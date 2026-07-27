import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class GpsService {
  static final GpsService _instance = GpsService._internal();
  factory GpsService() => _instance;
  GpsService._internal();

  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;
  double _totalDistance = 0.0;
  Position? _lastPosition;
  bool _isPaused = false;

  // Меньше сглаживания — точнее
  static const double _alpha = 0.15;
  Position? _smoothedPosition;

  // Минимальное расстояние для засчёта перемещения (0.5 м) - чтобы не игнорировать мелкие движения
  static const double _minDistance = 0.5;
  // Минимальная скорость отключаем — будем полагаться только на расстояние
  // static const double _minSpeed = 0.0; // не используем

  double get currentDistance => _totalDistance;

  final _distanceStreamController = StreamController<double>.broadcast();
  Stream<double> get distanceStream => _distanceStreamController.stream;

  Future<bool> requestPermissions(BuildContext context) async {
    var status = await Permission.location.status;
    
    if (status.isDenied) {
      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Нужен доступ к геолокации'),
          content: const Text(
            'Приложению нужен доступ к вашему местоположению для отслеживания маршрута доставки.\n\n'
            'Данные используются только во время активной доставки.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Разрешить'),
            ),
          ],
        ),
      );
      
      if (shouldRequest != true) return false;
      status = await Permission.location.request();
    }
    
    if (status.isGranted) {
      if (await Geolocator.isLocationServiceEnabled()) {
        return true;
      } else {
        await Geolocator.openLocationSettings();
        return false;
      }
    }
    
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    
    return false;
  }

  Position _smoothPosition(Position newPos) {
    if (_smoothedPosition == null) {
      _smoothedPosition = newPos;
      return newPos;
    }

    final smoothedLat = _smoothedPosition!.latitude + _alpha * (newPos.latitude - _smoothedPosition!.latitude);
    final smoothedLon = _smoothedPosition!.longitude + _alpha * (newPos.longitude - _smoothedPosition!.longitude);

    _smoothedPosition = Position(
      latitude: smoothedLat,
      longitude: smoothedLon,
      timestamp: newPos.timestamp,
      accuracy: newPos.accuracy,
      altitude: newPos.altitude,
      heading: newPos.heading,
      speed: newPos.speed,
      speedAccuracy: newPos.speedAccuracy,
      altitudeAccuracy: newPos.altitudeAccuracy,
      headingAccuracy: newPos.headingAccuracy,
    );
    return _smoothedPosition!;
  }

  void startTracking() {
    print('🟢 GPS: startTracking() called');
    if (_isTracking) {
      print('🟡 GPS: already tracking, ignoring');
      return;
    }

    _isTracking = true;
    _isPaused = false;
    _totalDistance = 0.0;
    _lastPosition = null;
    _smoothedPosition = null;
    print('🟢 GPS: tracking started, waiting for position...');

    // Настройки для максимальной точности и частоты
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0, // обрабатываем все обновления
      // intervalDuration: Duration(seconds: 1), // если поддерживается
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position rawPosition) {
      print('📍 GPS: raw position - lat: ${rawPosition.latitude}, lon: ${rawPosition.longitude}');

      // Фильтр по точности (отбрасываем совсем плохие сигналы)
      if (rawPosition.accuracy > 25) {
        print('⚠️ GPS: poor accuracy (${rawPosition.accuracy}m), ignoring');
        return;
      }

      if (_isPaused) {
        print('⏸️ GPS: paused, ignoring position');
        return;
      }

      final position = _smoothPosition(rawPosition);

      // Проверка по скорости больше не используется.
      // Вместо этого просто смотрим на расстояние.

      if (_lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        // Минимальное расстояние для засчёта (0.5 м)
        if (distance < _minDistance) {
          print('📏 GPS: distance too small (${distance.toStringAsFixed(2)}m), ignoring');
          return;
        }

        // Экстремальный выброс (>500 м) — игнорируем
        if (distance > 500) {
          print('⚠️ GPS: extreme jump (${distance.toStringAsFixed(2)}m > 500m), ignoring');
          return;
        }

        print('📏 GPS: distance since last update: ${distance.toStringAsFixed(2)} meters');
        _totalDistance += distance / 1000;
        print('📏 GPS: total distance: ${_totalDistance.toStringAsFixed(4)} km');
      } else {
        print('🟢 GPS: first position, initializing');
      }
      _lastPosition = position;
      _distanceStreamController.add(_totalDistance);
    }, onError: (error) {
      print('🔴 GPS error: $error');
    });
  }

  void pauseTracking() {
    print('⏸️ GPS: pauseTracking()');
    _isPaused = true;
  }

  void resumeTracking() {
    print('▶️ GPS: resumeTracking()');
    _isPaused = false;
    _getCurrentPosition();
  }

  void stopTracking() {
    print('🛑 GPS: stopTracking()');
    _isTracking = false;
    _isPaused = false;
    _positionStream?.cancel();
    _positionStream = null;
    _lastPosition = null;
    _smoothedPosition = null;
    _distanceStreamController.add(0.0);
  }

  double getTotalDistance() => _totalDistance;

  void resetDistance() {
    print('🔄 GPS: resetDistance()');
    _totalDistance = 0.0;
    _lastPosition = null;
    _smoothedPosition = null;
    _distanceStreamController.add(0.0);
  }

  Future<void> _getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      _lastPosition = position;
      _smoothedPosition = position;
      print('📍 GPS: current position updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('⚠️ GPS: error getting current position: $e');
    }
  }
}