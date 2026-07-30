// lib/features/delivery/services/GpsForegroundService.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

class GpsForegroundService {
  static final GpsForegroundService _instance = GpsForegroundService._internal();
  factory GpsForegroundService() => _instance;
  GpsForegroundService._internal();

  bool _isRunning = false;
  StreamSubscription<Position>? _positionSubscription;
  double _totalDistance = 0.0;
  Position? _lastPosition;

  // Параметры фильтрации (те же, что в GpsService)
  static const double _maxAccuracy = 30.0;
  static const double _minDistance = 0.5;
  static const double _maxJump = 100.0;

  // Стрим для отправки обновлений в UI
  final _distanceStreamController = StreamController<double>.broadcast();
  Stream<double> get distanceStream => _distanceStreamController.stream;

  Future<void> startTracking() async {
    if (_isRunning) return;

    // Запрашиваем разрешения для фоновой работы
    final locationPermission = await Geolocator.checkPermission();
    if (locationPermission != LocationPermission.always) {
      // Если нет "always", запрашиваем
      final newPermission = await Geolocator.requestPermission();
      if (newPermission != LocationPermission.always) {
        throw Exception('Разрешение "Всегда" не получено');
      }
    }

    // Проверяем, включена ли геолокация
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('GPS выключен');
    }

    // Запускаем foreground service через flutter_foreground_task
    // (библиотека flutter_foreground_task упрощает эту задачу)
    // Но можно и через MethodChannel, но я покажу простой вариант через плагин.

    // Для простоты я предлагаю использовать готовый плагин flutter_foreground_task.
    // Добавьте в pubspec.yaml: flutter_foreground_task: ^8.0.0

    // Запускаем сервис
    await FlutterForegroundTask.startService(
      notificationTitle: 'Отслеживание поездки',
      notificationText: 'Идёт подсчёт пробега...',
      notificationIcon: Icons.directions_car,
      callback: _startForegroundTask,
    );

    _isRunning = true;
  }

  // Эта функция будет выполняться в фоновом изоляте
  @pragma('vm:entry-point')
  static void _startForegroundTask() {
    FlutterForegroundTask.setTaskHandler(_GpsTaskHandler());
  }

  Future<void> stopTracking() async {
    if (!_isRunning) return;
    await FlutterForegroundTask.stopService();
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _isRunning = false;
    _totalDistance = 0.0;
    _lastPosition = null;
    _distanceStreamController.add(0.0);
  }

  double getTotalDistance() => _totalDistance;

  void resetDistance() {
    _totalDistance = 0.0;
    _lastPosition = null;
    _distanceStreamController.add(0.0);
  }
}

// Обработчик фоновой задачи
class _GpsTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionSubscription;
  double _totalDistance = 0.0;
  Position? _lastPosition;

  @override
  void onStart(DateTime timestamp, TaskStarter starter) {
    super.onStart(timestamp, starter);

    // Запускаем подписку на GPS
    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (Position position) {
        _onPositionUpdate(position);
      },
      onError: (error) {
        print('GPS error in foreground: $error');
      },
    );

    // Обновляем уведомление каждые 5 секунд
    Timer.periodic(Duration(seconds: 5), (timer) {
      FlutterForegroundTask.updateService(
        notificationTitle: 'Пробег: ${_totalDistance.toStringAsFixed(2)} км',
        notificationText: 'Отслеживание продолжается...',
      );
    });
  }

  void _onPositionUpdate(Position position) {
    // Те же фильтры, что и в GpsService
    if (position.accuracy > 30.0) return;

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

    if (distance < 0.5 || distance > 100.0) return;

    _totalDistance += distance / 1000;
    _lastPosition = position;

    // Можно сохранять в SharedPreferences для восстановления после перезапуска
  }

  @override
  void onDestroy(DateTime timestamp, TaskStarter starter) {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    super.onDestroy(timestamp, starter);
  }

  @override
  void onEvent(DateTime timestamp, TaskStarter starter, dynamic event) {
    // Обработка событий из UI
  }
}