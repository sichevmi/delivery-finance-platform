import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/delivery/providers/tab_provider.dart';
import 'package:delivery_app/features/delivery/providers/pricing_provider.dart';
import 'package:delivery_app/features/delivery/services/gps_service.dart';
import 'order_summary_screen.dart';
import 'package:delivery_app/features/delivery/services/permission_service.dart';

class Delivery {
  final int number;
  final String clientAddress;
  final double weight;
  final String apartment;
  final int timeToShop;
  final double distanceToShop;
  final int timeReceiving;
  final int timeToClient;
  final double distanceToClient;
  final int timeDelivery;
  final String? returnReason;

  Delivery({
    required this.number,
    required this.clientAddress,
    required this.weight,
    required this.apartment,
    required this.timeToShop,
    required this.distanceToShop,
    required this.timeReceiving,
    required this.timeToClient,
    required this.distanceToClient,
    required this.timeDelivery,
    this.returnReason,
  });
}

class OrderRouteScreen extends ConsumerStatefulWidget {
  final String serviceName;
  final double coefficient;
  final int segmentIndex;

  const OrderRouteScreen({
    super.key,
    required this.serviceName,
    required this.coefficient,
    required this.segmentIndex,
  });

  @override
  ConsumerState<OrderRouteScreen> createState() => _OrderRouteScreenState();
}

class _OrderRouteScreenState extends ConsumerState<OrderRouteScreen> with WidgetsBindingObserver {
  final List<String> _segments = ['В магазин', 'Получение', 'К клиенту', 'Выдача'];
  late int _currentSegment;

  // ---- Данные сегмента (время, пробег, паузы) ----

  DateTime? _segmentStartTime;
  DateTime? _segmentEndTime;
  Duration _totalPauseDuration = Duration.zero;
  DateTime? _pauseStartTime;
  bool _isPaused = false;

  // GPS
  final GpsService _gpsService = GpsService();
  bool _useGps = true;
  double _distance = 0.0;
  final TextEditingController _distanceController = TextEditingController(text: '');
  StreamSubscription<double>? _gpsSubscription;
  bool _isGpsInitialized = false;

  // ---- Сохранённые данные по сегментам ----
  int _timeToShop = 0;
  double _distanceToShop = 0.0;
  int _timeReceiving = 0;
  int _timeToClient = 0;
  double _distanceToClient = 0.0;
  int _timeDelivery = 0;

  // Общие данные
  late double _coefficient;
  double? _weight;
  double? _baseCost;

  final TextEditingController _weightController = TextEditingController(text: '');
  bool _isWeightValid = false;

  final TextEditingController _apartmentController = TextEditingController();
  bool _isApartmentValid = false;

  int _deliveryNumber = 1;
  final List<Delivery> _completedDeliveries = [];

  String? _clientAddress;
  String? _shopAddress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentSegment = widget.segmentIndex;
    _coefficient = widget.coefficient;
    _baseCost = 250.0;

