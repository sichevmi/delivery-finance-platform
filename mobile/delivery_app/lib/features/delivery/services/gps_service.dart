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

  // --- НАСТРОЙКИ (возврат к утренним, которые давали 80м погрешности) ---
  static const double _minSpeedMps = 0.5; // Восстановлен фильтр скорости
  static const double _maxAccuracy = 30.0; // 30м как было утром
  static const double _minDistance = 1.5; // 1.5м как было утром
  static const double _maxJump = 100.0; // 100м как было утром
  
  // Детектор "стояния"
  Position? _stationaryPosition;
  DateTime? _stationaryStartTime;

  // --- НОВОЕ: Детектор "залипания" GPS ---
  Position? _lastAcceptedPosition;
  int _stuckCounter = 0;
  static const int _stuckThreshold = 3; // 3 раза подряд одинаковые координаты

  static const int _pollInterval = 2;

  // --- Логирование ---
  bool _isLoggingEnabled = false;
  String _logBuffer = '';
  final int _maxLogSize = 500 * 1024;
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
    _log('🟢 GPS: startTracking() called (STUCK DETECTOR VERSION)');
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
    _lastAcceptedPosition = null;
    _stuckCounter = 0;

    _pollingTimer = Timer.periodic(
      Duration(seconds: _pollInterval),
      _pollGps,
    );
    _log('🟢 GPS: polling started every $_pollInterval second(s)');
  }

  Future<void> _pollGps(Timer timer) async {
    if (!_isTracking || _isPaused) {
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      _log('📍 GPS: lat: ${position.latitude}, lon: ${position.longitude}, '
          'acc: ${position.accuracy.toStringAsFixed(1)}m, speed: ${position.speed?.toStringAsFixed(2) ?? "N/A"} m/s');

      // ---- ФИЛЬТР 1: Точность ----
      if (position.accuracy > _maxAccuracy) {
        _log('⚠️ GPS: poor accuracy (${position.accuracy.toStringAsFixed(1)}m > ${_maxAccuracy}m), ignoring');
        // Сбрасываем счетчик залипания при плохой точности
        _stuckCounter = 0;
        return;
      }

      // ---- ФИЛЬТР 2: Скорость ----
      if (position.speed != null && position.speed! < _minSpeedMps) {
        _log('⏸️ GPS: speed too low (${position.speed!.toStringAsFixed(2)} m/s), ignoring');
        _stuckCounter = 0;
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

        // ---- НОВОЕ: Детектор залипания ----
        // Проверяем, не залипли ли мы на одной точке
        if (_lastAcceptedPosition != null) {
          final distFromLastAccepted = Geolocator.distanceBetween(
            _lastAcceptedPosition!.latitude,
            _lastAcceptedPosition!.longitude,
            position.latitude,
            position.longitude,
          );
          
          if (distFromLastAccepted < 0.5) {
            _stuckCounter++;
            _log('⚠️ GPS: stuck counter = $_stuckCounter/${_stuckThreshold}');
            
            if (_stuckCounter >= _stuckThreshold) {
              _log('🔄 GPS: DETECTED STUCK! Forcing refresh...');
              _stuckCounter = 0;
              // Принудительно обновляем позицию сбросом кеша
              await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.bestForNavigation,
                forceAndroidLocationManager: true,
              );
              return;
            }
          } else {
            _stuckCounter = 0;
          }
        }

        // ---- ФИЛЬТР 3: Минимальное расстояние ----
        if (distance < _minDistance) {
          _log('📏 GPS: distance too small (${distance.toStringAsFixed(2)}m < ${_minDistance}m), ignoring');
          return;
        }

        // ---- ФИЛЬТР 4: Максимальный скачок ----
        if (distance > _maxJump) {
          _log('⚠️ GPS: extreme jump > ${_maxJump}m (${distance.toStringAsFixed(2)}m), ignoring');
          _stuckCounter = 0;
          return;
        }

        // ---- ФИЛЬТР 5: Детектор "стояния" ----
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
          _stationaryPosition = null;
          _stationaryStartTime = null;
        }

        _log('✅ GPS: ACCEPTING ${distance.toStringAsFixed(2)}m');
        _totalDistance += distance / 1000;
        _log('📏 GPS: total: ${_totalDistance.toStringAsFixed(4)} km');
        _distanceStreamController.add(_totalDistance);
        
        // Запоминаем последнюю принятую позицию
        _lastAcceptedPosition = position;
        _stuckCounter = 0;
        
      } else {
        _log('🟢 GPS: first position, initializing');
        _lastAcceptedPosition = position;
        _stuckCounter = 0;
      }
      
      _lastPosition = position;

    } catch (e) {
      _log('🔴 GPS: poll error - $e');
      _stuckCounter = 0;
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
    _lastAcceptedPosition = null;
    _stuckCounter = 0;
    _distanceStreamController.add(0.0);
    if (_isLoggingEnabled) {
      _saveLogToFile();
    }
  }

  void forceRefresh() {
    _log('🔄 GPS: forceRefresh() called');
    _stuckCounter = 0;
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
    _lastAcceptedPosition = null;
    _stuckCounter = 0;
    _distanceStreamController.add(0.0);
  }
}