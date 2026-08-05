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
    logMessage('🟢 GpsService: создан экземпляр ${hashCode}');
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
  
  // Точность в зависимости от платформы
  double get _maxAccuracy {
    if (kIsWeb) {
      return 1000.0; // На вебе низкая точность
    }
    return 50.0; // На мобильных высокая точность
  }

  bool _isLoggingEnabled = false;
  String _logBuffer = '';
  final int _maxLogSize = 500 * 1024;
  File? _logFile;

  double get currentDistance => _totalDistance;
  final _distanceStreamController = StreamController<double>.broadcast();
  Stream<double> get distanceStream => _distanceStreamController.stream;

  void setOnDistanceUpdate(DistanceUpdateCallback callback) {
    logMessage('🟢 GpsService.setOnDistanceUpdate: колбэк установлен');
    _onDistanceUpdate = callback;
  }

  // ===== МЕТОДЫ ЛОГИРОВАНИЯ =====

  Future<void> startLogging() async {
    if (kIsWeb) {
      logMessage('📁 GPS логирование на вебе (в памяти)');
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
    logMessage('📁 GPS logging started');
    await _saveLogToFile();
  }

  Future<void> stopLogging() async {
    if (!_isLoggingEnabled) return;
    _isLoggingEnabled = false;
    logMessage('📁 GPS logging stopped');
    if (!kIsWeb) {
      await _saveLogToFile();
    }
  }

  void addLog(String message) {
    if (!_isLoggingEnabled) return;
    _log(message);
  }

  void _log(String message) {
  final timestamp = DateTime.now().toIso8601String();
  _logBuffer += '[$timestamp] $message\n';
  // также дублируем в общий лог, чтобы видеть в консоли
  logMessage(message);
}

  Future<void> _saveLogToFile() async {
    if (kIsWeb) return; // На вебе не сохраняем в файл
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/gps_log_final.txt');
      _logFile = file;
      await file.writeAsString(_logBuffer);
      logMessage('📁 Log saved to: ${file.path}');
    } catch (e) {
      logMessage('❌ Failed to save log: $e');
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

  // Везде, где нужно писать в GPS-лог, используем _log() вместо logMessage()

void startTracking() {
  _log('🟢 GPS: startTracking() called on instance ${hashCode}');
  if (_isTracking) {
    _log('🟡 GPS: already tracking');
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

  _log('🟢 GPS: подписываемся на поток позиции');
  _positionSubscription = Geolocator.getPositionStream(
    locationSettings: settings,
  ).listen(
    (Position position) => _onPositionUpdate(position),
    onError: (error) => _log('🔴 GPS error: $error'),
    cancelOnError: false,
  );
  _log('🟢 GPS: поток запущен');
}

void _onPositionUpdate(Position position) {
  if (!_isTracking || _isPaused) return;

  final now = DateTime.now();
  if (now.difference(position.timestamp).inSeconds > 30) {
    _log('⚠️ Position too old (${now.difference(position.timestamp).inSeconds}s), ignoring');
    return;
  }

  _log('📍 GPS: обновление позиции на instance ${hashCode}');
  _log('📍 GPS: lat: ${position.latitude}, lon: ${position.longitude}, acc: ${position.accuracy}m');

  if (position.accuracy > _maxAccuracy) {
    _log('⚠️ Accuracy too poor (${position.accuracy}m), ignoring');
    return;
  }

  if (_lastPosition == null) {
    _lastPosition = position;
    _log('🟢 First position stored');
    return;
  }

  double distance = Geolocator.distanceBetween(
    _lastPosition!.latitude,
    _lastPosition!.longitude,
    position.latitude,
    position.longitude,
  );
  _log('📏 Raw distance: ${distance.toStringAsFixed(2)}m');

  if (distance < _minDistance) {
    _log('📏 Too small (< ${_minDistance}m), ignoring');
    return;
  }

  if (distance > _maxJump) {
    _log('⚠️ Jump > ${_maxJump}m (${distance.toStringAsFixed(2)}m), ignoring');
    return;
  }

  final deltaKm = distance / 1000;
  _totalDistance += deltaKm;
  
  _log('✅ ACCEPTED ${distance.toStringAsFixed(2)}m (${deltaKm.toStringAsFixed(4)} km), total: ${_totalDistance.toStringAsFixed(4)} km');
  _distanceStreamController.add(_totalDistance);
  _lastPosition = position;

  if (_onDistanceUpdate != null) {
    _log('🔄 Вызываем колбэк с deltaKm=$deltaKm');
    _onDistanceUpdate?.call(deltaKm, true);
  } else {
    _log('⚠️ _onDistanceUpdate == null, колбэк не вызван');
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
  _log('🛑 GPS: stopTracking() on instance ${hashCode}');
  _isTracking = false;
  _isPaused = false;
  _positionSubscription?.cancel();
  _positionSubscription = null;
  _lastPosition = null;
  _totalDistance = 0.0;
  _distanceStreamController.add(0.0);
  if (_isLoggingEnabled && !kIsWeb) _saveLogToFile();
}



  void forceRefresh() => logMessage('🔄 ForceRefresh (no-op)');

  double getTotalDistance() => _totalDistance;

void resetDistance() {
  _log('🔄 GPS: resetDistance()');
  _totalDistance = 0.0;
  _lastPosition = null;
  _distanceStreamController.add(0.0);
}
}