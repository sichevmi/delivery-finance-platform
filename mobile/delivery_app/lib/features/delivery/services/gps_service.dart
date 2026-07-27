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

  static const double _alpha = 0.3;
  Position? _smoothedPosition;

  // Минимальная скорость для засчёта движения (м/с)
  static const double _minSpeed = 0.2; // ~0.7 км/ч

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

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5, // увеличили до 5 метров
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position rawPosition) {
      print('📍 GPS: raw position - lat: ${rawPosition.latitude}, lon: ${rawPosition.longitude}');

      if (rawPosition.accuracy > 20) {
        print('⚠️ GPS: poor accuracy (${rawPosition.accuracy}m), ignoring');
        return;
      }

      if (_isPaused) {
        print('⏸️ GPS: paused, ignoring position');
        return;
      }

      final position = _smoothPosition(rawPosition);

      // Проверяем скорость: если скорость меньше минимальной, считаем, что стоим
      if (position.speed != null && position.speed! < _minSpeed) {
        print('⏸️ GPS: speed too low (${position.speed!.toStringAsFixed(2)} m/s), ignoring');
        return;
      }

      if (_lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        if (distance < 1.5) {
          print('📏 GPS: distance too small (${distance.toStringAsFixed(2)}m), ignoring');
          return;
        }

        const maxSpeed = 3.0; // 10.8 км/ч (пешком)
        final timeDelta = position.timestamp.difference(_lastPosition!.timestamp).inSeconds;
        final maxDistancePerUpdate = maxSpeed * timeDelta.clamp(1, 5);

        if (distance > maxDistancePerUpdate) {
          print('⚠️ GPS: suspicious jump (${distance.toStringAsFixed(2)}m > ${maxDistancePerUpdate.toStringAsFixed(2)}m), ignoring');
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