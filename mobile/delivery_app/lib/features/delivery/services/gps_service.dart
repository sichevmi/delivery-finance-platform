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

  // Минимальная скорость для засчёта движения (м/с) - 1 м/с ≈ 3.6 км/ч
  static const double _minSpeed = 1.0;

  double get currentDistance => _totalDistance;

  final _distanceStreamController = StreamController<double>.broadcast();
  Stream<double> get distanceStream => _distanceStreamController.stream;

  Future<bool> requestPermissions(BuildContext context) async {
    var status = await Permission.locationAlways.request();
    
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
    print('🟢 GPS: tracking started, waiting for position...');

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5, // обновления при перемещении > 5 метров
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      print('📍 GPS: position - lat: ${position.latitude}, lon: ${position.longitude}, acc: ${position.accuracy}m, speed: ${position.speed?.toStringAsFixed(2)} m/s');

      // Игнорируем плохой сигнал (точность хуже 15 метров)
      if (position.accuracy > 15) {
        print('⚠️ GPS: poor accuracy (${position.accuracy}m), ignoring');
        return;
      }

      if (_isPaused) {
        print('⏸️ GPS: paused, ignoring position');
        return;
      }

      // Игнорируем, если скорость меньше минимальной (стоим на месте)
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

        // Игнорируем слишком маленькие перемещения (шум)
        if (distance < 2.0) {
          print('📏 GPS: distance too small (${distance.toStringAsFixed(2)}m), ignoring');
          return;
        }

        // Игнорируем очень большие скачки (> 200 метров за раз)
        if (distance > 200) {
          print('⚠️ GPS: extreme jump (${distance.toStringAsFixed(2)}m > 200m), ignoring');
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
    _distanceStreamController.add(0.0);
  }

  double getTotalDistance() => _totalDistance;

  void resetDistance() {
    print('🔄 GPS: resetDistance()');
    _totalDistance = 0.0;
    _lastPosition = null;
    _distanceStreamController.add(0.0);
  }

  Future<void> _getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      _lastPosition = position;
      print('📍 GPS: current position updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('⚠️ GPS: error getting current position: $e');
    }
  }
}