// gps_service.dart – Стрим-версия с настроенными порогами (minSpeed=0, minDistance=2)
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

  // ---- КОНСТАНТЫ (настроены) ----
  static const double _maxAccuracy = 30.0;
  static const double _minDistance = 2.0;
  static const double _maxJump = 100.0;
  static const double _minSpeed = 0.0;   // теперь 0 – не блокирует

  // Логирование (без изменений)
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
    _logBuffer += '=== GPS LOG STARTED (TUNED STREAM) ===\n';
    _logBuffer += 'Timestamp: ${DateTime.now()}\n';
    _logBuffer += 'Min distance: ${_minDistance}m, Min speed: ${_minSpeed}\n';
    _logBuffer += '========================\n\n';
    _log('📁 GPS logging started (TUNED)');
    await _saveLogToFile();
  }

  Future<void> stopLogging() async {
    if (!_isLoggingEnabled) return;
    _isLoggingEnabled = false;
    _log('📁 GPS logging stopped (TUNED)');
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
      final file = File('${directory.path}/gps_log_tuned.txt');
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

  void startTracking() {
    _log('🟢 GPS: startTracking() TUNED');
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

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (Position position) => _onPositionUpdate(position),
      onError: (error) => _log('🔴 GPS error: $error'),
      cancelOnError: false,
    );
    _log('🟢 GPS: stream started');
  }

  void _onPositionUpdate(Position position) {
    if (!_isTracking || _isPaused) return;

    _log('📍 GPS: lat: ${position.latitude}, lon: ${position.longitude}, '
        'acc: ${position.accuracy}m, speed: ${position.speed?.toStringAsFixed(2) ?? "N/A"}');

    // Фильтр точности
    if (position.accuracy > _maxAccuracy) {
      _log('⚠️ Accuracy too poor (${position.accuracy}m), ignoring');
      return;
    }

    // Фильтр скорости (теперь minSpeed=0, поэтому никогда не сработает)
    final speed = position.speed ?? 0.0;
    if (speed < _minSpeed) {
      _log('⏸️ Speed too low (${speed.toStringAsFixed(2)} m/s), ignoring');
      return;
    }

    // Первая позиция
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

    _totalDistance += distance / 1000;
    _log('✅ ACCEPTED ${distance.toStringAsFixed(2)}m, total: ${_totalDistance.toStringAsFixed(4)} km');
    _distanceStreamController.add(_totalDistance);
    _lastPosition = position;
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
    _isTracking = false;
    _isPaused = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _lastPosition = null;
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