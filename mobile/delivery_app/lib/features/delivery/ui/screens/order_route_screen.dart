import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:delivery_app/features/delivery/providers/tab_provider.dart';
import 'package:delivery_app/features/delivery/providers/pricing_provider.dart';
import 'package:delivery_app/features/delivery/services/gps_service.dart';
import 'package:delivery_app/features/delivery/services/geocoder_service.dart';
import 'order_summary_screen.dart';
import 'package:delivery_app/features/delivery/services/permission_service.dart';
import 'package:delivery_app/features/delivery/providers/gps_provider.dart';

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

  // ---- Данные сегмента ----
  DateTime? _segmentStartTime;
  DateTime? _segmentEndTime;
  Duration _totalPauseDuration = Duration.zero;
  DateTime? _pauseStartTime;
  bool _isPaused = false;

  // GPS
  late final GpsService _gpsService;
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
  bool _isPrivateHouse = false; // чекбокс "частный дом"

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

    _gpsService = ref.read(gpsServiceProvider);
    _initGps();
    _startSegment();
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
      await _gpsService.startLogging();
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
    print('🔵 _startSegment() called for segment $_currentSegment');
    _segmentStartTime = DateTime.now();
    _segmentEndTime = null;
    _totalPauseDuration = Duration.zero;
    _isPaused = false;
    _pauseStartTime = null;

    _gpsService.resetDistance();
    _distance = 0.0;
    _distanceController.text = '';

    if (_useGps && _currentSegment != 1 && _currentSegment != 3) {
      print('🟢 Starting GPS tracking for segment $_currentSegment');
      _gpsService.startTracking();
    } else {
      print('🟡 GPS not started: useGps=$_useGps, segment=$_currentSegment');
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
    print('🔵 _finishSegment() called for segment $_currentSegment');
    _segmentEndTime = DateTime.now();
    if (_isPaused) {
      if (_pauseStartTime != null) {
        _totalPauseDuration += DateTime.now().difference(_pauseStartTime!);
        _pauseStartTime = null;
      }
      _isPaused = false;
    }
    if (_useGps) {
      print('🛑 Stopping GPS tracking for segment $_currentSegment');
      _gpsService.stopTracking();
    }
  }

  void _saveCurrentSegmentData() {
    final time = _getSegmentTime();
    final distance = _getDistance();
    print('📊 Saving segment $_currentSegment: time=$time, distance=$distance');
    switch (_currentSegment) {
      case 0:
        _timeToShop = time;
        _distanceToShop = distance;
        break;
      case 1:
        _timeReceiving = time;
        break;
      case 2:
        _timeToClient = time;
        _distanceToClient = distance;
        break;
      case 3:
        _timeDelivery = time;
        break;
    }
  }

  // ---- Получение текущих координат (для геокодера) ----
  Future<Position?> _getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
    } catch (e) {
      _gpsService.addLog('❌ Ошибка получения позиции: $e');
      return null;
    }
  }

  // ===================== НОВЫЕ ВИДЖЕТЫ =====================

  // Карточка заказа
  Widget _buildOrderCard() {
    final deliveryLabel = _deliveryNumber > 1 ? 'Доставка #$_deliveryNumber' : 'Заказ';
    final pricing = ref.watch(pricingProvider);

    double cost = 0;
    // Стоимость рассчитывается только если известен вес и мы в сегментах 2 или 3
    if (_currentSegment >= 2 && _weight != null) {
      cost = (pricing.receivingFee + (_weight! * pricing.pricePerKg)) * _coefficient;
      if (_currentSegment == 3) {
        cost += (pricing.deliveryFee + (_getDistance() * pricing.pricePerKm)) * _coefficient;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6C63FF), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                deliveryLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              // Коэффициент
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'К: ${_coefficient.toString()}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_shopAddress != null)
            _buildInfoLine(Icons.storefront, 'Магазин', _shopAddress!),
          if (_clientAddress != null && _currentSegment >= 2)
            _buildInfoLine(Icons.location_on, 'Клиент', _clientAddress!),
          if (_weight != null)
            _buildInfoLine(Icons.fitness_center, 'Вес', '${_weight!.toStringAsFixed(1)} кг'),
          if (cost > 0)
            _buildInfoLine(Icons.attach_money, 'Стоимость', '${cost.toStringAsFixed(0)} руб.'),
        ],
      ),
    );
  }

  Widget _buildInfoLine(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6C63FF)),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF888888),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Блок управления GPS + пауза
  Widget _buildGpsControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2C2C2C), width: 1),
      ),
      child: Row(
        children: [
          _buildToggleButton('GPS', _useGps, () {
            setState(() {
              _useGps = true;
              if (_currentSegment != 1 && _currentSegment != 3) {
                _gpsService.startTracking();
              }
              _distance = 0.0;
              _distanceController.text = '';
            });
          }),
          const SizedBox(width: 6),
          _buildToggleButton('Вручную', !_useGps, () {
            setState(() {
              _useGps = false;
              _gpsService.stopTracking();
              _distance = 0.0;
              _distanceController.text = '';
            });
          }),
          const Spacer(),
          // Расстояние
          if (_useGps)
            Row(
              children: [
                const Icon(Icons.straighten, size: 16, color: Color(0xFF6C63FF)),
                const SizedBox(width: 4),
                Text(
                  '${_distance.toStringAsFixed(2)} км',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: 60,
              child: TextField(
                controller: _distanceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: '0.0',
                  hintStyle: TextStyle(color: Color(0xFF666666)),
                ),
                onChanged: (value) {
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed != null && parsed >= 0) {
                    setState(() {
                      _distance = parsed;
                    });
                  }
                },
              ),
            ),
          const SizedBox(width: 8),
          // Кнопка паузы
          GestureDetector(
            onTap: _togglePause,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isPaused ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _isPaused ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isPaused ? Icons.play_arrow : Icons.pause,
                    size: 14,
                    color: _isPaused ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    _isPaused ? 'Старт' : 'Пауза',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _isPaused ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== ОСНОВНОЙ BUILD =====

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
            const SizedBox(height: 12),
            _buildOrderCard(),
            const SizedBox(height: 10),
            _buildGpsControl(),
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

  // ===== ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ =====

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

  // ---- Сегмент 0: В магазин (только заголовок) ----
  Widget _buildShopSegment() {
    return const Text(
      'Пробег до магазина (бесплатный)',
      style: TextStyle(fontSize: 14, color: Colors.white),
    );
  }

  // ---- Сегмент 1: Получение (только вес) ----
  Widget _buildReceivingSegment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Введите вес бандероли',
          style: TextStyle(fontSize: 14, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isWeightValid ? const Color(0xFF6C63FF) : const Color(0xFF2C2C2C),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fitness_center, size: 18, color: Color(0xFF6C63FF)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Вес',
                            style: TextStyle(fontSize: 11, color: Color(0xFF888888)),
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
                              hintStyle: TextStyle(color: Color(0xFF666666)),
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
                          ),
                        ],
                      ),
                    ),
                    if (_isWeightValid)
                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---- Сегмент 2: К клиенту (заголовок) ----
  Widget _buildClientSegment() {
    return const Text(
      'Пробег до клиента (платный)',
      style: TextStyle(fontSize: 14, color: Colors.white),
    );
  }

  // ---- Сегмент 3: Выдача (квартира с чекбоксом) ----
  Widget _buildDeliverySegment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Введите номер квартиры',
          style: TextStyle(fontSize: 14, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isApartmentValid || _isPrivateHouse
                        ? const Color(0xFF6C63FF)
                        : const Color(0xFF2C2C2C),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.home, size: 18, color: Color(0xFF6C63FF)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Квартира',
                            style: TextStyle(fontSize: 11, color: Color(0xFF888888)),
                          ),
                          TextField(
                            controller: _apartmentController,
                            enabled: !_isPrivateHouse,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              hintText: _isPrivateHouse ? 'Частный дом' : 'Введите номер',
                              hintStyle: TextStyle(
                                color: _isPrivateHouse ? Color(0xFF888888) : Color(0xFF666666),
                                fontSize: 14,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _isApartmentValid = value.trim().isNotEmpty;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: _isPrivateHouse,
                          onChanged: (val) {
                            setState(() {
                              _isPrivateHouse = val ?? false;
                              if (_isPrivateHouse) {
                                _apartmentController.text = '1';
                                _isApartmentValid = true;
                              } else {
                                _apartmentController.clear();
                                _isApartmentValid = false;
                              }
                            });
                          },
                          activeColor: const Color(0xFF6C63FF),
                          side: BorderSide(
                            color: _isPrivateHouse ? const Color(0xFF6C63FF) : const Color(0xFF666666),
                          ),
                        ),
                        const Text(
                          'Частный дом',
                          style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
            style: TextStyle(fontSize: 12, color: Colors.orange),
          ),
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
          ),
        ),
      ],
    );
  }

  // ---- Кнопка переключения (используется и в GPS, и для вкладок) ----
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

  // ---- Кнопка действия ----
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
        isMainEnabled = _isPrivateHouse || _isApartmentValid; // изменено
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
          backgroundColor: isMainEnabled ? const Color(0xFF6C63FF) : const Color(0xFF2C2C2C),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // ---- Обработчики действий ----
  void _handleMainAction() async {
    _finishSegment();
    _saveCurrentSegmentData();

    switch (_currentSegment) {
      case 0:
        _gpsService.addLog('🔍 Получение адреса магазина...');
        final currentPos = await _getCurrentPosition();
        if (currentPos != null) {
          final address = await GeocoderService.reverseGeocode(
            currentPos.latitude,
            currentPos.longitude,
            onLog: _gpsService.addLog,
          );
          setState(() {
            _shopAddress = address ?? 'Адрес не определён';
          });
        } else {
          setState(() {
            _shopAddress = 'Адрес не определён (нет GPS)';
          });
        }
        setState(() {
          _currentSegment = 1;
        });
        _startSegment();
        break;

      case 1:
        final weight = double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0.0;
        if (weight <= 0) return;
        _weight = weight;
        _clientAddress = 'Адрес клиента будет определён позже';
        setState(() {
          _currentSegment = 2;
        });
        _startSegment();
        break;

      case 2:
        _gpsService.addLog('🔍 Получение адреса клиента...');
        final currentPos = await _getCurrentPosition();
        if (currentPos != null) {
          final address = await GeocoderService.reverseGeocode(
            currentPos.latitude,
            currentPos.longitude,
            onLog: _gpsService.addLog,
          );
          setState(() {
            _clientAddress = address ?? 'Адрес не определён';
          });
        } else {
          setState(() {
            _clientAddress = 'Адрес не определён (нет GPS)';
          });
        }
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
    String apartment = _apartmentController.text.trim();
    if (!_isPrivateHouse && apartment.isEmpty) return;
    if (_isPrivateHouse) apartment = 'частный дом (1)';

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
      _isPrivateHouse = false;
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
        title: const Text('Отменить заказ?', style: TextStyle(color: Colors.white)),
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