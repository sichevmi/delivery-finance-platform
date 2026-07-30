// gps_service.dart – Стрим-версия (точный пробег по координатам)
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';

class GpsService {
  static final GpsService _instance = GpsService._internal();
  factory GpsService() => _instance;
  GpsService._internal();

  StreamSubscription<Position>? _positionSubscription;
  bool _isTracking = false;
  double _totalDistance = 0.0;
  Position? _lastPosition;
  bool _isPaused = false;

  // ---- Константы фильтрации ----
  static const double _maxAccuracy = 30.0;      // метры – максимальная допустимая точность
  static const double _minDistance = 1.0;       // метры – минимальное перемещение для учёта
  static const double _maxJump = 100.0;         // метры – защита от выбросов
  static const double _minSpeed = 0.2;          // м/с – минимальная скорость (для отсечения стоячего шума)
  static const bool _useSmoothing = false;      // можно включить EMA (пока отключено)

  // ---- EMA (если включено) ----
  double _emaAlpha = 0.5;
  Position? _smoothedPosition;

  // ---- Логирование ----
  bool _isLoggingEnabled = false;
  String _logBuffer = '';
  final int _maxLogSize = 500 * 1024; // 500 KB
  File? _logFile;

  double get currentDistance => _totalDistance;

  final _distanceStreamController = StreamController<double>.broadcast();
  Stream<double> get distanceStream => _distanceStreamController.stream;

  // ---- Управление логированием ----
  Future<void> startLogging() async {
    if (_isLoggingEnabled) return;
    _isLoggingEnabled = true;
    _logBuffer = '';
    _logBuffer += '=== GPS LOG STARTED (STREAM VERSION) ===\n';
    _logBuffer += 'Timestamp: ${DateTime.now()}\n';
    _logBuffer += 'Min distance: ${_minDistance}m\n';
    _logBuffer += 'Max accuracy: ${_maxAccuracy}m\n';
    _logBuffer += '========================\n\n';
    _log('📁 GPS logging started (STREAM)');
    await _saveLogToFile();
  }

  Future<void> stopLogging() async {
    if (!_isLoggingEnabled) return;
    _isLoggingEnabled = false;
    _log('📁 GPS logging stopped (STREAM)');
    await _saveLogToFile();
  }

  void _log(String message) {
    if (!_isLoggingEnabled) return;
    final timestamp = DateTime.now().toIso8601String();
    _logBuffer += '[$timestamp] $message\n';
    print(message);
  }

