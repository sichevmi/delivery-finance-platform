import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'logger_service.dart';

class GpsService {
  static final GpsService _instance = GpsService._internal();
  factory GpsService() => _instance;
  GpsService._internal();

  bool _isTracking = false;
  double _totalDistance = 0.0;
  Position? _lastPosition;
  bool _isPaused = false;
  bool _isInitialized = false;

  static const int _pollInterval = 1;

  double get currentDistance => _totalDistance;

  final _distanceStreamController = StreamController<double>.broadcast();
  Stream<double> get distanceStream => _distanceStreamController.stream;

  Future<void> initLogger() async {
    if (!_isInitialized) {
      await LoggerService().init();
      _isInitialized = true;
      await LoggerService().logEvent('GPS_SERVICE_INIT');
    }
  }

  void startTracking() {
    LoggerService().logEvent('START_TRACKING', data: {
      'isTracking': _isTracking,
      'isPaused': _isPaused,
      'totalDistance': _totalDistance,
    });

    if (_isTracking) {
      LoggerService().log('🟡 GPS: already tracking, ignoring');
      return;
    }

    _isTracking = true;
    _isPaused = false;
    _totalDistance = 0.0;
    _lastPosition = null;

    LoggerService().log('🟢 GPS: tracking started');

    // Запускаем Foreground Service
    _startForegroundService();
  }

  void _startForegroundService() {
    FlutterForegroundTask.startService(
      notificationTitle: 'FinFlow Доставка',
      notificationText: 'Отслеживание маршрута...',
      callback: _foregroundCallback,
    );
    LoggerService().log('🟢 Foreground Service started');
  }

  @pragma('vm:entry-point')
  static void _foregroundCallback() {
    FlutterForegroundTask.setTaskHandler(_GpsForegroundHandler());
  }

  void pauseTracking() {
    LoggerService().logEvent('PAUSE_TRACKING', data: {
      'totalDistance': _totalDistance,
    });
    _isPaused = true;
  }

  void resumeTracking() {
    LoggerService().logEvent('RESUME_TRACKING', data: {
      'totalDistance': _totalDistance,
    });
    _isPaused = false;
  }

  void stopTracking() {
    LoggerService().logEvent('STOP_TRACKING', data: {
      'totalDistance': _totalDistance,
      'lastPosition': _lastPosition?.latitude.toString() ?? 'null',
    });
    _isTracking = false;
    _isPaused = false;
    _lastPosition = null;
    _distanceStreamController.add(0.0);
    LoggerService().close();

    // Останавливаем Foreground Service
    FlutterForegroundTask.stopService();
    LoggerService().log('🛑 Foreground Service stopped');
  }

  void forceRefresh() {
    LoggerService().logEvent('FORCE_REFRESH', data: {
      'isTracking': _isTracking,
      'isPaused': _isPaused,
    });
  }

  double getTotalDistance() => _totalDistance;

  void resetDistance() {
    LoggerService().logEvent('RESET_DISTANCE', data: {
      'oldDistance': _totalDistance,
    });
    _totalDistance = 0.0;
    _lastPosition = null;
    _distanceStreamController.add(0.0);
  }

  Future<String?> getLog() async {
    return await LoggerService().readLog();
  }

  Future<String?> getLogPath() async {
    return await LoggerService().getLogFilePath();
  }

  // Метод для обновления расстояния из фонового сервиса
  void updateDistance(double distance) {
    _totalDistance = distance;
    _distanceStreamController.add(_totalDistance);
  }
}

// ---- Foreground Handler ----
class _GpsForegroundHandler extends TaskHandler {
  double _totalDistance = 0.0;
  Position? _lastPosition;
  bool _isPaused = false;
  Timer? _pollingTimer;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('🟢 Foreground: onStart');
    _startPolling();
    FlutterForegroundTask.updateService(
      notificationTitle: 'FinFlow Доставка',
      notificationText: 'Отслеживание маршрута...',
    );
  }

  @override
  Future<void> onEvent(DateTime timestamp, TaskStarter starter) async {
    // Обновляем уведомление каждые 5 секунд
    if (_pollingTimer == null || !_pollingTimer!.isActive) {
      _startPolling();
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, TaskStarter starter) async {
    print('🛑 Foreground: onDestroy');
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void onButtonPressed(String id) {
    // Обработка нажатия на кнопку в уведомлении
    print('🔘 Foreground: button pressed - $id');
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (_isPaused) return;

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
        );

        if (_lastPosition != null) {
          final distance = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );

          if (distance > 1.0 && distance < 500) {
            _totalDistance += distance / 1000;
            LoggerService().log('📏 Foreground: +${distance.toStringAsFixed(2)}m, total: ${_totalDistance.toStringAsFixed(4)}km');

            // Обновляем уведомление с текущим расстоянием
            FlutterForegroundTask.updateService(
              notificationTitle: 'FinFlow Доставка',
              notificationText: '${_totalDistance.toStringAsFixed(2)} км',
            );

            // Передаём расстояние в основное приложение
            final gpsService = GpsService();
            gpsService.updateDistance(_totalDistance);
          }
        }
        _lastPosition = position;

      } catch (e) {
        print('⚠️ Foreground GPS error: $e');
      }
    });
  }
}