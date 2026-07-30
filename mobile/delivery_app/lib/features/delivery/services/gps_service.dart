// gps_service_speed.dart – Версия на основе скорости GPS
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
  Position? _lastPosition;
  DateTime? _lastTimestamp;
  bool _isPaused = false;

  // ---- Константы ----
  static const int _pollInterval = 2; // секунды
  static const double _minSpeed = 0.3;       // м/с – минимальная скорость для движения
  static const double _maxAccuracy = 30.0;   // метры – максимальная допустимая точность
  static const double _minDistanceIncrement = 0.5; // метры – минимальное приращение для учёта
  static const double _maxSpeed = 40.0;      // м/с – ограничение скорости (144 км/ч)

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
    _logBuffer += '=== GPS LOG STARTED (SPEED INTEGRATION) ===\n';
    _logBuffer += 'Timestamp: ${DateTime.now()}\n';
    _logBuffer += 'Poll interval: ${_pollInterval}s\n';
    _logBuffer += '========================\n\n';
    _log('📁 GPS logging started (SPEED)');
    await _saveLogToFile();
  }

  Future<void> stopLogging() async {
    if (!_isLoggingEnabled) return;
    _isLoggingEnabled = false;
    _log('📁 GPS logging stopped (SPEED)');
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
      final file = File('${directory.path}/gps_log_speed.txt');
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
    _log('🟢 GPS: startTracking() SPEED INTEGRATION');
    if (_isTracking) {
      _log('🟡 GPS: already tracking, ignoring');
      return;
    }

    _isTracking = true;
    _isPaused = false;
    _totalDistance = 0.0;
    _lastPosition = null;
    _lastTimestamp = null;

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

      // ---- Ограничение скорости ----
      final effectiveSpeed = speed.clamp(0.0, _maxSpeed);

      // ---- Вычисляем время с предыдущего опроса ----
      final now = DateTime.now();
      if (_lastTimestamp != null) {
        final dt = now.difference(_lastTimestamp!).inSeconds.toDouble();
        if (dt > 0.0 && dt < 10.0) {
          // Расстояние = скорость * время
          double distance = effectiveSpeed * dt;

          // ---- Минимальное приращение ----
          if (distance < _minDistanceIncrement) {
            _log('📏 GPS: distance too small (${distance.toStringAsFixed(2)}m < ${_minDistanceIncrement}m), ignoring');
            _lastTimestamp = now;
            return;
          }

          // ---- Ограничение максимального приращения ----
          if (distance > 100.0) {
            _log('⚠️ GPS: distance > 100m (${distance.toStringAsFixed(2)}m), limiting to 100m');
            distance = 100.0;
          }

          _totalDistance += distance / 1000;
          _log('✅ GPS: ACCEPTING ${distance.toStringAsFixed(2)}m (speed integration)');
          _log('📏 GPS: total: ${_totalDistance.toStringAsFixed(4)} km');
          _distanceStreamController.add(_totalDistance);
        } else {
          _log('⚠️ GPS: dt out of range (${dt}s), ignoring');
        }
      } else {
        _log('🟢 GPS: first position, initializing');
      }

      _lastPosition = position;
      _lastTimestamp = now;

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
    _lastPosition = null;
    _lastTimestamp = null;
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
    _lastPosition = null;
    _lastTimestamp = null;
    _distanceStreamController.add(0.0);
  }
}