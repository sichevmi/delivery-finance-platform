import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/features/delivery/models/delivery.dart';
import 'package:delivery_app/features/delivery/services/gps_service.dart';
import 'package:delivery_app/features/delivery/services/geocoder_service.dart';
import 'package:delivery_app/features/delivery/providers/pricing_provider.dart';
import 'package:delivery_app/features/delivery/providers/tab_provider.dart';
import 'package:delivery_app/features/delivery/providers/gps_provider.dart';
import 'package:delivery_app/features/delivery/providers/shift_provider.dart';
import 'package:delivery_app/features/delivery/providers/daily_stats_provider.dart';
import 'package:delivery_app/core/database/database_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

final orderRouteProvider = StateNotifierProvider<OrderRouteNotifier, OrderRouteState>((ref) {
  return OrderRouteNotifier(ref);
});

class OrderRouteState {
  final int currentSegment;
  final bool useGps;
  final double distance;
  final DateTime? segmentStartTime;
  final DateTime? segmentEndTime;
  final Duration totalPauseDuration;
  final DateTime? pauseStartTime;
  final bool isPaused;
  final int timeToShop;
  final double distanceToShop;
  final int timeReceiving;
  final int timeToClient;
  final double distanceToClient;
  final int timeDelivery;
  final double coefficient;
  final double? weight;
  final bool isWeightValid;
  final String? shopAddress;
  final String? clientAddress;
  final int deliveryNumber;
  final List<Delivery> completedDeliveries;
  final String apartment;
  final bool isApartmentValid;
  final bool isPrivateHouse;
  final bool showSummary;
  final bool shouldNavigateToHome;
  final double manualDistance;
  
  // Новые поля для сохранения
  final String? serviceName;
  final double? totalAllDistance;
  final double? totalCost;
  final double? totalExpenses;
  final int? totalTime;

  const OrderRouteState({
    required this.currentSegment,
    required this.useGps,
    required this.distance,
    this.segmentStartTime,
    this.segmentEndTime,
    required this.totalPauseDuration,
    this.pauseStartTime,
    required this.isPaused,
    required this.timeToShop,
    required this.distanceToShop,
    required this.timeReceiving,
    required this.timeToClient,
    required this.distanceToClient,
    required this.timeDelivery,
    required this.coefficient,
    this.weight,
    required this.isWeightValid,
    this.shopAddress,
    this.clientAddress,
    required this.deliveryNumber,
    required this.completedDeliveries,
    required this.apartment,
    required this.isApartmentValid,
    required this.isPrivateHouse,
    this.showSummary = false,
    this.shouldNavigateToHome = false,
    this.manualDistance = 0.0,
    this.serviceName,
    this.totalAllDistance,
    this.totalCost,
    this.totalExpenses,
    this.totalTime,
  });

  factory OrderRouteState.initial({required double coefficient, required int segmentIndex, String? serviceName}) {
    return OrderRouteState(
      currentSegment: segmentIndex,
      useGps: true,
      distance: 0.0,
      segmentStartTime: null,
      segmentEndTime: null,
      totalPauseDuration: Duration.zero,
      pauseStartTime: null,
      isPaused: false,
      timeToShop: 0,
      distanceToShop: 0.0,
      timeReceiving: 0,
      timeToClient: 0,
      distanceToClient: 0.0,
      timeDelivery: 0,
      coefficient: coefficient,
      weight: null,
      isWeightValid: false,
      shopAddress: null,
      clientAddress: null,
      deliveryNumber: 1,
      completedDeliveries: [],
      apartment: '',
      isApartmentValid: false,
      isPrivateHouse: false,
      showSummary: false,
      shouldNavigateToHome: false,
      manualDistance: 0.0,
      serviceName: serviceName,
      totalAllDistance: null,
      totalCost: null,
      totalExpenses: null,
      totalTime: null,
    );
  }

