import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/core/services/api_service.dart';
import 'package:delivery_app/features/delivery/models/delivery.dart';
import 'package:delivery_app/features/delivery/services/geocoder_service.dart';
import 'package:delivery_app/features/delivery/ui/widgets/segment_progress.dart';
import 'package:delivery_app/features/delivery/ui/widgets/order_card.dart';
import 'package:delivery_app/features/delivery/ui/widgets/gps_control.dart';
import 'package:delivery_app/features/delivery/ui/widgets/segment_content.dart';
import 'package:delivery_app/features/delivery/ui/widgets/action_buttons.dart';
import 'order_summary_screen.dart';
import 'package:delivery_app/features/delivery/providers/pricing_provider.dart';
import 'package:delivery_app/features/delivery/providers/settings_provider.dart';
import 'package:delivery_app/features/delivery/providers/shift_provider.dart';
import 'package:delivery_app/features/delivery/providers/daily_stats_provider.dart';
import 'package:delivery_app/features/delivery/providers/gps_provider.dart';
import 'package:delivery_app/features/delivery/services/gps_service.dart';
import 'package:delivery_app/features/delivery/models/pricing_config.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// ===== ЛОКАЛЬНОЕ СОСТОЯНИЕ =====
class _OrderRouteState {
  final int currentSegment;
  final int deliveryNumber;
  final double coefficient;
  final double distance;
  final double gpsDistance;
  final double? weight;
  final String? shopAddress;
  final String? clientAddress;
  final String? apartment;
  final bool isPrivateHouse;
  final bool useGps;
  final bool isPaused;
  final bool isWeightValid;
  final bool isApartmentValid;
  final List<Delivery> completedDeliveries;
  final double totalAllDistance;
  final double totalCost;
  final double totalExpenses;
  final int totalTime;
  final bool showSummary;
  final bool shouldNavigateToHome;
  final int timeToShop;
  final double distanceToShop;
  final int timeReceiving;
  final int timeToClient;
  final double distanceToClient;
  final int timeDelivery;
  final DateTime? segmentStartTime;
  final DateTime? segmentEndTime;
  final Duration totalPauseDuration;
  final DateTime? pauseStartTime;

  _OrderRouteState({
    this.currentSegment = 0,
    this.deliveryNumber = 1,
    this.coefficient = 1.0,
    this.distance = 0.0,
    this.gpsDistance = 0.0,
    this.weight,
    this.shopAddress,
    this.clientAddress,
    this.apartment,
    this.isPrivateHouse = false,
    this.useGps = true,
    this.isPaused = false,
    this.isWeightValid = false,
    this.isApartmentValid = false,
    this.completedDeliveries = const [],
    this.totalAllDistance = 0.0,
    this.totalCost = 0.0,
    this.totalExpenses = 0.0,
    this.totalTime = 0,
    this.showSummary = false,
    this.shouldNavigateToHome = false,
    this.timeToShop = 0,
    this.distanceToShop = 0.0,
    this.timeReceiving = 0,
    this.timeToClient = 0,
    this.distanceToClient = 0.0,
    this.timeDelivery = 0,
    this.segmentStartTime,
    this.segmentEndTime,
    this.totalPauseDuration = Duration.zero,
    this.pauseStartTime,
  });

