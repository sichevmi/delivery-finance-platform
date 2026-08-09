import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:delivery_app/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

typedef DistanceUpdateCallback = void Function(double deltaDistance, bool isPaid);

class GpsService {
  static GpsService? _instance;
  
  GpsService._internal() {
    logMessage('🟢 GpsService: создан экземпляр ${hashCode}', category: 'GPS');
  }
  
  factory GpsService() {
    _instance ??= GpsService._internal();
    return _instance!;
  }

  StreamSubscription<Position>? _positionSubscription;
  bool _isTracking = false;
  double _totalDistance = 0.0;
  Position? _lastPosition;
  bool _isPaused = false;

  DistanceUpdateCallback? _onDistanceUpdate;

  static const double _minDistance = 0.1;
  static const double _maxJump = 100.0;
  
  double get _maxAccuracy {
    if (kIsWeb) {
      return 1000.0;
    }
    return 50.0;
  }

  bool _isLoggingEnabled = false;
  String _logBuffer = '';
  final int _maxLogSize = 500 * 1024;
  File? _logFile;

  double get currentDistance => _totalDistance;
  final _distanceStreamController = StreamController<double>.broadcast();
  Stream<double> get distanceStream => _distanceStreamController.stream;

  void setOnDistanceUpdate(DistanceUpdateCallback callback) {
    logMessage('🟢 GpsService.setOnDistanceUpdate: колбэк установлен', category: 'GPS');
    _onDistanceUpdate = callback;
  }

  // ===== МЕТОДЫ ЛОГИРОВАНИЯ (устаревшие, оставлены для совместимости) =====

  Future<void> startLogging() async {
    if (kIsWeb) {
      logMessage('📁 GPS логирование на вебе (в памяти)', category: 'GPS');
      _isLoggingEnabled = true;
      _logBuffer = '=== GPS LOG (Web) ===\n';
      _logBuffer += 'Timestamp: ${DateTime.now()}\n';
      _logBuffer += '========================\n\n';
      return;
    }
    
    if (_isLoggingEnabled) return;
    _isLoggingEnabled = true;
    _logBuffer = '';
    _logBuffer += '=== GPS LOG (minDistance=${_minDistance}m, maxAccuracy=${_maxAccuracy}m) ===\n';
    _logBuffer += 'Timestamp: ${DateTime.now()}\n';
    _logBuffer += '========================\n\n';
    logMessage('📁 GPS logging started', category: 'GPS');
    await _saveLogToFile();
  }

  Future<void> stopLogging() async {
    if (!_isLoggingEnabled) return;
    _isLoggingEnabled = false;
    logMessage('📁 GPS logging stopped', category: 'GPS');
    if (!kIsWeb) {
      await _saveLogToFile();
    }
  }

  void addLog(String message) {
    if (!_isLoggingEnabled) return;
    logMessage(message, category: 'GPS');
  }

  void _log(String message) {
    // Используем общий логгер с категорией GPS
    logMessage(message, category: 'GPS');
  }

