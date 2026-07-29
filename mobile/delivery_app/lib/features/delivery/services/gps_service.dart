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

  // АДАПТИВНЫЕ НАСТРОЙКИ
  static const double _maxAccuracy = 40.0;
  static const double _minDistance = 1.5;
  static const int _pollInterval = 2;
  
  // Буфер последних позиций для анализа
  List<Position> _recentPositions = [];
  static const int _bufferSize = 5;

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
    _logBuffer += '=== GPS LOG STARTED (VERSION 3 - SMART) ===\n';
    _logBuffer += 'Timestamp: ${DateTime.now()}\n';
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

  // Проверка на "реалистичность" перемещения
  bool _isRealisticMovement(Position current, Position previous) {
    double distance = Geolocator.distanceBetween(
      previous.latitude, previous.longitude,
      current.latitude, current.longitude,
    );
    
    double timeDelta = (current.timestamp.millisecondsSinceEpoch - 
                       previous.timestamp.millisecondsSinceEpoch) / 1000.0;
    
    if (timeDelta == 0) return false;
    
    double speed = distance / timeDelta;
    
    // Слишком быстро (>30 м/с) — явный выброс
    if (speed > 30.0) {
      _log('⚠️ GPS: unrealistic speed ${speed.toStringAsFixed(1)} m/s, ignoring');
      return false;
    }
    
    // Если расстояние меньше чем точность * 1.5 — скорее всего шум
    if (current.accuracy > 0 && distance < current.accuracy * 1.5) {
      _log('⚠️ GPS: distance ($distance) < accuracy * 1.5, likely noise');
      return false;
    }
    
    return true;
  }

  // Получение "усреднённой" позиции из буфера
  Position? _getSmoothedPosition() {
    if (_recentPositions.length < 3) return null;
    
    double avgLat = 0.0;
    double avgLon = 0.0;
    double avgAcc = 0.0;
    
    for (var pos in _recentPositions) {
      avgLat += pos.latitude;
      avgLon += pos.longitude;
      avgAcc += pos.accuracy;
    }
    
    avgLat /= _recentPositions.length;
    avgLon /= _recentPositions.length;
    avgAcc /= _recentPositions.length;
    
    // Используем последнюю позицию как основу
    Position last = _recentPositions.last;
    return Position(
      latitude: avgLat,
      longitude: avgLon,
      timestamp: last.timestamp,
      accuracy: avgAcc,
      altitude: last.altitude,
      heading: last.heading,
      speed: last.speed,
      speedAccuracy: last.speedAccuracy,
      altitudeAccuracy: last.altitudeAccuracy,  // <-- Добавлено
      headingAccuracy: last.headingAccuracy,    // <-- Добавлено
    );
  }

  void startTracking() {
    _log('🟢 GPS: startTracking() V3 - SMART');
    if (_isTracking) {
      _log('🟡 GPS: already tracking, ignoring');
      return;
    }

    _isTracking = true;
    _isPaused = false;
    _totalDistance = 0.0;
    _lastPosition = null;
    _recentPositions.clear();

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

      // Фильтр точности
      if (position.accuracy > _maxAccuracy) {
        _log('⚠️ GPS: poor accuracy (${position.accuracy.toStringAsFixed(1)}m > ${_maxAccuracy}m), ignoring');
        return;
      }

      // Добавляем в буфер
      _recentPositions.add(position);
      if (_recentPositions.length > _bufferSize) {
        _recentPositions.removeAt(0);
      }

      // Получаем сглаженную позицию
      Position? smoothed = _getSmoothedPosition();
      if (smoothed == null) {
        _log('🟡 GPS: waiting for more data...');
        return;
      }

      if (_lastPosition != null) {
        // Проверяем на реалистичность
        if (!_isRealisticMovement(smoothed, _lastPosition!)) {
          _log('⚠️ GPS: unrealistic movement, ignoring');
          return;
        }

        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          smoothed.latitude,
          smoothed.longitude,
        );
        
        _log('📏 GPS: smoothed distance: ${distance.toStringAsFixed(2)}m');

        if (distance >= _minDistance) {
          _totalDistance += distance / 1000;
          _log('✅ GPS: ACCEPTING ${distance.toStringAsFixed(2)}m, total: ${_totalDistance.toStringAsFixed(4)} km');
          _distanceStreamController.add(_totalDistance);
          
          // Обновляем последнюю позицию
          _lastPosition = smoothed;
        } else {
          _log('📏 GPS: distance too small (${distance.toStringAsFixed(2)}m < ${_minDistance}m), ignoring');
        }
      } else {
        _log('🟢 GPS: first position, initializing');
        _lastPosition = smoothed;
      }

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
    _recentPositions.clear();
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
    _recentPositions.clear();
    _distanceStreamController.add(0.0);
  }
}