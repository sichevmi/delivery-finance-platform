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

  // Kalman filter parameters - БЫСТРАЯ АДАПТАЦИЯ
  double _q = 0.5;   // Увеличено! Доверяем движению больше
  double _r = 5.0;   // Уменьшено! Меньше шума
  double _p = 1.0;
  double _k = 0.0;
  double _x = 0.0;

  static const double _maxAccuracy = 50.0;
  static const int _pollInterval = 2;

  bool _isLoggingEnabled = false;
  String _logBuffer = '';
  final int _maxLogSize = 500 * 1024;
  File? _logFile;

  double get currentDistance => _totalDistance;

  final _distanceStreamController = StreamController<double>.broadcast();
  Stream<double> get distanceStream => _distanceStreamController.stream;

  Future<void> startLogging() async {
    if (_isLoggingEnabled) return;
    _isLoggingEnabled = true;
    _logBuffer = '';
    _logBuffer += '=== GPS LOG STARTED (VERSION 2.1 - FAST KALMAN) ===\n';
    _logBuffer += 'Timestamp: ${DateTime.now()}\n';
    _logBuffer += 'q=$_q, r=$_r\n';
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

  double _kalmanFilter(double measurement) {
    // Prediction
    _p = _p + _q;
    
    // Update
    _k = _p / (_p + _r);
    _x = _x + _k * (measurement - _x);
    _p = (1 - _k) * _p;
    
    return _x;
  }

  void startTracking() {
    _log('🟢 GPS: startTracking() V2.1 - FAST KALMAN');
    if (_isTracking) {
      _log('🟡 GPS: already tracking, ignoring');
      return;
    }

    _isTracking = true;
    _isPaused = false;
    _totalDistance = 0.0;
    _lastPosition = null;
    _x = 0.0;
    _p = 1.0;

    _pollingTimer = Timer.periodic(
      Duration(seconds: _pollInterval),
      _pollGps,
    );
    _log('🟢 GPS: polling started every $_pollInterval second(s)');
  }

  Future<void> _pollGps(Timer timer) async {
    if (!_isTracking || _isPaused) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      _log('📍 GPS: lat: ${position.latitude}, lon: ${position.longitude}, '
          'acc: ${position.accuracy.toStringAsFixed(1)}m, speed: ${position.speed?.toStringAsFixed(2) ?? "N/A"} m/s');

      if (position.accuracy > _maxAccuracy) {
        _log('⚠️ GPS: poor accuracy (${position.accuracy.toStringAsFixed(1)}m > ${_maxAccuracy}m), ignoring');
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

        // Kalman filter с быстрой адаптацией
        double filteredDistance = _kalmanFilter(distance);
        _log('📏 GPS: filtered distance: ${filteredDistance.toStringAsFixed(2)}m (k=${_k.toStringAsFixed(3)})');

        // Убираем слишком маленький порог
        if (filteredDistance > 0.3) {
          _totalDistance += filteredDistance / 1000;
          _log('✅ GPS: ACCEPTING ${filteredDistance.toStringAsFixed(2)}m, total: ${_totalDistance.toStringAsFixed(4)} km');
          _distanceStreamController.add(_totalDistance);
        } else {
          _log('📏 GPS: filtered distance too small (${filteredDistance.toStringAsFixed(2)}m), ignoring');
        }
      } else {
        _log('🟢 GPS: first position, initializing');
      }
      
      _lastPosition = position;

    } catch (e) {
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
    _distanceStreamController.add(0.0);
    if (_isLoggingEnabled) {
      _saveLogToFile();
    }
  }

  void forceRefresh() {
    _log('🔄 GPS: forceRefresh() called');
    // Сбрасываем Kalman при принудительном обновлении
    _x = 0.0;
    _p = 1.0;
    if (_isTracking && !_isPaused) {
      _pollGps(Timer.periodic(Duration(seconds: 1), (timer) {}));
    }
  }

  double getTotalDistance() => _totalDistance;

  void resetDistance() {
    _log('🔄 GPS: resetDistance()');
    _totalDistance = 0.0;
    _lastPosition = null;
    _x = 0.0;
    _p = 1.0;
    _distanceStreamController.add(0.0);
  }
}