  OrderRouteState copyWith({
    int? currentSegment,
    bool? useGps,
    double? distance,
    DateTime? segmentStartTime,
    DateTime? segmentEndTime,
    Duration? totalPauseDuration,
    DateTime? pauseStartTime,
    bool? isPaused,
    int? timeToShop,
    double? distanceToShop,
    int? timeReceiving,
    int? timeToClient,
    double? distanceToClient,
    int? timeDelivery,
    double? coefficient,
    double? weight,
    bool? isWeightValid,
    String? shopAddress,
    String? clientAddress,
    int? deliveryNumber,
    List<Delivery>? completedDeliveries,
    String? apartment,
    bool? isApartmentValid,
    bool? isPrivateHouse,
    bool? showSummary,
    bool? shouldNavigateToHome,
    double? manualDistance,
    String? serviceName,
    double? totalAllDistance,
    double? totalCost,
    double? totalExpenses,
    int? totalTime,
  }) {
    return OrderRouteState(
      currentSegment: currentSegment ?? this.currentSegment,
      useGps: useGps ?? this.useGps,
      distance: distance ?? this.distance,
      segmentStartTime: segmentStartTime ?? this.segmentStartTime,
      segmentEndTime: segmentEndTime ?? this.segmentEndTime,
      totalPauseDuration: totalPauseDuration ?? this.totalPauseDuration,
      pauseStartTime: pauseStartTime ?? this.pauseStartTime,
      isPaused: isPaused ?? this.isPaused,
      timeToShop: timeToShop ?? this.timeToShop,
      distanceToShop: distanceToShop ?? this.distanceToShop,
      timeReceiving: timeReceiving ?? this.timeReceiving,
      timeToClient: timeToClient ?? this.timeToClient,
      distanceToClient: distanceToClient ?? this.distanceToClient,
      timeDelivery: timeDelivery ?? this.timeDelivery,
      coefficient: coefficient ?? this.coefficient,
      weight: weight ?? this.weight,
      isWeightValid: isWeightValid ?? this.isWeightValid,
      shopAddress: shopAddress ?? this.shopAddress,
      clientAddress: clientAddress ?? this.clientAddress,
      deliveryNumber: deliveryNumber ?? this.deliveryNumber,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      apartment: apartment ?? this.apartment,
      isApartmentValid: isApartmentValid ?? this.isApartmentValid,
      isPrivateHouse: isPrivateHouse ?? this.isPrivateHouse,
      showSummary: showSummary ?? this.showSummary,
      shouldNavigateToHome: shouldNavigateToHome ?? this.shouldNavigateToHome,
      manualDistance: manualDistance ?? this.manualDistance,
      serviceName: serviceName ?? this.serviceName,
      totalAllDistance: totalAllDistance ?? this.totalAllDistance,
      totalCost: totalCost ?? this.totalCost,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalTime: totalTime ?? this.totalTime,
    );
  }
}

class OrderRouteNotifier extends StateNotifier<OrderRouteState> {
  final Ref ref;
  late GpsService _gpsService;
  StreamSubscription<double>? _gpsSubscription;
  bool _isGpsInitialized = false;
  bool _gpsTrackingStarted = false;

  OrderRouteNotifier(this.ref) : super(OrderRouteState.initial(coefficient: 1.0, segmentIndex: 0, serviceName: null)) {
    logMessage('🟢 OrderRouteNotifier: создан');
  }

  void resetNavigationFlag() {
    state = state.copyWith(shouldNavigateToHome: false);
  }

  void init({required double coefficient, required int segmentIndex, required String serviceName}) {
    logMessage('🟢 OrderRouteNotifier.init(): coefficient=$coefficient, segmentIndex=$segmentIndex, serviceName=$serviceName');
    
    try {
      _gpsService = ref.read(gpsServiceProvider);
      logMessage('🟢 OrderRouteNotifier: получили GpsService instance ${_gpsService.hashCode}');
    } catch (e) {
      logMessage('⚠️ Ошибка получения GpsService: $e');
      ref.read(gpsInitProvider);
      _gpsService = ref.read(gpsServiceProvider);
      logMessage('🟢 OrderRouteNotifier: GpsService создан после инициализации');
    }
    
    _isGpsInitialized = true;
    state = OrderRouteState.initial(coefficient: coefficient, segmentIndex: segmentIndex, serviceName: serviceName);
    _initGps();
    _startGpsTracking();
    _startSegment();
  }

