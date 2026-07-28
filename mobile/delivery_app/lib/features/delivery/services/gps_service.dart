import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class GpsService {
  static final GpsService _instance = GpsService._internal();
  factory GpsService() => _instance;
  GpsService._internal();

  Timer? _pollingTimer;
  bool _isTracking = false;
  double _totalDistance = 0.0;
  Position? _lastPosition;
  bool _isPaused = false;

  // Интервал опроса (секунды)
  static const int _pollInterval = 2;

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

  void startTracking() {
    print('🟢 GPS: startTracking() called (POLLING mode)');
    if (_isTracking) {
      print('🟡 GPS: already tracking, ignoring');
      return;
    }

    _isTracking = true;
    _isPaused = false;
    _totalDistance = 0.0;
    _lastPosition = null;

    // Запускаем таймер для опроса GPS
    _pollingTimer = Timer.periodic(
      Duration(seconds: _pollInterval),
      _pollGps,
    );
    print('🟢 GPS: polling started every $_pollInterval seconds');
  }

  Future<void> _pollGps(Timer timer) async {
    if (!_isTracking || _isPaused) {
      print('⏸️ GPS: polling skipped (paused or stopped)');
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      print('📍 GPS: poll - lat: ${position.latitude}, lon: ${position.longitude}, acc: ${position.accuracy}m');

      // Игнорируем плохой сигнал
      if (position.accuracy > 15) {
        print('⚠️ GPS: poor accuracy (${position.accuracy}m), ignoring');
        return;
      }

      if (_lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        // Игнорируем шум (< 2 метров)
        if (distance < 2.0) {
          print('📏 GPS: distance too small (${distance.toStringAsFixed(2)}m), ignoring');
          return;
        }

        // Игнорируем выбросы (> 200 метров)
        if (distance > 200) {
          print('⚠️ GPS: extreme jump (${distance.toStringAsFixed(2)}m > 200m), ignoring');
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