    _initGps();
    _checkPermissionsAndInit();
    _startSegment();
  }

  Future<void> _checkPermissionsAndInit() async {
  final hasPermission = await PermissionService.requestLocationPermission(context);
  if (hasPermission) {
    _gpsSubscription = _gpsService.distanceStream.listen((distance) {
      if (mounted) {
        setState(() {
          _distance = distance;
        });
      }
    });
    _isGpsInitialized = true;
  } else {
    setState(() {
      _useGps = false;
    });
  }
}

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gpsSubscription?.cancel();
    _gpsService.stopTracking();
    _distanceController.dispose();
    _weightController.dispose();
    _apartmentController.dispose();
    super.dispose();
  }

  Future<void> _initGps() async {
  final hasPermission = await PermissionService.requestLocationPermission(context);
  if (hasPermission) {
    _gpsSubscription = _gpsService.distanceStream.listen((distance) {
      if (mounted) {
        setState(() {
          _distance = distance;
        });
      }
    });
    _isGpsInitialized = true;
  } else {
    setState(() {
      _useGps = false;
    });
  }
}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      print('🔵 App went to background');
    } else if (state == AppLifecycleState.resumed) {
      print('🔵 App resumed from background');
      setState(() {});
      if (_useGps && !_isPaused) {
        print('🔄 Force refreshing GPS on resume');
        _gpsService.forceRefresh();
      }
    }
  }

  void _startSegment() {
    _segmentStartTime = DateTime.now();
    _segmentEndTime = null;
    _totalPauseDuration = Duration.zero;
    _isPaused = false;
    _pauseStartTime = null;

    _gpsService.resetDistance();
    _distance = 0.0;
    _distanceController.text = '';

    if (_useGps && _currentSegment != 1 && _currentSegment != 3) {
      _gpsService.startTracking();
    }

    setState(() {});
  }

  void _togglePause() {
    setState(() {
      if (_isPaused) {
        if (_pauseStartTime != null) {
          _totalPauseDuration += DateTime.now().difference(_pauseStartTime!);
          _pauseStartTime = null;
        }
        _isPaused = false;
        if (_useGps && _currentSegment != 1 && _currentSegment != 3) {
          _gpsService.resumeTracking();
        }
      } else {
        _pauseStartTime = DateTime.now();
        _isPaused = true;
        if (_useGps && _currentSegment != 1 && _currentSegment != 3) {
          _gpsService.pauseTracking();
        }
      }
    });
  }

  int _getSegmentTime() {
    if (_segmentStartTime == null) return 0;
    final endTime = _segmentEndTime ?? DateTime.now();
    final rawDuration = endTime.difference(_segmentStartTime!);
    final result = rawDuration - _totalPauseDuration;
    return result.inSeconds.clamp(0, 86400).toInt();
  }

  double _getDistance() {
    if (_useGps) {
      return _distance;
    } else {
      return double.tryParse(_distanceController.text.replaceAll(',', '.')) ?? 0.0;
    }
  }

  void _finishSegment() {
    _segmentEndTime = DateTime.now();
    if (_isPaused) {
      if (_pauseStartTime != null) {
        _totalPauseDuration += DateTime.now().difference(_pauseStartTime!);
        _pauseStartTime = null;
      }
      _isPaused = false;
    }
    if (_useGps) {
      _gpsService.stopTracking();
    }
  }

  // ---- Сохранение данных текущего сегмента ----
  void _saveCurrentSegmentData() {
    final time = _getSegmentTime();
    final distance = _getDistance();
    print('📊 Saving segment $_currentSegment: time=$time, distance=$distance');
    switch (_currentSegment) {
      case 0: // В магазин
        _timeToShop = time;
        _distanceToShop = distance;
        break;
      case 1: // Получение
        _timeReceiving = time;
        break;
      case 2: // К клиенту
        _timeToClient = time;
        _distanceToClient = distance;
        break;
      case 3: // Выдача
        _timeDelivery = time;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.serviceName),
            if (_deliveryNumber > 1) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Доставка #$_deliveryNumber',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          TextButton(
            onPressed: _cancelOrder,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text(
              'Отменить',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSegmentProgress(),
            const SizedBox(height: 20),
            _buildCoefficientDisplay(),
            const SizedBox(height: 12),
            _buildSegmentContent(),
            const SizedBox(height: 20),
            _buildActionButtons(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentProgress() {
    return Row(
      children: List.generate(_segments.length, (index) {
        final isActive = index == _currentSegment;
        final isCompleted = index < _currentSegment;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: isCompleted || isActive
                            ? const Color(0xFF6C63FF)
                            : const Color(0xFF2C2C2C),
                      ),
                    ),
                  ),
                  if (index < _segments.length - 1) const SizedBox(width: 2),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF6C63FF)
                          : isCompleted
                              ? const Color(0xFF6C63FF).withOpacity(0.3)
                              : const Color(0xFF2C2C2C),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive || isCompleted
                              ? Colors.white
                              : const Color(0xFF888888),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _segments[index],
                    style: TextStyle(
                      fontSize: 10,
                      color: isActive || isCompleted
                          ? Colors.white
                          : const Color(0xFF888888),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCoefficientDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF2C2C2C),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Коэффициент нагрузки',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF888888),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _coefficient.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C63FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentContent() {
    switch (_currentSegment) {
      case 0:
        return _buildShopSegment();
      case 1:
        return _buildReceivingSegment();
      case 2:
        return _buildClientSegment();
      case 3:
        return _buildDeliverySegment();
      default:
        return const SizedBox.shrink();
    }
  }

  // ---- Сегмент 1: В магазин ----

  Widget _buildShopSegment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Бесплатный пробег',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildToggleButton('Вручную', !_useGps, () {
              setState(() {
                _useGps = false;
                _gpsService.stopTracking();
                _distance = 0.0;
                _distanceController.text = '';
              });
            }),
            const SizedBox(width: 8),
            _buildToggleButton('GPS', _useGps, () {
              setState(() {
                _useGps = true;
                _gpsService.startTracking();
                _distance = 0.0;
                _distanceController.text = '';
              });
            }),
            const Spacer(),
            _buildPauseButton(),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Пробег',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (_useGps)
                    Row(
                      children: [
                        const Icon(
                          Icons.gps_fixed,
                          size: 18,
                          color: Color(0xFF6C63FF),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_distance.toStringAsFixed(2)} км',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _distanceController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              hintText: '0.0',
                              hintStyle: TextStyle(
                                color: Color(0xFF666666),
                              ),
                            ),
                            onChanged: (value) {
                              final parsed = double.tryParse(value.replaceAll(',', '.'));
                              if (parsed != null && parsed >= 0) {
                                setState(() {
                                  _distance = parsed;
                                });
                              }
                            },
                            onTap: () {
                              _distanceController.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: _distanceController.text.length,
                              );
                            },
                          ),
                        ),
                        const Text(
                          ' км',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---- Сегмент 2: Получение ----

  Widget _buildReceivingSegment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_shopAddress != null)
          _buildInfoRow(
            icon: Icons.location_on,
            label: 'Магазин',
            value: _shopAddress!,
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isWeightValid
                        ? const Color(0xFF6C63FF)
                        : const Color(0xFF2C2C2C),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.fitness_center,
                      size: 18,
                      color: Color(0xFF6C63FF),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Вес',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF888888),
                            ),
                          ),
                          TextField(
                            controller: _weightController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              hintText: '0.0',
                              hintStyle: TextStyle(
                                color: Color(0xFF666666),
                              ),
                            ),
                            onChanged: (value) {
                              final parsed = double.tryParse(value.replaceAll(',', '.'));
                              setState(() {
                                _isWeightValid = parsed != null && parsed > 0;
                                if (_isWeightValid) {
                                  _weight = parsed;
                                } else {
                                  _weight = null;
                                }
                              });
                            },
                            onTap: () {
                              _weightController.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: _weightController.text.length,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    if (_isWeightValid)
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildPauseButton(),
          ],
        ),
      ],
    );
  }

  // ---- Сегмент 3: К клиенту ----

  Widget _buildClientSegment() {
    final deliveryLabel = _deliveryNumber > 1 ? ' (Доставка #$_deliveryNumber)' : '';

    final pricing = ref.watch(pricingProvider);
    double currentCost = pricing.receivingFee * _coefficient;
    if (_weight != null && _weight! > 0) {
      currentCost += _weight! * pricing.pricePerKg * _coefficient;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_shopAddress != null)
          _buildInfoRow(
            icon: Icons.storefront,
            label: 'Магазин',
            value: _shopAddress!,
          ),
        const SizedBox(height: 12),
        _buildInfoRow(
          icon: Icons.fitness_center,
          label: 'Вес',
          value: '${_weight?.toStringAsFixed(1) ?? '0.0'} кг',
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          icon: Icons.attach_money,
          label: 'Стоимость (получение + вес)',
          value: '${currentCost.toStringAsFixed(0)} руб.',
          valueColor: const Color(0xFF6C63FF),
        ),
        const SizedBox(height: 16),
        const Divider(color: Color(0xFF2C2C2C)),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'Платный пробег$deliveryLabel',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            _buildPauseButton(),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildToggleButton('Вручную', !_useGps, () {
              setState(() {
                _useGps = false;
                _gpsService.stopTracking();
                _distance = 0.0;
                _distanceController.text = '';
              });
            }),
            const SizedBox(width: 8),
            _buildToggleButton('GPS', _useGps, () {
              setState(() {
                _useGps = true;
                _gpsService.startTracking();
                _distance = 0.0;
                _distanceController.text = '';
              });
            }),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Пробег',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (_useGps)
                    Row(
                      children: [
                        const Icon(
                          Icons.gps_fixed,
                          size: 18,
                          color: Color(0xFF6C63FF),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_distance.toStringAsFixed(2)} км',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _distanceController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              hintText: '0.0',
                              hintStyle: TextStyle(
                                color: Color(0xFF666666),
                              ),
                            ),
                            onChanged: (value) {
                              final parsed = double.tryParse(value.replaceAll(',', '.'));
                              if (parsed != null && parsed >= 0) {
                                setState(() {
                                  _distance = parsed;
                                });
                              }
                            },
                            onTap: () {
                              _distanceController.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: _distanceController.text.length,
                              );
                            },
                          ),
                        ),
                        const Text(
                          ' км',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---- Сегмент 4: Выдача ----

  Widget _buildDeliverySegment() {
    final deliveryLabel = _deliveryNumber > 1 ? ' (Доставка #$_deliveryNumber)' : '';

    final pricing = ref.watch(pricingProvider);
    double currentCost = (pricing.deliveryFee + (_getDistance() * pricing.pricePerKm)) * _coefficient;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_shopAddress != null)
          _buildInfoRow(
            icon: Icons.storefront,
            label: 'Магазин',
            value: _shopAddress!,
          ),
        const SizedBox(height: 8),
        if (_clientAddress != null)
          _buildInfoRow(
            icon: Icons.location_on,
            label: 'Адрес клиента$deliveryLabel',
            value: _clientAddress!,
          ),
        const SizedBox(height: 12),
        _buildInfoRow(
          icon: Icons.fitness_center,
          label: 'Вес',
          value: '${_weight?.toStringAsFixed(1) ?? '0.0'} кг',
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          icon: Icons.attach_money,
          label: 'Стоимость (выдача + пробег)',
          value: '${currentCost.toStringAsFixed(0)} руб.',
          valueColor: const Color(0xFF6C63FF),
        ),
        const SizedBox(height: 16),
        const Divider(color: Color(0xFF2C2C2C)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isApartmentValid
                        ? const Color(0xFF6C63FF)
                        : const Color(0xFF2C2C2C),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.home,
                      size: 18,
                      color: Color(0xFF6C63FF),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Квартира',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF888888),
                            ),
                          ),
                          TextField(
                            controller: _apartmentController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              hintText: 'Введите номер квартиры',
                              hintStyle: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 14,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _isApartmentValid = value.trim().isNotEmpty;
                              });
                            },
                            onTap: () {
                              _apartmentController.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: _apartmentController.text.length,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    if (_isApartmentValid)
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildPauseButton(),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Функция возврата товара в разработке'),
                backgroundColor: Colors.orange,
              ),
            );
          },
          icon: const Icon(Icons.assignment_return, size: 16, color: Colors.orange),
          label: const Text(
            'Возврат товара в магазин',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange,
            ),
          ),
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
          ),
        ),
      ],
    );
  }

  // ---- Вспомогательные виджеты ----

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF2C2C2C),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF6C63FF),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF888888),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF2C2C2C),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : const Color(0xFF888888),
          ),
        ),
      ),
    );
  }

  Widget _buildPauseButton() {
    return GestureDetector(
      onTap: _togglePause,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _isPaused
              ? Colors.green.withOpacity(0.15)
              : Colors.orange.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isPaused
                ? Colors.green.withOpacity(0.3)
                : Colors.orange.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPaused ? Icons.play_arrow : Icons.pause,
              size: 16,
              color: _isPaused ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 4),
            Text(
              _isPaused ? 'Старт' : 'Пауза',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _isPaused ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    String mainButtonText = 'Далее';
    bool isMainEnabled = true;

    final deliveryLabel = _deliveryNumber > 1 ? ' #$_deliveryNumber' : '';

    switch (_currentSegment) {
      case 0:
        mainButtonText = 'Получить бандероль';
        isMainEnabled = true;
        break;
      case 1:
        mainButtonText = 'Выехал к получателю$deliveryLabel';
        isMainEnabled = _isWeightValid;
        break;
      case 2:
        mainButtonText = 'Выдать бандероль$deliveryLabel';
        isMainEnabled = true;
        break;
      case 3:
        mainButtonText = 'Завершить доставку$deliveryLabel';
        isMainEnabled = _isApartmentValid;
        break;
      default:
        mainButtonText = 'Далее';
        isMainEnabled = true;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isMainEnabled ? _handleMainAction : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isMainEnabled
              ? const Color(0xFF6C63FF)
              : const Color(0xFF2C2C2C),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          mainButtonText,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isMainEnabled ? Colors.white : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }

  void _handleMainAction() {
    // Сначала завершаем текущий сегмент (устанавливаем _segmentEndTime)
    _finishSegment();
    
    // Потом сохраняем данные (используя _getSegmentTime(), который теперь знает время окончания)
    _saveCurrentSegmentData();

    switch (_currentSegment) {
      case 0:
        _shopAddress = 'ул. Ленина, 25, г. Москва';
        setState(() {
          _currentSegment = 1;
        });
        _startSegment();
        break;
      case 1:
        final weight = double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0.0;
        if (weight <= 0) return;
        _weight = weight;
        _clientAddress = 'ул. Пушкина, 10, г. Москва';
        setState(() {
          _currentSegment = 2;
        });
        _startSegment();
        break;
      case 2:
        setState(() {
          _currentSegment = 3;
        });
        _startSegment();
        break;
      case 3:
        _completeDelivery();
        break;
    }
  }

  void _completeDelivery() async {
    final apartment = _apartmentController.text.trim();
    if (apartment.isEmpty) return;

    // Завершаем последний сегмент и сохраняем данные
    _finishSegment();
    _saveCurrentSegmentData();

    final delivery = Delivery(
      number: _deliveryNumber,
      clientAddress: _clientAddress ?? 'Неизвестный адрес',
      weight: _weight ?? 0.0,
      apartment: apartment,
      timeToShop: _timeToShop,
      distanceToShop: _distanceToShop,
      timeReceiving: _timeReceiving,
      timeToClient: _timeToClient,
      distanceToClient: _distanceToClient,
      timeDelivery: _timeDelivery,
    );

    _completedDeliveries.add(delivery);

    final pricing = ref.watch(pricingProvider);

    final totalTime = _calculateTotalTime();
    final totalDistance = _calculateTotalDistance();
    final totalCost = _calculateTotalCost(pricing);

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => OrderSummaryScreen(
          serviceName: widget.serviceName,
          coefficient: _coefficient,
          deliveries: _completedDeliveries,
          totalCost: totalCost,
          totalTime: totalTime,
          totalDistance: totalDistance,
        ),
      ),
    );

    if (result == true) {
      _startNextDelivery();
    } else {
      _finishOrder();
    }
  }

  void _startNextDelivery() {
    setState(() {
      _deliveryNumber++;
      _currentSegment = 2;
      _clientAddress = 'ул. Новая, ${_deliveryNumber * 5}, г. Москва';
      _apartmentController.clear();
      _isApartmentValid = false;
    });
    _startSegment();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Начало доставки #$_deliveryNumber'),
        backgroundColor: const Color(0xFF6C63FF),
      ),
    );
  }

  int _calculateTotalTime() {
    if (_completedDeliveries.isEmpty) return 0;

    final first = _completedDeliveries.first;
    int total = first.timeToShop + first.timeReceiving;

    for (final d in _completedDeliveries) {
      total += d.timeToClient + d.timeDelivery;
    }

    return total;
  }

  double _calculateTotalDistance() {
    if (_completedDeliveries.isEmpty) return 0.0;

    double total = _completedDeliveries.first.distanceToShop;

    for (final d in _completedDeliveries) {
      total += d.distanceToClient;
    }

    return total;
  }

  double _calculateTotalCost(PricingConfig pricing) {
    if (_completedDeliveries.isEmpty) return 0.0;

    final first = _completedDeliveries.first;
    double total = (pricing.receivingFee + (first.weight * pricing.pricePerKg)) * _coefficient;

    for (final d in _completedDeliveries) {
      total += (pricing.deliveryFee + (d.distanceToClient * pricing.pricePerKm)) * _coefficient;
    }

    return total;
  }

  void _finishOrder() {
    Navigator.of(context, rootNavigator: false).popUntil((route) => route.isFirst);
    ref.read(selectedTabProvider.notifier).state = 0;
  }

  void _cancelOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Отменить заказ?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Вы уверены, что хотите отменить заказ? Все данные будут потеряны.',
          style: TextStyle(color: Color(0xFF888888)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Нет', style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(selectedTabProvider.notifier).state = 1;
              Navigator.of(context, rootNavigator: false).popUntil((route) => route.isFirst);
            },
            child: const Text('Да, отменить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}