  void updateManualDistance(double distance) {
    state = state.copyWith(manualDistance: distance);
  }

  void _initGps() {
    logMessage('🟢 OrderRouteNotifier._initGps()');
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
    _gpsSubscription = _gpsService.distanceStream.listen((distance) {
      logMessage('📍 OrderRoute GPS distance обновление: $distance');
      if (mounted) {
        state = state.copyWith(distance: distance);
      }
    });
    logMessage('🟢 OrderRouteNotifier._initGps() - подписка создана');
  }

  void _startGpsTracking() {
    logMessage('🟢 OrderRouteNotifier._startGpsTracking()');
    _gpsTrackingStarted = true;
    _gpsService.resetDistance();
    state = state.copyWith(distance: 0.0);
    state = state.copyWith(manualDistance: 0.0);
    
    if (state.useGps) {
      logMessage('🟢 ЗАПУСКАЕМ GPS трекинг для сегмента ${state.currentSegment}');
      _gpsService.startTracking();
    } else {
      logMessage('⚠️ GPS НЕ запущен: useGps=${state.useGps}');
    }
  }

  void _startSegment() {
    logMessage('🟢 OrderRouteNotifier._startSegment() segment: ${state.currentSegment}');
    
    state = state.copyWith(
      segmentStartTime: DateTime.now(),
      segmentEndTime: null,
      totalPauseDuration: Duration.zero,
      isPaused: false,
      pauseStartTime: null,
      showSummary: false,
      shouldNavigateToHome: false,
    );
    
    logMessage('🟢 Сброс расстояния для нового сегмента ${state.currentSegment}');
    _gpsService.resetDistance();
    state = state.copyWith(distance: 0.0);
    state = state.copyWith(manualDistance: 0.0);
  }

  void togglePause() {
    if (state.isPaused) {
      final now = DateTime.now();
      if (state.pauseStartTime != null) {
        final added = now.difference(state.pauseStartTime!);
        state = state.copyWith(
          totalPauseDuration: state.totalPauseDuration + added,
          pauseStartTime: null,
          isPaused: false,
        );
      }
      if (state.useGps) {
        _gpsService.resumeTracking();
      }
    } else {
      state = state.copyWith(
        pauseStartTime: DateTime.now(),
        isPaused: true,
      );
      if (state.useGps) {
        _gpsService.pauseTracking();
      }
    }
  }

  int getSegmentTime() {
    if (state.segmentStartTime == null) return 0;
    final endTime = state.segmentEndTime ?? DateTime.now();
    final rawDuration = endTime.difference(state.segmentStartTime!);
    final result = rawDuration - state.totalPauseDuration;
    return result.inSeconds.clamp(0, 86400).toInt();
  }

  double getDistance() {
    if (state.useGps) {
      return state.distance;
    } else {
      return state.manualDistance;
    }
  }

  void finishSegment() {
    final end = DateTime.now();
    if (state.isPaused) {
      if (state.pauseStartTime != null) {
        final added = end.difference(state.pauseStartTime!);
        state = state.copyWith(
          totalPauseDuration: state.totalPauseDuration + added,
          pauseStartTime: null,
          isPaused: false,
        );
      }
    }
    state = state.copyWith(segmentEndTime: end);
  }

  void saveCurrentSegmentData() {
    final time = getSegmentTime();
    final distance = getDistance();
    logMessage('📊 Сохраняем сегмент ${state.currentSegment}: time=$time сек, distance=$distance км');
    switch (state.currentSegment) {
      case 0:
        state = state.copyWith(timeToShop: time, distanceToShop: distance);
        break;
      case 1:
        state = state.copyWith(timeReceiving: time);
        break;
      case 2:
        state = state.copyWith(timeToClient: time, distanceToClient: distance);
        break;
      case 3:
        state = state.copyWith(timeDelivery: time);
        break;
    }
  }

