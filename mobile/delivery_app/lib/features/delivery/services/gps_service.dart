// gps_service_hybrid.dart – Координатный метод с EMA-сглаживанием
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';

class GpsService {
  static final GpsService _instance = GpsService._internal();
  factory GpsService() => _instance;
  GpsService._internal();

  Timer? _pollingTimer;
  bool _isTracking = false;
  double _totalDistance = 0.0;
  Position? _lastRawPosition;          // последняя сырая позиция (для фильтров)
  Position? _smoothedPosition;          // сглаженная позиция (EMA)
  bool _isPaused = false;

  // ---- Константы ----
  static const int _pollInterval = 2;          // секунды
  static const double _minSpeed = 0.3;         // м/с – минимальная скорость для движения
  static const double _maxAccuracy = 30.0;     // метры – максимальная допустимая точность
  static const double _minDistance = 0.5;      // метры – игнорируем очень маленькие перемещения
  static const double _maxJump = 100.0;        // метры – защита от выбросов
  static const double _emaAlpha = 0.6;         // коэффициент сглаживания (0..1), больше – быстрее реагируем

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
    _logBuffer += '=== GPS LOG STARTED (HYBRID EMA COORD) ===\n';
    _logBuffer += 'Timestamp: ${DateTime.now()}\n';
    _logBuffer += 'Poll interval: ${_pollInterval}s\n';
    _logBuffer += 'EMA alpha: $_emaAlpha\n';
    _logBuffer += '========================\n\n';
    _log('📁 GPS logging started (HYBRID)');
    await _saveLogToFile();
  }

  Future<void> stopLogging() async {
    if (!_isLoggingEnabled) return;
    _isLoggingEnabled = false;
    _log('📁 GPS logging stopped (HYBRID)');
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
      final file = File('${directory.path}/gps_log_hybrid.txt');
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
    _log('🟢 GPS: startTracking() HYBRID EMA');
    if (_isTracking) {
      _log('🟡 GPS: already tracking, ignoring');
      return;
    }

    _isTracking = true;
    _isPaused = false;
    _totalDistance = 0.0;
    _lastRawPosition = null;
    _smoothedPosition = null;

    _pollingTimer = Timer.periodic(
      Duration(seconds: _pollInterval),
      _pollGps,
    );
    _log('🟢 GPS: polling started every $_pollInterval second(s)');
  }

  Future<void> _pollGps(Timer timer) async {
    if (!_isTracking || _isPaused) {
      _log('⏸️ GPS: polling skipped');
      return;
    }

    _log('📍 GPS: polling...');
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      _log('📍 GPS: position - lat: ${position.latitude}, lon: ${position.longitude}, '
          'acc: ${position.accuracy}m, speed: ${position.speed?.toStringAsFixed(2) ?? "N/A"} m/s');

      // ---- ФИЛЬТР 1: Точность ----
      if (position.accuracy > _maxAccuracy) {
        _log('⚠️ GPS: poor accuracy (${position.accuracy}m > ${_maxAccuracy}m), ignoring');
        return;
      }

      // ---- ФИЛЬТР 2: Скорость ----
      final speed = position.speed ?? 0.0;
      if (speed < _minSpeed) {
        _log('⏸️ GPS: speed too low (${speed.toStringAsFixed(2)} m/s), ignoring');
        return;
      }

      // ---- Сохраняем сырую позицию для фильтров (выбросы) ----
      _lastRawPosition = position;

      // ---- Обновляем сглаженную позицию (EMA) ----
      if (_smoothedPosition == null) {
        // Первая точка – просто берём её
        _smoothedPosition = position;
        _log('🟢 GPS: first smoothed position set');
        return;
      }

      // Вычисляем сырое расстояние между сырыми координатами (для проверки выбросов)
      final rawDistance = Geolocator.distanceBetween(
        _lastRawPosition!.latitude,
        _lastRawPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      _log('📏 GPS: raw distance between raw points: ${rawDistance.toStringAsFixed(2)}m');

      // ---- ФИЛЬТР 3: Минимальное расстояние (сырое) ----
      if (rawDistance < _minDistance) {
        _log('📏 GPS: raw distance too small (${rawDistance.toStringAsFixed(2)}m < ${_minDistance}m), ignoring');
        return;
      }

      // ---- ФИЛЬТР 4: Максимальный скачок (защита от выбросов) ----
      if (rawDistance > _maxJump) {
        _log('⚠️ GPS: extreme jump > ${_maxJump}m (${rawDistance.toStringAsFixed(2)}m), ignoring');
        return;
      }

      // ---- Применяем EMA к координатам ----
      final double smoothedLat = _emaAlpha * position.latitude + (1 - _emaAlpha) * _smoothedPosition!.latitude;
      final double smoothedLon = _emaAlpha * position.longitude + (1 - _emaAlpha) * _smoothedPosition!.longitude;

      // Создаём новую сглаженную позицию (копируем остальные поля из сырой)
      final newSmoothed = Position(
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

      // ---- Считаем расстояние между сглаженными позициями ----
      final smoothedDistance = Geolocator.distanceBetween(
        _smoothedPosition!.latitude,
        _smoothedPosition!.longitude,
        newSmoothed.latitude,
        newSmoothed.longitude,
      );
      _log('📏 GPS: smoothed distance: ${smoothedDistance.toStringAsFixed(2)}m');

      // ---- Принимаем это расстояние ----
      if (smoothedDistance > 0.01) {
        _totalDistance += smoothedDistance / 1000;
        _log('✅ GPS: ACCEPTING ${smoothedDistance.toStringAsFixed(2)}m (smoothed)');
        _log('📏 GPS: total: ${_totalDistance.toStringAsFixed(4)} km');
        _distanceStreamController.add(_totalDistance);
      } else {
        _log('📏 GPS: smoothed distance too small (${smoothedDistance.toStringAsFixed(2)}m), ignoring');
      }

      // Обновляем сглаженную позицию
      _smoothedPosition = newSmoothed;

    } catch (e, stack) {
      _log('🔴 GPS: poll error - $e');
    }

    if (_isLoggingEnabled && _logBuffer.length > _maxLogSize) {
      await _saveLogToFile();
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
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _lastRawPosition = null;
    _smoothedPosition = null;
    _distanceStreamController.add(0.0);
    if (_isLoggingEnabled) {
      _saveLogToFile();
    }
  }

  void forceRefresh() {
    _log('🔄 GPS: forceRefresh() called');
    if (_isTracking && !_isPaused) {
      _pollGps(Timer.periodic(Duration(seconds: 1), (timer) {}));
    }
  }

  double getTotalDistance() => _totalDistance;

  void resetDistance() {
    _log('🔄 GPS: resetDistance()');
    _totalDistance = 0.0;
    _lastRawPosition = null;
    _smoothedPosition = null;
    _distanceStreamController.add(0.0);
  }
}