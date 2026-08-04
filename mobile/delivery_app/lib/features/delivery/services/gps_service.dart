// gps_service.dart – с правильной передачей приращений
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';

typedef DistanceUpdateCallback = void Function(double deltaDistance, bool isPaid);

class GpsService {
  GpsService(){
    print('🟢 GpsService: создан экземпляр ${hashCode}');
  }

  // ---- Внутреннее состояние ----
  StreamSubscription<Position>? _positionSubscription;
  bool _isTracking = false;
  double _totalDistance = 0.0;
  Position? _lastPosition;
  bool _isPaused = false;

  // ---- Колбэк для обновления пробега в ShiftProvider ----
  DistanceUpdateCallback? _onDistanceUpdate;

  // ---- Константы ----
  static const double _maxAccuracy = 50.0;
  static const double _minDistance = 0.1;
  static const double _maxJump = 100.0;

  // ---- Логирование ----
  bool _isLoggingEnabled = false;
  String _logBuffer = '';
  final int _maxLogSize = 500 * 1024;
  File? _logFile;

  double get currentDistance => _totalDistance;
  final _distanceStreamController = StreamController<double>.broadcast();
  Stream<double> get distanceStream => _distanceStreamController.stream;

  void setOnDistanceUpdate(DistanceUpdateCallback callback) {
    _onDistanceUpdate = callback;
  }

  // ---- Публичные методы логирования ----
  Future<void> startLogging() async {
    if (_isLoggingEnabled) return;
    _isLoggingEnabled = true;
    _logBuffer = '';
    _logBuffer += '=== GPS LOG (minDistance=${_minDistance}m, maxAccuracy=${_maxAccuracy}m) ===\n';
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

  void addLog(String message) {
    if (!_isLoggingEnabled) return;
    _log(message);
  }

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    _logBuffer += '[$timestamp] $message\n';
    print(message);
  }

  Future<void> _saveLogToFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/gps_log_final.txt');
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

  // ---- Основные методы GPS ----
    void startTracking() {
    print('🟢 GPS: startTracking() called on instance ${hashCode}');
    if (_isTracking) {
      print('🟡 GPS: already tracking');
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

    print('🟢 GPS: подписываемся на поток позиции');
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (Position position) => _onPositionUpdate(position),
      onError: (error) => print('🔴 GPS error: $error'),
      cancelOnError: false,
    );
    print('🟢 GPS: поток запущен');
  }

  void _onPositionUpdate(Position position) {
    print('📍 GPS: обновление позиции на instance ${hashCode}');
    if (!_isTracking || _isPaused) return;

    print('📍 GPS: lat: ${position.latitude}, lon: ${position.longitude}, acc: ${position.accuracy}m');

    if (position.accuracy > _maxAccuracy) {
      print('⚠️ Accuracy too poor (${position.accuracy}m), ignoring');
      return;
    }

    if (_lastPosition == null) {
      _lastPosition = position;
      print('🟢 First position stored');
      return;
    }

    double distance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      position.latitude,
      position.longitude,
    );
    print('📏 Raw distance: ${distance.toStringAsFixed(2)}m');

    if (distance < _minDistance) {
      print('📏 Too small (< ${_minDistance}m), ignoring');
      return;
    }

    if (distance > _maxJump) {
      print('⚠️ Jump > ${_maxJump}m (${distance.toStringAsFixed(2)}m), ignoring');
      return;
    }

    final deltaKm = distance / 1000;
    _totalDistance += deltaKm;
    
    print('✅ ACCEPTED ${distance.toStringAsFixed(2)}m (${deltaKm.toStringAsFixed(4)} km), total: ${_totalDistance.toStringAsFixed(4)} km');
    _distanceStreamController.add(_totalDistance);
    _lastPosition = position;

    if (_onDistanceUpdate != null) {
      print('🔄 Вызываем колбэк с deltaKm=$deltaKm');
      _onDistanceUpdate?.call(deltaKm, true);
    } else {
      print('⚠️ _onDistanceUpdate == null, колбэк не вызван');
    }
  }

  void pauseTracking() {
    _log('⏸️ Pause');
    _isPaused = true;
  }

  void resumeTracking() {
    _log('▶️ Resume');
    _isPaused = false;
  }

  void stopTracking() {
    _log('🛑 Stop');
    print('🔴 stopTracking() called from: ${StackTrace.current}');
    _isTracking = false;
    _isPaused = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _lastPosition = null;
    _totalDistance = 0.0;
    _distanceStreamController.add(0.0);
    if (_isLoggingEnabled) _saveLogToFile();
  }

  void forceRefresh() => _log('🔄 ForceRefresh (no-op)');

  double getTotalDistance() => _totalDistance;

  void resetDistance() {
    _log('🔄 Reset');
    _totalDistance = 0.0;
    _lastPosition = null;
    _distanceStreamController.add(0.0);
  }
}