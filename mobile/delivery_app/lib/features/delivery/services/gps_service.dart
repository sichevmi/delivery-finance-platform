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

  static const int _pollInterval = 2;

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

  // ---- Основные методы ----

  void startTracking() {
    _log('🟢 GPS: startTracking() called (STREAM mode)');
    if (_isTracking) {
      _log('🟡 GPS: already tracking, ignoring');
      return;
    }

    _isTracking = true;
    _isPaused = false;
    _totalDistance = 0.0;
    _lastPosition = null;

    _startPositionStream();

    _log('🟢 GPS: position stream started');
  }

  void _startPositionStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3,
    );

    Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _onPositionReceived(position);
    }, onError: (error) {
      _log('🔴 GPS stream error: $error');
    });
  }

  void _onPositionReceived(Position position) {
    if (!_isTracking || _isPaused) {
      _log('⏸️ GPS: position ignored (tracking=$_isTracking, paused=$_isPaused)');
      return;
    }

    _log('📍 GPS: position received:');
    _log('   - lat: ${position.latitude}');
    _log('   - lon: ${position.longitude}');
    _log('   - accuracy: ${position.accuracy}m');
    _log('   - speed: ${position.speed?.toStringAsFixed(2) ?? "N/A"} m/s');
    _log('   - timestamp: ${position.timestamp}');

    if (position.accuracy > 50) {
      _log('⚠️ GPS: poor accuracy (${position.accuracy}m > 50m), but still using for test');
    }

    if (_lastPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      _log('📏 GPS: raw distance since last update: ${distance.toStringAsFixed(2)} meters');

      if (distance > 1000) {
        _log('⚠️ GPS: extreme jump > 1000m, ignoring');
        return;
      }

      if (distance < 0.5) {
        _log('📏 GPS: distance too small (< 0.5m), ignoring');
        return;
      }

      _log('✅ GPS: ACCEPTING distance: ${distance.toStringAsFixed(2)}m');
      _totalDistance += distance / 1000;
      _log('📏 GPS: total distance now: ${_totalDistance.toStringAsFixed(4)} km');
      _distanceStreamController.add(_totalDistance);
    } else {
      _log('🟢 GPS: first position, initializing');
    }
    _lastPosition = position;

    if (_isLoggingEnabled && _logBuffer.length > _maxLogSize) {
      _saveLogToFile();
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
    if (_isTracking && !_isPaused) {
      _log('🔄 GPS: forceRefresh - getting current position');
      Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      ).then((position) {
        _onPositionReceived(position);
        _log('🔄 GPS: forceRefresh completed');
      }).catchError((e) {
        _log('🔄 GPS: forceRefresh error: $e');
      });
    } else {
      _log('🔄 GPS: forceRefresh skipped (tracking=$_isTracking, paused=$_isPaused)');
    }
  }

  double getTotalDistance() => _totalDistance;

  void resetDistance() {
    _log('🔄 GPS: resetDistance()');
    _totalDistance = 0.0;
    _lastPosition = null;
    _distanceStreamController.add(0.0);
  }
}