  Future<void> handleMainAction() async {
    logMessage('🟢 handleMainAction() сегмент ${state.currentSegment}');
    finishSegment();
    saveCurrentSegmentData();

    switch (state.currentSegment) {
      case 0:
        final pos = await _getCurrentPosition();
        if (!mounted) return;
        String? addr;
        if (pos != null) {
          addr = await GeocoderService.reverseGeocode(pos.latitude, pos.longitude, onLog: _gpsService.addLog);
        }
        state = state.copyWith(shopAddress: addr ?? 'Адрес не определён');
        state = state.copyWith(currentSegment: 1);
        _startSegment();
        break;
      case 1:
        if (state.weight == null || state.weight! <= 0) return;
        state = state.copyWith(
          clientAddress: 'Адрес клиента будет определён позже',
          currentSegment: 2,
        );
        _startSegment();
        break;
      case 2:
        final pos = await _getCurrentPosition();
        if (!mounted) return;
        String? addr;
        if (pos != null) {
          addr = await GeocoderService.reverseGeocode(pos.latitude, pos.longitude, onLog: _gpsService.addLog);
        }
        state = state.copyWith(clientAddress: addr ?? 'Адрес не определён');
        state = state.copyWith(currentSegment: 3);
        _startSegment();
        break;
      case 3:
        await _completeDelivery();
        break;
    }
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      if (kIsWeb) {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            logMessage('⏰ Таймаут получения позиции на вебе');
            throw TimeoutException('Превышено время ожидания позиции');
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
          logMessage('⏰ Таймаут получения позиции');
          throw TimeoutException('Превышено время ожидания позиции');
        },
      );
    } catch (e) {
      logMessage('❌ Ошибка получения позиции: $e');
      return null;
    }
  }

  Future<void> _completeDelivery() async {
    String apartment = state.apartment.trim();
    if (!state.isPrivateHouse && apartment.isEmpty) return;
    if (state.isPrivateHouse) apartment = 'частный дом (1)';

    final delivery = Delivery(
      number: state.deliveryNumber,
      clientAddress: state.clientAddress ?? 'Неизвестный адрес',
      weight: state.weight ?? 0.0,
      apartment: apartment,
      timeToShop: state.timeToShop,
      distanceToShop: state.distanceToShop,
      timeReceiving: state.timeReceiving,
      timeToClient: state.timeToClient,
      distanceToClient: state.distanceToClient,
      timeDelivery: state.timeDelivery,
    );

    final updatedList = List<Delivery>.from(state.completedDeliveries)..add(delivery);

    if (mounted) {
      state = state.copyWith(
        completedDeliveries: updatedList,
        showSummary: true,
      );
    }
  }

  void resetAfterSummary() {
    if (!mounted) return;
    state = state.copyWith(showSummary: false);
    _startNextDelivery();
  }

  void _startNextDelivery() {
    if (!mounted) return;
    state = state.copyWith(
      deliveryNumber: state.deliveryNumber + 1,
      currentSegment: 2,
      clientAddress: 'Адрес клиента будет определён позже',
      apartment: '',
      isApartmentValid: false,
      isPrivateHouse: false,
      weight: null,
      isWeightValid: false,
      showSummary: false,
      manualDistance: 0.0,
    );
    _startGpsTracking();
    _startSegment();
  }

  // ===== ИСПРАВЛЕННЫЙ finishOrder с сохранением в БД =====
 // В order_route_provider.dart