  _OrderRouteState copyWith({
    int? currentSegment,
    int? deliveryNumber,
    double? coefficient,
    double? distance,
    double? gpsDistance,
    double? weight,
    String? shopAddress,
    String? clientAddress,
    String? apartment,
    bool? isPrivateHouse,
    bool? useGps,
    bool? isPaused,
    bool? isWeightValid,
    bool? isApartmentValid,
    List<Delivery>? completedDeliveries,
    double? totalAllDistance,
    double? totalCost,
    double? totalExpenses,
    int? totalTime,
    bool? showSummary,
    bool? shouldNavigateToHome,
    int? timeToShop,
    double? distanceToShop,
    int? timeReceiving,
    int? timeToClient,
    double? distanceToClient,
    int? timeDelivery,
    DateTime? segmentStartTime,
    DateTime? segmentEndTime,
    Duration? totalPauseDuration,
    DateTime? pauseStartTime,
  }) {
    return _OrderRouteState(
      currentSegment: currentSegment ?? this.currentSegment,
      deliveryNumber: deliveryNumber ?? this.deliveryNumber,
      coefficient: coefficient ?? this.coefficient,
      distance: distance ?? this.distance,
      gpsDistance: gpsDistance ?? this.gpsDistance,
      weight: weight ?? this.weight,
      shopAddress: shopAddress ?? this.shopAddress,
      clientAddress: clientAddress ?? this.clientAddress,
      apartment: apartment ?? this.apartment,
      isPrivateHouse: isPrivateHouse ?? this.isPrivateHouse,
      useGps: useGps ?? this.useGps,
      isPaused: isPaused ?? this.isPaused,
      isWeightValid: isWeightValid ?? this.isWeightValid,
      isApartmentValid: isApartmentValid ?? this.isApartmentValid,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      totalAllDistance: totalAllDistance ?? this.totalAllDistance,
      totalCost: totalCost ?? this.totalCost,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalTime: totalTime ?? this.totalTime,
      showSummary: showSummary ?? this.showSummary,
      shouldNavigateToHome: shouldNavigateToHome ?? this.shouldNavigateToHome,
      timeToShop: timeToShop ?? this.timeToShop,
      distanceToShop: distanceToShop ?? this.distanceToShop,
      timeReceiving: timeReceiving ?? this.timeReceiving,
      timeToClient: timeToClient ?? this.timeToClient,
      distanceToClient: distanceToClient ?? this.distanceToClient,
      timeDelivery: timeDelivery ?? this.timeDelivery,
      segmentStartTime: segmentStartTime ?? this.segmentStartTime,
      segmentEndTime: segmentEndTime ?? this.segmentEndTime,
      totalPauseDuration: totalPauseDuration ?? this.totalPauseDuration,
      pauseStartTime: pauseStartTime ?? this.pauseStartTime,
    );
  }
}

// ===== ОСНОВНОЙ ЭКРАН =====
class OrderRouteScreen extends ConsumerStatefulWidget {
  final String serviceName;
  final double coefficient;
  final int segmentIndex;

  const OrderRouteScreen({
    super.key,
    required this.serviceName,
    required this.coefficient,
    this.segmentIndex = 0,
  });

  @override
  ConsumerState<OrderRouteScreen> createState() => _OrderRouteScreenState();
}

class _OrderRouteScreenState extends ConsumerState<OrderRouteScreen> {
  _OrderRouteState _state = _OrderRouteState();
  bool _isSummaryShown = false;
  bool _isProcessing = false;
  late GpsService _gpsService;
  StreamSubscription<double>? _gpsSubscription;

