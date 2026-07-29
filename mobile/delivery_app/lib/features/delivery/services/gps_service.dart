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
  bool _isPaused = false;

  // --- НАСТРОЙКИ ФИЛЬТРОВ ---
  // Минимальная скорость (м/с) для засчёта движения. Отсекает дрейф при стоянии.
  static const double _minSpeedMps = 0.5; // ~1.8 км/ч
  // Максимальная допустимая точность GPS (метров).
  static const double _maxAccuracy = 20.0;
  // Минимальное расстояние (метров) для засчёта перемещения.
  static const double _minDistance = 1.5;
  // Максимальный скачок (метров) за один опрос. Отсекает выбросы.
  static const double _maxJump = 100.0;

  // Детектор "стояния": запоминаем позицию и время, если перемещения очень маленькие.
  Position? _stationaryPosition;
  DateTime? _stationaryStartTime;

  static const int _pollInterval = 2; // Опрос каждые 2 секунды

  // --- Логирование ---
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
    _logBuffer += '=== GPS LOG STARTED ===\n';
    _logBuffer += 'Timestamp: ${DateTime.now()}\n';
    _logBuffer += 'Poll interval: ${_pollInterval}s\n';
    _logBuffer += '========================\n\n';
    _log('📁 GPS logging started');
    await _saveLogToFile();
  }

  Future<void> stopLogging() async {
    if (!_isLoggingEnabled) return;
    _isLoggingEnabled = false;
    _log('📁 GPS logging stopped');
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
      final file = File('${directory.path}/gps_log.txt');
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
    _log('🟢 GPS: startTracking() called (FINAL IMPROVED VERSION)');
    if (_isTracking) {
      _log('🟡 GPS: already tracking, ignoring');
      return;
    }

    _isTracking = true;
    _isPaused = false;
    _totalDistance = 0.0;
    _lastPosition = null;
    _stationaryPosition = null;
    _stationaryStartTime = null;

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
      // Игнорируем, если скорость меньше минимальной (стоим на месте)
      if (position.speed != null && position.speed! < _minSpeedMps) {
        _log('⏸️ GPS: speed too low (${position.speed!.toStringAsFixed(2)} m/s), ignoring');
        return;
      }

      if (_lastPosition != null) {
        final distance = Geolocator.distanceBetween(
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

        // ---- ФИЛЬТР 5: Детектор "стояния" ----
        // Если перемещение меньше 3 метров, запоминаем позицию как "стояние".
        // Если стоим дольше 30 секунд, то игнорируем любые перемещения < 3 метров.
        if (distance < 3.0) {
          if (_stationaryPosition == null) {
            _stationaryPosition = position;
            _stationaryStartTime = DateTime.now();
          } else {
            final stationaryDist = Geolocator.distanceBetween(
              _stationaryPosition!.latitude,
              _stationaryPosition!.longitude,
              position.latitude,
              position.longitude,
            );
            if (stationaryDist < 3.0 &&
                _stationaryStartTime != null &&
                DateTime.now().difference(_stationaryStartTime!).inSeconds > 30) {
              _log('⏸️ GPS: stationary for >30s, ignoring small movement');
              return;
            }
          }
        } else {
          // Если сдвинулись > 3 метров — сбрасываем "стояние"
          _stationaryPosition = null;
          _stationaryStartTime = null;
        }

        _log('✅ GPS: ACCEPTING ${distance.toStringAsFixed(2)}m');
        _totalDistance += distance / 1000;
        _log('📏 GPS: total: ${_totalDistance.toStringAsFixed(4)} km');
        _distanceStreamController.add(_totalDistance);
      } else {
        _log('🟢 GPS: first position, initializing');
      }
      _lastPosition = position;

    } catch (e, stack) {
      _log('🔴 GPS: poll error - $e');
    }

    if (_isLoggingEnabled && _logBuffer.length > _maxLogSize) {
      await _saveLogToFile();
      _logBuffer = _logBuffer.substring(_logBuffer.length ~/ 2);
    }
  }

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
    _stationaryPosition = null;
    _stationaryStartTime = null;
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
    _stationaryPosition = null;
    _stationaryStartTime = null;
    _distanceStreamController.add(0.0);
  }
}