Future<void> finishOrder() async {
  if (!mounted) return;
  logMessage('🟢 finishOrder() - завершаем заказ', category: 'ORDER');
  
  try {
    final db = ref.read(appDatabaseProvider);
    final shiftState = ref.read(shiftProvider);
    
    // Проверяем, не был ли уже сохранён этот заказ
    final existingOrders = await db.orderDao.getOrdersForDate(DateTime.now());
    final alreadyExists = existingOrders.any((o) => 
      o.deliveryNumber == state.deliveryNumber && 
      o.shiftId == shiftState.localShiftId
    );
    
    if (!alreadyExists && state.totalAllDistance != null && state.totalCost != null) {
      // Сохраняем заказ
      final orderId = await db.orderDao.insertOrder(
        serviceName: state.serviceName ?? 'Доставка',
        coefficient: state.coefficient,
        deliveryNumber: state.deliveryNumber,
        totalPaidDistance: state.totalAllDistance!,
        totalIncome: state.totalCost!,
        totalExpenses: state.totalExpenses ?? 0,
        netProfit: state.totalCost! - (state.totalExpenses ?? 0),
        totalTimeSeconds: state.totalTime ?? 0,
        shiftId: shiftState.localShiftId,
        status: 'completed',
      );
      logMessage('💾 Заказ сохранён в БД (id=$orderId)', category: 'ORDER');
      
      // Сохраняем доставки
      for (final delivery in state.completedDeliveries) {
        await db.deliveryDao.insertDelivery(
          number: delivery.number,
          clientAddress: delivery.clientAddress,
          apartment: delivery.apartment,
          weight: delivery.weight,
          timeToShop: delivery.timeToShop,
          distanceToShop: delivery.distanceToShop,
          timeReceiving: delivery.timeReceiving,
          timeToClient: delivery.timeToClient,
          distanceToClient: delivery.distanceToClient,
          timeDelivery: delivery.timeDelivery,
          orderId: orderId,
          status: 'completed',
        );
        logMessage('💾 Доставка #${delivery.number} сохранена', category: 'ORDER');
      }
      logMessage('✅ Заказ сохранён в БД (доставок: ${state.completedDeliveries.length})', category: 'ORDER');
    } else {
      logMessage('⚠️ Заказ уже существует в БД или данные неполные, пропускаем сохранение', category: 'ORDER');
    }
  } catch (e) {
    logMessage('❌ Ошибка сохранения заказа в БД: $e', category: 'ORDER', level: LogLevel.error);
  }
  
  // Сбрасываем расстояние
  _gpsService.resetDistance();
  state = state.copyWith(distance: 0.0, manualDistance: 0.0);
  
  // Отписываемся от стрима, но GPS продолжает работать
  _gpsSubscription?.cancel();
  _gpsSubscription = null;
  _gpsTrackingStarted = false;
  
  // Сбрасываем состояние
  state = OrderRouteState.initial(coefficient: state.coefficient, segmentIndex: 0, serviceName: state.serviceName);
  
  // Обновляем статистику
  ref.invalidate(dailyStatsProvider);
  logMessage('📊 Статистика обновлена', category: 'STATS');
  logMessage('🟢 finishOrder() - GPS продолжает работу для холостого пробега');
}

  void resetToInitial() {
    if (!mounted) return;
    _gpsService.stopTracking();
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
    _gpsTrackingStarted = false;
    state = OrderRouteState.initial(
      coefficient: state.coefficient,
      segmentIndex: 0,
      serviceName: state.serviceName,
    );
  }

  // ===== ИСПРАВЛЕННЫЙ cancelOrder =====
  void cancelOrder() {
    if (!mounted) return;
    
    logMessage('🟢 cancelOrder() - отмена заказа');
    
    final shiftNotifier = ref.read(shiftProvider.notifier);
    shiftNotifier.cancelOrder();
    
    _gpsService.resetDistance();
    state = state.copyWith(distance: 0.0, manualDistance: 0.0);
    
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
    _gpsTrackingStarted = false;
    
    state = OrderRouteState.initial(
      coefficient: state.coefficient,
      segmentIndex: 0,
      serviceName: state.serviceName,
    );
    state = state.copyWith(shouldNavigateToHome: true);
    
    logMessage('🟢 cancelOrder() - GPS продолжает работу для холостого пробега');
  }

  @override
  void dispose() {
    logMessage('🛑 OrderRouteNotifier.dispose()');
    _gpsSubscription?.cancel();
    super.dispose();
  }
}