  @override
  void initState() {
    super.initState();
    logMessage('🟢 OrderRouteScreen.initState()');
    
    _gpsService = ref.read(gpsServiceProvider);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initOrderRoute();
      ref.read(shiftProvider.notifier).startOrder();
      
      _gpsSubscription = _gpsService.distanceStream.listen((distance) {
        if (mounted) {
          setState(() {
            _state = _state.copyWith(gpsDistance: distance);
            if (_state.useGps) {
              _state = _state.copyWith(distance: distance);
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    super.dispose();
  }

  void _initOrderRoute() {
    logMessage('🟢 OrderRouteScreen._initOrderRoute()');
    setState(() {
      _state = _OrderRouteState(
        coefficient: widget.coefficient,
        currentSegment: widget.segmentIndex,
        deliveryNumber: 1,
        useGps: true,
        distance: 0.0,
        gpsDistance: 0.0,
      );
    });
    _gpsService.resetDistance();
    _startSegment();
  }

  void _startSegment() {
    logMessage('🟢 _startSegment() сегмент ${_state.currentSegment}');
    setState(() {
      _state = _state.copyWith(
        segmentStartTime: DateTime.now(),
        segmentEndTime: null,
        totalPauseDuration: Duration.zero,
        isPaused: false,
        pauseStartTime: null,
        distance: 0.0,
        gpsDistance: 0.0,
        useGps: true,
      );
    });
    _gpsService.resetDistance();
  }

  int _getSegmentTime() {
    if (_state.segmentStartTime == null) return 0;
    final endTime = _state.segmentEndTime ?? DateTime.now();
    final rawDuration = endTime.difference(_state.segmentStartTime!);
    final result = rawDuration - _state.totalPauseDuration;
    return result.inSeconds.clamp(0, 86400).toInt();
  }

  double _getDistance() {
    if (_state.useGps) {
      return _state.gpsDistance;
    }
    return _state.distance;
  }

  void _saveCurrentSegmentData() {
    final time = _getSegmentTime();
    final distance = _getDistance();
    logMessage('📊 Сохраняем сегмент ${_state.currentSegment}: time=$time сек, distance=$distance км');
    setState(() {
      switch (_state.currentSegment) {
        case 0:
          _state = _state.copyWith(timeToShop: time, distanceToShop: distance);
          break;
        case 1:
          _state = _state.copyWith(timeReceiving: time);
          break;
        case 2:
          _state = _state.copyWith(timeToClient: time, distanceToClient: distance);
          break;
        case 3:
          _state = _state.copyWith(timeDelivery: time);
          break;
      }
    });
  }

  Future<void> _handleMainAction() async {
    logMessage('🔵 [_handleMainAction] ВХОД, _isProcessing=$_isProcessing, сегмент=${_state.currentSegment}');
    
    if (_isProcessing) {
      logMessage('⚠️ [_handleMainAction] ПРОПУСК: уже в обработке');
      return;
    }
    _isProcessing = true;

    logMessage('🟢 _handleMainAction() сегмент ${_state.currentSegment}');
    
    final end = DateTime.now();
    if (_state.isPaused && _state.pauseStartTime != null) {
      final added = end.difference(_state.pauseStartTime!);
      setState(() {
        _state = _state.copyWith(
          totalPauseDuration: _state.totalPauseDuration + added,
          pauseStartTime: null,
          isPaused: false,
        );
      });
    }
    setState(() {
      _state = _state.copyWith(segmentEndTime: end);
    });
    _saveCurrentSegmentData();

    switch (_state.currentSegment) {
      case 0:
        logMessage('🔵 [_handleMainAction] КЕЙС 0: получение позиции');
        final pos = await _getCurrentPosition();
        if (!mounted) { 
          logMessage('⚠️ [_handleMainAction] КЕЙС 0: виджет не смонтирован');
          _isProcessing = false; 
          return; 
        }
        String? addr;
        if (pos != null) {
          addr = await GeocoderService.reverseGeocode(
            pos.latitude, 
            pos.longitude,
            onLog: (msg) => logMessage(msg, category: 'GEO'),
          );
        }
        setState(() {
          _state = _state.copyWith(
            shopAddress: addr ?? 'Адрес не определён',
            currentSegment: 1,
          );
        });
        _startSegment();
        _isProcessing = false;
        logMessage('🔵 [_handleMainAction] КЕЙС 0: завершён, переход на сегмент 1');
        break;

      case 1:
        logMessage('🔵 [_handleMainAction] КЕЙС 1: проверка веса');
        if (_state.weight == null || _state.weight! <= 0) {
          logMessage('⚠️ Вес не введён', category: 'ORDER');
          _isProcessing = false;
          return;
        }
        setState(() {
          _state = _state.copyWith(
            clientAddress: 'Адрес клиента будет определён позже',
            currentSegment: 2,
          );
        });
        _startSegment();
        _isProcessing = false;
        logMessage('🔵 [_handleMainAction] КЕЙС 1: завершён, переход на сегмент 2');
        break;

      case 2:
        logMessage('🔵 [_handleMainAction] КЕЙС 2: получение позиции для адреса клиента');
        final pos = await _getCurrentPosition();
        if (!mounted) { 
          logMessage('⚠️ [_handleMainAction] КЕЙС 2: виджет не смонтирован');
          _isProcessing = false; 
          return; 
        }
        String? addr;
        if (pos != null) {
          addr = await GeocoderService.reverseGeocode(
            pos.latitude, 
            pos.longitude,
            onLog: (msg) => logMessage(msg, category: 'GEO'),
          );
        }
        setState(() {
          _state = _state.copyWith(
            clientAddress: addr ?? 'Адрес не определён',
            currentSegment: 3,
          );
        });
        _startSegment();
        _isProcessing = false;
        logMessage('🔵 [_handleMainAction] КЕЙС 2: завершён, переход на сегмент 3');
        break;

      case 3:
        logMessage('🔵 [_handleMainAction] КЕЙС 3: завершение доставки');
        await _completeDelivery();
        _isProcessing = false;
        if (mounted) {
          logMessage('🔵 [_handleMainAction] КЕЙС 3: установка showSummary=true');
          setState(() {
            _state = _state.copyWith(showSummary: true);
          });
        }
        logMessage('🔵 [_handleMainAction] КЕЙС 3: завершён');
        break;
    }
    logMessage('🔵 [_handleMainAction] ВЫХОД, _isProcessing=$_isProcessing');
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      if (kIsWeb) {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            logMessage('⏰ Таймаут получения позиции на вебе', category: 'GPS');
            throw Exception('Превышено время ожидания позиции');
          },
        );
      }
      
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        return lastPosition;
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          logMessage('⏰ Таймаут получения позиции', category: 'GPS');
          throw Exception('Превышено время ожидания позиции');
        },
      );
    } catch (e) {
      logMessage('❌ Ошибка получения позиции: $e', category: 'GPS');
      return null;
    }
  }

  Future<void> _completeDelivery() async {
    logMessage('🔵 [_completeDelivery] ВХОД, deliveryNumber=${_state.deliveryNumber}');
    logMessage('🔵 [_completeDelivery] completedDeliveries до: ${_state.completedDeliveries.length}');
    
    if (_state.completedDeliveries.any((d) => d.number == _state.deliveryNumber)) {
      logMessage('⚠️ [_completeDelivery] Доставка #${_state.deliveryNumber} уже завершена!');
      return;
    }

    String apartment = _state.apartment?.trim() ?? '';
    if (!_state.isPrivateHouse && apartment.isEmpty) {
      logMessage('⚠️ [_completeDelivery] Номер квартиры не введён');
      _isProcessing = false;
      return;
    }
    if (_state.isPrivateHouse) apartment = 'частный дом (1)';

    logMessage('🔵 [_completeDelivery] Создание Delivery #${_state.deliveryNumber}');
    logMessage('🔵 [_completeDelivery]   clientAddress: ${_state.clientAddress}');
    logMessage('🔵 [_completeDelivery]   apartment: $apartment');
    logMessage('🔵 [_completeDelivery]   weight: ${_state.weight}');
    logMessage('🔵 [_completeDelivery]   timeToShop: ${_state.timeToShop}');
    logMessage('🔵 [_completeDelivery]   distanceToShop: ${_state.distanceToShop}');
    logMessage('🔵 [_completeDelivery]   timeReceiving: ${_state.timeReceiving}');
    logMessage('🔵 [_completeDelivery]   timeToClient: ${_state.timeToClient}');
    logMessage('🔵 [_completeDelivery]   distanceToClient: ${_state.distanceToClient}');
    logMessage('🔵 [_completeDelivery]   timeDelivery: ${_state.timeDelivery}');

    final delivery = Delivery(
      id: 0,
      number: _state.deliveryNumber,
      clientAddress: _state.clientAddress ?? 'Неизвестный адрес',
      apartment: apartment,
      weight: _state.weight ?? 0.0,
      timeToShop: _state.timeToShop,
      distanceToShop: _state.distanceToShop,
      timeReceiving: _state.timeReceiving,
      timeToClient: _state.timeToClient,
      distanceToClient: _state.distanceToClient,
      timeDelivery: _state.timeDelivery,
    );

    final updatedList = List<Delivery>.from(_state.completedDeliveries)..add(delivery);

    logMessage('✅ [_completeDelivery] Добавлена доставка #${_state.deliveryNumber}, всего: ${updatedList.length}', category: 'ORDER');
    logMessage('🔵 [_completeDelivery] completedDeliveries после: ${updatedList.length}');

    setState(() {
      _state = _state.copyWith(
        completedDeliveries: updatedList,
      );
    });
    logMessage('🔵 [_completeDelivery] ВЫХОД');
  }

  void _toggleGpsMode() {
    setState(() {
      final newUseGps = !_state.useGps;
      if (newUseGps) {
        _state = _state.copyWith(
          useGps: true,
          distance: _state.gpsDistance,
        );
      } else {
        _state = _state.copyWith(
          useGps: false,
        );
      }
    });
  }

  void _togglePause() {
    if (_state.isPaused) {
      final now = DateTime.now();
      if (_state.pauseStartTime != null) {
        final added = now.difference(_state.pauseStartTime!);
        setState(() {
          _state = _state.copyWith(
            totalPauseDuration: _state.totalPauseDuration + added,
            pauseStartTime: null,
            isPaused: false,
          );
        });
      }
    } else {
      setState(() {
        _state = _state.copyWith(
          pauseStartTime: DateTime.now(),
          isPaused: true,
        );
      });
    }
  }

  void _updateWeight(double value) {
    setState(() {
      _state = _state.copyWith(
        weight: value,
        isWeightValid: value > 0,
      );
    });
  }

  void _updateApartment(String value) {
    setState(() {
      _state = _state.copyWith(
        apartment: value,
        isApartmentValid: value.trim().isNotEmpty || _state.isPrivateHouse,
      );
    });
  }

  void _togglePrivateHouse(bool value) {
    setState(() {
      _state = _state.copyWith(
        isPrivateHouse: value,
        apartment: value ? '1' : '',
        isApartmentValid: value ? true : false,
      );
    });
  }

  void _addDelivery() {
    logMessage('🔵 [_addDelivery] ВХОД, deliveryNumber=${_state.deliveryNumber}');
    logMessage('🔵 [_addDelivery] completedDeliveries до: ${_state.completedDeliveries.length}');
    
    final alreadyExists = _state.completedDeliveries.any((d) => d.number == _state.deliveryNumber);
    logMessage('🔵 [_addDelivery] alreadyExists: $alreadyExists');
    
    List<Delivery> newCompletedDeliveries = List.from(_state.completedDeliveries);
    
    if (!alreadyExists && _state.clientAddress != null && _state.clientAddress != 'Адрес клиента будет определён позже') {
      logMessage('🔵 [_addDelivery] Сохраняем текущую доставку #${_state.deliveryNumber}');
      final currentDelivery = Delivery(
        id: 0,
        number: _state.deliveryNumber,
        clientAddress: _state.clientAddress ?? 'Неизвестный адрес',
        apartment: _state.apartment ?? '',
        weight: _state.weight ?? 0.0,
        timeToShop: _state.timeToShop,
        distanceToShop: _state.distanceToShop,
        timeReceiving: _state.timeReceiving,
        timeToClient: _state.timeToClient,
        distanceToClient: _state.distanceToClient,
        timeDelivery: _state.timeDelivery,
      );
      newCompletedDeliveries.add(currentDelivery);
      logMessage('📦 Сохранена доставка #${_state.deliveryNumber} перед добавлением новой', category: 'ORDER');
    } else if (alreadyExists) {
      logMessage('🔵 [_addDelivery] Доставка #${_state.deliveryNumber} уже сохранена, пропускаем');
    } else {
      logMessage('🔵 [_addDelivery] clientAddress не готов, пропускаем сохранение');
    }

    logMessage('🔵 [_addDelivery] newCompletedDeliveries: ${newCompletedDeliveries.length}');

    _isSummaryShown = false;

    setState(() {
      _state = _state.copyWith(
        completedDeliveries: newCompletedDeliveries,
        deliveryNumber: _state.deliveryNumber + 1,
        currentSegment: 2,
        weight: null,
        apartment: null,
        isWeightValid: false,
        isApartmentValid: false,
        isPrivateHouse: false,
        distance: 0.0,
        gpsDistance: 0.0,
        showSummary: false,
        useGps: true,
        timeToShop: 0,
        distanceToShop: 0.0,
        timeReceiving: 0,
        timeToClient: 0,
        distanceToClient: 0.0,
        timeDelivery: 0,
        clientAddress: 'Адрес клиента будет определён позже',
        shopAddress: _state.shopAddress,
        coefficient: _state.coefficient,
      );
    });
    
    logMessage('🔵 [_addDelivery] После setState: deliveryNumber=${_state.deliveryNumber}, completedDeliveries=${_state.completedDeliveries.length}');
    
    _gpsService.resetDistance();
    _startSegment();
    logMessage('🔵 [_addDelivery] ВЫХОД');
  }

  void _cancelOrder() {
    _gpsSubscription?.cancel();
    ref.read(shiftProvider.notifier).cancelOrder();
    Navigator.of(context).pop();
  }

  void _showSummary(BuildContext context) {
  logMessage('🔵 [_showSummary] ВХОД, completedDeliveries=${_state.completedDeliveries.length}');
  
  if (_isProcessing) {
    logMessage('⚠️ [_showSummary] ПРОПУСК: уже в обработке');
    return;
  }
  _isProcessing = true;

  final pricing = ref.read(pricingProvider);
  final settings = ref.read(settingsProvider);

  final totalTime = _calculateTotalTime();
  final totalDistance = _calculateTotalDistance();
  final totalCost = _calculateTotalCost(pricing);

  final firstDelivery = _state.completedDeliveries.isNotEmpty 
      ? _state.completedDeliveries.first 
      : null;
  final shopDistance = firstDelivery?.distanceToShop ?? 0.0;
  final totalPaidDistance = _state.completedDeliveries.fold(0.0, (sum, d) => sum + d.distanceToClient);
  final totalAllDistance = shopDistance + totalPaidDistance;

  final fuelCostPerKm = (settings.fuelConsumption / 100) * settings.fuelPrice;
  final totalFuelCost = totalAllDistance * fuelCostPerKm;
  final totalRepairCost = totalAllDistance * settings.repairCost;
  final totalExpenses = totalFuelCost + totalRepairCost;

  logMessage('🟢 _showSummary: завершение заказа');
  logMessage('   доставок: ${_state.completedDeliveries.length}');
  logMessage('   paidDistance: $totalAllDistance');
  logMessage('   income: $totalCost');
  logMessage('   expenses: $totalExpenses');

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => OrderSummaryScreen(
        serviceName: widget.serviceName,
        coefficient: _state.coefficient,
        deliveries: _state.completedDeliveries,
        totalCost: totalCost,
        totalTime: totalTime,
        totalDistance: totalDistance,
        shopAddress: _state.shopAddress,
      ),
    ),
  ).then((result) async {
    logMessage('🔵 [_showSummary] Возврат из OrderSummaryScreen, result=$result');
    if (!mounted) { 
      logMessage('⚠️ [_showSummary] виджет не смонтирован');
      _isProcessing = false; 
      return; 
    }
    
    if (result == true) {
      logMessage('🟢 Добавление ещё доставки');
      _isProcessing = false;
      _addDelivery();
    } else {
      logMessage('🟢 Завершение заказа через API');
      final shiftNotifier = ref.read(shiftProvider.notifier);
      final orderDuration = Duration(seconds: totalTime);
      
      shiftNotifier.finishOrder(
        paidDistance: totalAllDistance,
        income: totalCost,
        expenses: totalExpenses,
        orderDuration: orderDuration,
      );
      
      // ===== ОБНОВЛЯЕМ СТАТИСТИКУ С ПРОВЕРКОЙ mounted =====
      if (mounted) {
        try {
          await ref.refreshStats();
          logMessage('📊 Статистика обновлена после завершения заказа', category: 'STATS');
        } catch (e) {
          logMessage('⚠️ Ошибка обновления статистики: $e', category: 'STATS');
        }
      } else {
        logMessage('⚠️ Виджет не смонтирован, пропускаем обновление статистики', category: 'STATS');
      }
      
      try {
        final apiService = ApiService();
        final orderData = {
          'serviceName': widget.serviceName,
          'coefficient': _state.coefficient,
          'deliveryNumber': _state.deliveryNumber,
          'totalPaidDistance': totalAllDistance,
          'totalIncome': totalCost,
          'totalExpenses': totalExpenses,
          'netProfit': totalCost - totalExpenses,
          'totalTimeSeconds': totalTime,
          'deliveries': _state.completedDeliveries.map((d) => {
            'number': d.number,
            'clientAddress': d.clientAddress,
            'apartment': d.apartment,
            'weight': d.weight,
            'timeToShop': d.timeToShop,
            'distanceToShop': d.distanceToShop,
            'timeReceiving': d.timeReceiving,
            'timeToClient': d.timeToClient,
            'distanceToClient': d.distanceToClient,
            'timeDelivery': d.timeDelivery,
            'status': d.status,
          }).toList(),
        };
        
        logMessage('🔵 [_showSummary] Отправка заказа с ${_state.completedDeliveries.length} доставками');
        await apiService.createOrder(orderData);
        logMessage('✅ Заказ с ${_state.completedDeliveries.length} доставками создан на сервере');
      } catch (e) {
        logMessage('❌ Ошибка создания заказа: $e');
      }
      
      if (mounted) {
        setState(() {
          _state = _state.copyWith(shouldNavigateToHome: true);
        });
      }
      _isProcessing = false;
    }
    logMessage('🔵 [_showSummary] ВЫХОД');
  });
}

  int _calculateTotalTime() {
    if (_state.completedDeliveries.isEmpty) return 0;
    final first = _state.completedDeliveries.first;
    int total = first.timeToShop + first.timeReceiving;
    for (final d in _state.completedDeliveries) {
      total += d.timeToClient + d.timeDelivery;
    }
    return total;
  }

  double _calculateTotalDistance() {
    if (_state.completedDeliveries.isEmpty) return 0.0;
    double total = _state.completedDeliveries.first.distanceToShop;
    for (final d in _state.completedDeliveries) {
      total += d.distanceToClient;
    }
    return total;
  }

  double _calculateTotalCost(PricingConfig pricing) {
    if (_state.completedDeliveries.isEmpty) return 0.0;
    final first = _state.completedDeliveries.first;
    double total = (pricing.receivingFee + (first.weight * pricing.pricePerKg)) * _state.coefficient;
    for (final d in _state.completedDeliveries) {
      total += (pricing.deliveryFee + (d.distanceToClient * pricing.pricePerKm)) * _state.coefficient;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (_state.shouldNavigateToHome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.invalidate(dailyStatsProvider);
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    }

    if (_state.showSummary && !_isSummaryShown) {
      _isSummaryShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showSummary(context);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.serviceName),
            if (_state.deliveryNumber > 1) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Доставка #${_state.deliveryNumber}',
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Отменить', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentProgress(currentSegment: _state.currentSegment),
            const SizedBox(height: 12),
            OrderCard(
              serviceName: widget.serviceName,
              coefficient: _state.coefficient,
              currentSegment: _state.currentSegment,
              deliveryNumber: _state.deliveryNumber,
              weight: _state.weight,
              distance: _state.distance,
              shopAddress: _state.shopAddress,
              clientAddress: _state.clientAddress,
            ),
            const SizedBox(height: 10),
            GpsControl(
              useGps: _state.useGps,
              distance: _state.distance,
              gpsDistance: _state.gpsDistance,
              isPaused: _state.isPaused,
              onToggleGpsMode: _toggleGpsMode,
              onManualDistanceChanged: (value) {
                setState(() {
                  _state = _state.copyWith(distance: value);
                });
              },
              onTogglePause: _togglePause,
            ),
            const SizedBox(height: 12),
            SegmentContent(
              currentSegment: _state.currentSegment,
              weight: _state.weight,
              isWeightValid: _state.isWeightValid,
              apartment: _state.apartment,
              isApartmentValid: _state.isApartmentValid,
              isPrivateHouse: _state.isPrivateHouse,
              onWeightChanged: _updateWeight,
              onApartmentChanged: _updateApartment,
              onPrivateHouseChanged: _togglePrivateHouse,
            ),
            const SizedBox(height: 20),
            ActionButtons(
              currentSegment: _state.currentSegment,
              deliveryNumber: _state.deliveryNumber,
              isWeightValid: _state.isWeightValid,
              isApartmentValid: _state.isApartmentValid,
              isPrivateHouse: _state.isPrivateHouse,
              onMainAction: _handleMainAction,
            ),
          ],
        ),
      ),
    );
  }
}