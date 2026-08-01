import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:delivery_app/features/delivery/models/delivery.dart';
import 'package:delivery_app/features/delivery/services/gps_service.dart';
import 'package:delivery_app/features/delivery/services/geocoder_service.dart';
import 'package:delivery_app/features/delivery/providers/pricing_provider.dart';
import 'package:delivery_app/features/delivery/providers/tab_provider.dart';
import 'package:delivery_app/features/delivery/providers/gps_provider.dart';

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
  });

  factory OrderRouteState.initial({required double coefficient, required int segmentIndex}) {
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
    );
  }
}

class OrderRouteNotifier extends StateNotifier<OrderRouteState> {
  final Ref ref;
  late final GpsService _gpsService;
  StreamSubscription<double>? _gpsSubscription;

  OrderRouteNotifier(this.ref) : super(OrderRouteState.initial(coefficient: 1.0, segmentIndex: 0));

  void resetNavigationFlag() {
    state = state.copyWith(shouldNavigateToHome: false);
  }

  void init({required double coefficient, required int segmentIndex}) {
    _gpsService = GpsService(); // <-- НЕ через ref, а new!
  
    state = OrderRouteState.initial(coefficient: coefficient, segmentIndex: segmentIndex);
    _initGps();
    _startSegment();
  }

  void _initGps() {
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
    _gpsSubscription = _gpsService.distanceStream.listen((distance) {
      if (mounted) {
        state = state.copyWith(distance: distance);
      }
    });
  }

  void _startSegment() {
    state = state.copyWith(
      segmentStartTime: DateTime.now(),
      segmentEndTime: null,
      totalPauseDuration: Duration.zero,
      isPaused: false,
      pauseStartTime: null,
      showSummary: false,
      shouldNavigateToHome: false,
    );
    _gpsService.resetDistance();
    state = state.copyWith(distance: 0.0);
    if (state.useGps && state.currentSegment != 1) {
      _gpsService.startTracking();
    }
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
      if (state.useGps && state.currentSegment != 1) {
        _gpsService.resumeTracking();
      }
    } else {
      state = state.copyWith(
        pauseStartTime: DateTime.now(),
        isPaused: true,
      );
      if (state.useGps && state.currentSegment != 1) {
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
      return 0.0;
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
    if (state.useGps && state.currentSegment == 1) {
      _gpsService.stopTracking();
    }
  }

  void saveCurrentSegmentData() {
    final time = getSegmentTime();
    final distance = getDistance();
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
    finishSegment();
    saveCurrentSegmentData();

    switch (state.currentSegment) {
      case 0:
        final pos = await _getCurrentPosition();
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
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
    } catch (e) {
      _gpsService.addLog('❌ Ошибка получения позиции: $e');
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
    state = state.copyWith(
      completedDeliveries: updatedList,
      showSummary: true,
    );
  }

  void resetAfterSummary() {
    state = state.copyWith(showSummary: false);
    _startNextDelivery();
  }

  void _startNextDelivery() {
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
    );
    _startSegment();
  }

  void finishOrder() {
    _gpsService.stopTracking();
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
    state = OrderRouteState.initial(coefficient: state.coefficient, segmentIndex: 0);
  }

  void resetToInitial() {
    _gpsService.stopTracking();
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
    state = OrderRouteState.initial(
      coefficient: state.coefficient,
      segmentIndex: 0,
    );
  }

  void cancelOrder() {
    _gpsService.stopTracking();
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
    state = OrderRouteState.initial(
      coefficient: state.coefficient,
      segmentIndex: 0,
    );
    state = state.copyWith(shouldNavigateToHome: true);
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    _gpsService.stopTracking();
    super.dispose();
  }
}