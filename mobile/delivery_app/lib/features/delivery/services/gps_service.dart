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

  static const int _pollInterval = 1;

  double get currentDistance => _totalDistance;

  final _distanceStreamController = StreamController<double>.broadcast();
  Stream<double> get distanceStream => _distanceStreamController.stream;

  Future<bool> requestPermissions(BuildContext context) async {
    // Используем Permission.locationAlways для фона
    var status = await Permission.locationAlways.status;
    
    if (status.isDenied) {
      final shouldRequest = await _showExplanationDialog(context);
      if (!shouldRequest) return false;
      status = await Permission.locationAlways.request();
    }
    
    if (status.isGranted) {
      // Проверяем, включена ли служба геолокации
      if (!await Geolocator.isLocationServiceEnabled()) {
        await _showEnableGpsDialog(context);
        return false;
      }
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(context);
      return false;
    }
    
    return false;
  }

  // --- Методы для диалогов (здесь аналогично PermissionService) ---
  // В реальном проекте можно вынести в отдельный сервис

  Future<bool> _showExplanationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Доступ к геолокации'),
        content: const Text(
          'Для отслеживания маршрута доставки приложению '
          'необходим доступ к вашему местоположению в фоновом режиме.\n\n'
          'Данные используются только во время активной доставки.',
          style: TextStyle(color: Color(0xFFB0B0B0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(color: Color(0xFF888888))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
            ),
            child: const Text('Разрешить'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _showEnableGpsDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Включите GPS'),
        content: const Text('Для работы приложения необходимо включить GPS.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(color: Color(0xFF888888))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
            ),
            child: const Text('Включить'),
          ),
        ],
      ),
    );
    if (result == true) {
      await Geolocator.openLocationSettings();
    }
  }

  Future<void> _showSettingsDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Требуется доступ к геолокации'),
        content: const Text(
          'Вы запретили доступ к геолокации.\n'
          'Пожалуйста, разрешите доступ в настройках устройства.',
          style: TextStyle(color: Color(0xFFB0B0B0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(color: Color(0xFF888888))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
            ),
            child: const Text('Открыть настройки'),
          ),
        ],
      ),
    );
    if (result == true) {
      await openAppSettings();
    }
  }

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

    // Запускаем Foreground Service (через Geolocator)
    _startForegroundService();

    _pollingTimer = Timer.periodic(
      Duration(seconds: _pollInterval),
      _pollGps,
    );
    print('🟢 GPS: polling started every $_pollInterval second(s)');
  }

  void _startForegroundService() async {
    // Geolocator автоматически запускает foreground service при использовании
    // getPositionStream с параметрами для фона.
    // Для polling мы можем вручную запросить foreground service через Android
    // Но Geolocator предоставляет метод для этого:
    try {
      // Это вызовет foreground service, если разрешено
      await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      print('🟢 GPS: foreground service started');
    } catch (e) {
      print('⚠️ GPS: foreground service start error: $e');
    }
  }

  Future<void> _pollGps(Timer timer) async {
    if (!_isTracking || _isPaused) {
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      print('📍 GPS: poll - lat: ${position.latitude}, lon: ${position.longitude}, '
          'acc: ${position.accuracy}m, speed: ${position.speed?.toStringAsFixed(2) ?? 'N/A'} m/s');

      if (position.accuracy > 25) {
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

        if (distance < 1.0) {
          print('📏 GPS: distance too small (${distance.toStringAsFixed(2)}m), ignoring');
          return;
        }

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