  Future<void> _saveLogToFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/gps_log_stream.txt');
      _logFile = file;
      await file.writeAsString(_logBuffer);
      _log('📁 Log saved to: ${file.path}');
    } catch (e) {
      print('❌ Failed to save log: $e');
    }
  }

  Future<String?> getLogFilePath() async {
    if (_logFile == null) return null;
    return _logFile!.path;
  }

  Future<String> readLogFile() async {
    if (_logFile == null) return 'Log file not found';
    try {
      return await _logFile!.readAsString();
    } catch (e) {
      return 'Error reading log: $e';
    }
  }

  // ---- Основные методы ----
  void startTracking() {
    _log('🟢 GPS: startTracking() STREAM');
    if (_isTracking) {
      _log('🟡 GPS: already tracking, ignoring');
      return;
    }

    _isTracking = true;
    _isPaused = false;
    _totalDistance = 0.0;
    _lastPosition = null;
    _smoothedPosition = null;

    // Настройки геолокации
    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0, // получаем все обновления
      intervalDuration: Duration(seconds: 1),
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (Position position) {
        _onPositionUpdate(position);
      },
      onError: (error) {
        _log('🔴 GPS stream error: $error');
      },
      cancelOnError: false,
    );

    _log('🟢 GPS: stream started');
  }

  void _onPositionUpdate(Position position) {
    if (!_isTracking || _isPaused) {
      _log('⏸️ GPS: update skipped (paused/stopped)');
      return;
    }

    _log('📍 GPS: position - lat: ${position.latitude}, lon: ${position.longitude}, '
        'acc: ${position.accuracy}m, speed: ${position.speed?.toStringAsFixed(2) ?? "N/A"} m/s');

    // ---- ФИЛЬТР 1: Точность ----
    if (position.accuracy > _maxAccuracy) {
      _log('⚠️ GPS: poor accuracy (${position.accuracy}m > ${_maxAccuracy}m), ignoring');
      return;
    }

    // ---- ФИЛЬТР 2: Скорость (только для отсечения стоячего шума) ----
    final speed = position.speed ?? 0.0;
    if (speed < _minSpeed) {
      _log('⏸️ GPS: speed too low (${speed.toStringAsFixed(2)} m/s), ignoring');
      return;
    }

    // ---- Первая позиция ----
    if (_lastPosition == null) {
      _lastPosition = position;
      if (_useSmoothing) _smoothedPosition = position;
      _log('🟢 GPS: first position stored');
      return;
    }

    // ---- Вычисляем расстояние между текущей и предыдущей позицией ----
    double distance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      position.latitude,
      position.longitude,
    );
    _log('📏 GPS: raw distance: ${distance.toStringAsFixed(2)}m');

    // ---- ФИЛЬТР 3: Минимальное расстояние ----
    if (distance < _minDistance) {
      _log('📏 GPS: distance too small (${distance.toStringAsFixed(2)}m < ${_minDistance}m), ignoring');
      return;
    }

    // ---- ФИЛЬТР 4: Максимальный скачок ----
    if (distance > _maxJump) {
      _log('⚠️ GPS: extreme jump > ${_maxJump}m (${distance.toStringAsFixed(2)}m), ignoring');
      return;
    }

    // ---- Опциональное EMA-сглаживание (по умолчанию выключено) ----
    double finalDistance = distance;
    if (_useSmoothing && _smoothedPosition != null) {
      final double smoothedLat = _emaAlpha * position.latitude + (1 - _emaAlpha) * _smoothedPosition!.latitude;
      final double smoothedLon = _emaAlpha * position.longitude + (1 - _emaAlpha) * _smoothedPosition!.longitude;
      final smoothedPos = Position(
        latitude: smoothedLat,
        longitude: smoothedLon,
        timestamp: position.timestamp,
        accuracy: position.accuracy,
        altitude: position.altitude,
        heading: position.heading,
        speed: position.speed,
        speedAccuracy: position.speedAccuracy,
        altitudeAccuracy: position.altitudeAccuracy,
        headingAccuracy: position.headingAccuracy,
      );
      final smoothedDist = Geolocator.distanceBetween(
        _smoothedPosition!.latitude,
        _smoothedPosition!.longitude,
        smoothedPos.latitude,
        smoothedPos.longitude,
      );
      if (smoothedDist > 0.01) {
        finalDistance = smoothedDist;
        _smoothedPosition = smoothedPos;
      } else {
        _log('📏 GPS: smoothed distance too small (${smoothedDist.toStringAsFixed(2)}m), using raw');
      }
    } else {
      // Если сглаживание выключено, обновляем lastPosition
      _lastPosition = position;
    }

    // ---- Добавляем расстояние ----
    if (finalDistance > 0.01) {
      _totalDistance += finalDistance / 1000;
      _log('✅ GPS: ACCEPTING ${finalDistance.toStringAsFixed(2)}m');
      _log('📏 GPS: total: ${_totalDistance.toStringAsFixed(4)} km');
      _distanceStreamController.add(_totalDistance);
    } else {
      _log('📏 GPS: final distance too small (${finalDistance.toStringAsFixed(2)}m), ignoring');
    }

    // ---- Обновляем lastPosition (если не использовали EMA) ----
    if (!_useSmoothing) {
      _lastPosition = position;
    } else {
      // При EMA мы уже обновили _smoothedPosition, но lastPosition оставляем исходным для следующих итераций?
      // Лучше хранить lastPosition как сырую, а smoothed – отдельно.
      // В этом коде мы не трогаем _lastPosition при EMA, но для простоты оставим как есть.
      // Для корректности: при EMA _lastPosition должен оставаться сырым, а _smoothedPosition – сглаженным.
      // В текущей реализации _lastPosition используется только для расчёта сырого расстояния, что нам и нужно.
      // После расчёта мы обновляем _lastPosition на сырую позицию (чтобы следующий шаг считал сырое расстояние от новой сырой точки).
      _lastPosition = position;
    }

    // ---- Ротация лога ----
    if (_isLoggingEnabled && _logBuffer.length > _maxLogSize) {
      _saveLogToFile();
      _logBuffer = _logBuffer.substring(_logBuffer.length ~/ 2);
    }
  }

  // ---- Остальные методы ----
  void pauseTracking() {
    _log('⏸️ GPS: pauseTracking()');
    _isPaused = true;
  }

  void resumeTracking() {
    _log('▶️ GPS: resumeTracking()');
    _isPaused = false;
  }

  void stopTracking() {
    _log('🛑 GPS: stopTracking()');
    _isTracking = false;
    _isPaused = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _lastPosition = null;
    _smoothedPosition = null;
    _distanceStreamController.add(0.0);
    if (_isLoggingEnabled) {
      _saveLogToFile();
    }
  }

  // forceRefresh не нужен для стрима, но оставим как заглушку
  void forceRefresh() {
    _log('🔄 GPS: forceRefresh() called (no-op for stream)');
  }

  double getTotalDistance() => _totalDistance;

  void resetDistance() {
    _log('🔄 GPS: resetDistance()');
    _totalDistance = 0.0;
    _lastPosition = null;
    _smoothedPosition = null;
    _distanceStreamController.add(0.0);
  }
}