  Future<void> _saveLogToFile() async {
    if (kIsWeb) return;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/gps_log_final.txt');
      _logFile = file;
      await file.writeAsString(_logBuffer);
      logMessage('📁 Log saved to: ${file.path}', category: 'GPS');
    } catch (e) {
      logMessage('❌ Failed to save log: $e', category: 'GPS', level: LogLevel.error);
    }
  }

  Future<String?> getLogFilePath() async {
    if (kIsWeb) return null;
    if (_logFile == null) return null;
    return _logFile!.path;
  }

  Future<String> readLogFile() async {
    if (kIsWeb) {
      return _logBuffer.isNotEmpty ? _logBuffer : 'Логи в памяти (веб)';
    }
    if (_logFile == null) return 'Log file not found';
    try {
      return await _logFile!.readAsString();
    } catch (e) {
      return 'Error reading log: $e';
    }
  }

  // ===== ОСНОВНЫЕ МЕТОДЫ GPS =====

  void startTracking() {
    logMessage('🟢 GPS: startTracking() called on instance ${hashCode}', category: 'GPS');
    if (_isTracking) {
      logMessage('🟡 GPS: already tracking', category: 'GPS');
      return;
    }
    _isTracking = true;
    _isPaused = false;
    _totalDistance = 0.0;
    _lastPosition = null;

    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    logMessage('🟢 GPS: подписываемся на поток позиции', category: 'GPS');
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (Position position) => _onPositionUpdate(position),
      onError: (error) => logMessage('🔴 GPS error: $error', category: 'GPS', level: LogLevel.error),
      cancelOnError: false,
    );
    logMessage('🟢 GPS: поток запущен', category: 'GPS');
  }

  void _onPositionUpdate(Position position) {
    if (!_isTracking || _isPaused) return;

    final now = DateTime.now();
    if (now.difference(position.timestamp).inSeconds > 30) {
      logMessage('⚠️ Position too old (${now.difference(position.timestamp).inSeconds}s), ignoring', category: 'GPS');
      return;
    }

    logMessage('📍 GPS: lat: ${position.latitude}, lon: ${position.longitude}, acc: ${position.accuracy}m', category: 'GPS');

    if (position.accuracy > _maxAccuracy) {
      logMessage('⚠️ Accuracy too poor (${position.accuracy}m), ignoring', category: 'GPS');
      return;
    }

    if (_lastPosition == null) {
      _lastPosition = position;
      logMessage('🟢 First position stored', category: 'GPS');
      return;
    }

    double distance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      position.latitude,
      position.longitude,
    );
    logMessage('📏 Raw distance: ${distance.toStringAsFixed(2)}m', category: 'GPS');

    if (distance < _minDistance) {
      logMessage('📏 Too small (< ${_minDistance}m), ignoring', category: 'GPS');
      return;
    }

    if (distance > _maxJump) {
      logMessage('⚠️ Jump > ${_maxJump}m (${distance.toStringAsFixed(2)}m), ignoring', category: 'GPS');
      return;
    }

    final deltaKm = distance / 1000;
    _totalDistance += deltaKm;
    
    logMessage('✅ ACCEPTED ${distance.toStringAsFixed(2)}m (${deltaKm.toStringAsFixed(4)} km), total: ${_totalDistance.toStringAsFixed(4)} km', category: 'GPS');
    _distanceStreamController.add(_totalDistance);
    _lastPosition = position;

    if (_onDistanceUpdate != null) {
      logMessage('🔄 Вызываем колбэк с deltaKm=$deltaKm', category: 'GPS');
      _onDistanceUpdate?.call(deltaKm, true);
    } else {
      logMessage('⚠️ _onDistanceUpdate == null, колбэк не вызван', category: 'GPS');
    }
  }

  void pauseTracking() {
    logMessage('⏸️ GPS: pauseTracking()', category: 'GPS');
    _isPaused = true;
  }

  void resumeTracking() {
    logMessage('▶️ GPS: resumeTracking()', category: 'GPS');
    _isPaused = false;
  }

  void stopTracking() {
    logMessage('🛑 GPS: stopTracking() on instance ${hashCode}', category: 'GPS');
    _isTracking = false;
    _isPaused = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _lastPosition = null;
    _totalDistance = 0.0;
    _distanceStreamController.add(0.0);
    if (_isLoggingEnabled && !kIsWeb) _saveLogToFile();
  }

  void forceRefresh() => logMessage('🔄 ForceRefresh (no-op)', category: 'GPS');

  double getTotalDistance() => _totalDistance;

  void resetDistance() {
    logMessage('🔄 GPS: resetDistance()', category: 'GPS');
    _totalDistance = 0.0;
    _lastPosition = null;
    _distanceStreamController.add(0.0);
  }
}