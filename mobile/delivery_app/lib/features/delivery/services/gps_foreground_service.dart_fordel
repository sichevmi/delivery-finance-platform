// gps_foreground_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class GpsForegroundService {
  static bool _isRunning = false;
  static final StreamController<double> _distanceController = StreamController<double>.broadcast();
  static Stream<double> get distanceStream => _distanceController.stream;

  static double _totalDistance = 0.0;
  static Position? _lastPosition;
  static bool _isPaused = false;

  static const double _maxAccuracy = 30.0;
  static const double _minDistance = 0.5;
  static const double _maxJump = 100.0;

  static bool get isRunning => _isRunning;

  static void start({
    required String notificationTitle,
    required String notificationText,
  }) async {
    if (_isRunning) return;

    // Запрашиваем разрешения, если ещё нет
    final status = await Permission.locationAlways.status;
    if (!status.isGranted) {
      await Permission.locationAlways.request();
    }

    // Настройки уведомления
    final notification = NotificationDetails(
      id: 888,
      title: notificationTitle,
      text: notificationText,
      iconData: NotificationIcon.fromIconData(Icons.directions_car), // исправлено
      sound: null,
    );

    // Запускаем foreground-сервис
    await FlutterForegroundTask.startService(
      notification: notification,
      callback: _startCallback,
    );

    _isRunning = true;
    _resetDistance();
    _isPaused = false;
  }

  static void stop() {
    if (!_isRunning) return;
    FlutterForegroundTask.stopService();
    _isRunning = false;
    _distanceController.add(0.0);
  }

  static void pauseTracking() {
    _isPaused = true;
    // В TaskHandler мы обрабатываем паузу через флаг
  }

  static void resumeTracking() {
    _isPaused = false;
  }

  static void resetDistance() {
    _totalDistance = 0.0;
    _lastPosition = null;
    _distanceController.add(0.0);
  }

  static void forceRefresh() {
    // Можно отправить сигнал TaskHandler, но для простоты ничего не делаем
  }

  // ---- Внутренние методы для TaskHandler ----
  static void _onPositionUpdate(Position position) {
    if (_isPaused) return;

    // Фильтр точности
    if (position.accuracy > _maxAccuracy) return;

    if (_lastPosition == null) {
      _lastPosition = position;
      return;
    }

    double distance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      position.latitude,
      position.longitude,
    );

    if (distance < _minDistance) return;
    if (distance > _maxJump) return;

    _totalDistance += distance / 1000;
    _distanceController.add(_totalDistance);
    _lastPosition = position;
  }
}

// ---- TaskHandler (полноценная реализация) ----
@pragma('vm:entry-point')
void _startCallback() {
  FlutterForegroundTask.setTaskHandler(_GpsTaskHandler());
}

class _GpsTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _gpsSubscription;
  bool _isPaused = false;

  @override
  Future<void> onStart(DateTime timestamp) async {
    // Подписываемся на GPS
    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen((position) {
      // Передаём данные в статический метод
      GpsForegroundService._onPositionUpdate(position);
    }, onError: (error) {
      // Логируем ошибку
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Можно обновлять уведомление, если нужно
    // Например, показать текущую дистанцию
    // final distance = GpsForegroundService._totalDistance;
    // FlutterForegroundTask.updateService(
    //   notification: NotificationDetails(
    //     id: 888,
    //     title: 'Отслеживание маршрута',
    //     text: 'Пробег: ${distance.toStringAsFixed(2)} км',
    //     iconData: NotificationIcon.fromIconData(Icons.directions_car),
    //   ),
    // );
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _gpsSubscription?.cancel();
    _gpsSubscription = null;
  }

  @override
  void onNotificationPressed() {
    // Можно открыть приложение при нажатии на уведомление
  }
}