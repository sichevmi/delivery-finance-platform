import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class GpsService {
  static final GpsService _instance = GpsService._internal();
  factory GpsService() => _instance;
  GpsService._internal();

  Timer? _pollingTimer;
  bool _isTracking = false;
  double _totalDistance = 0.0;
  Position? _lastPosition;
  bool _isPaused = false;

  // Интервал опроса: 1 секунда для автомобиля
  static const int _pollInterval = 1;

  double get currentDistance => _totalDistance;

  final _distanceStreamController = StreamController<double>.broadcast();
  Stream<double> get distanceStream => _distanceStreamController.stream;

  void startTracking() {
    print('🟢 GPS: startTracking() called (POLLING 1s)');
    if (_isTracking) {
      print('🟡 GPS: already tracking, ignoring');
      return;
    }

    _isTracking = true;
    _isPaused = false;
    _totalDistance = 0.0;
    _lastPosition = null;

    // Запускаем таймер опроса каждую секунду
    _pollingTimer = Timer.periodic(
      Duration(seconds: _pollInterval),
      _pollGps,
    );
    print('🟢 GPS: polling started every $_pollInterval second(s)');
  }

  Future<void> _pollGps(Timer timer) async {
    if (!_isTracking || _isPaused) {
      return;
    }

    try {
      // Запрашиваем позицию с максимальной точностью
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      print('📍 GPS: poll - lat: ${position.latitude}, lon: ${position.longitude}, '
          'acc: ${position.accuracy}m, speed: ${position.speed?.toStringAsFixed(2) ?? 'N/A'} m/s');

      // Для автомобиля увеличиваем допустимую погрешность до 25 метров
      if (position.accuracy > 25) {
        print('⚠️ GPS: poor accuracy (${position.accuracy}m), ignoring');
        return;
      }

      // Если скорость высокая (> 2 м/с), можно игнорировать точность (но мы уже проверили)
      // Можно также учитывать скорость для определения движения

      if (_lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        // Для автомобиля увеличиваем минимальное расстояние до 1 метра
        if (distance < 1.0) {
          print('📏 GPS: distance too small (${distance.toStringAsFixed(2)}m), ignoring');
          return;
        }

        // Для автомобиля увеличиваем допустимый выброс до 500 метров
        if (distance > 500) {
          print('⚠️ GPS: extreme jump (${distance.toStringAsFixed(2)}m > 500m), ignoring');
          return;
        }

        print('📏 GPS: distance: ${distance.toStringAsFixed(2)}m, total: ${_totalDistance.toStringAsFixed(4)}km');
        _totalDistance += distance / 1000;
        _distanceStreamController.add(_totalDistance);
      } else {
        print('🟢 GPS: first position, initializing');
      }
      _lastPosition = position;

    } catch (e) {
      print('⚠️ GPS: poll error - $e');
    }
  }

  void pauseTracking() {
    print('⏸️ GPS: pauseTracking()');
    _isPaused = true;
  }

  void resumeTracking() {
    print('▶️ GPS: resumeTracking()');
    _isPaused = false;
  }

  void stopTracking() {
    print('🛑 GPS: stopTracking()');
    _isTracking = false;
    _isPaused = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _lastPosition = null;
    _distanceStreamController.add(0.0);
  }

  void forceRefresh() {
    print('🔄 GPS: forceRefresh() called');
    if (_isTracking && !_isPaused) {
      // Вызываем poll немедленно
      _pollGps(Timer.periodic(Duration(seconds: 1), (timer) {}));
    }
  }

  double getTotalDistance() => _totalDistance;

  void resetDistance() {
    print('🔄 GPS: resetDistance()');
    _totalDistance = 0.0;
    _lastPosition = null;
    _distanceStreamController.add(0.0);
  }
}