// gps_service.dart – Версия B: Speed Integration V1.0
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GpsService {
  static const String VERSION = '1.0 - SPEED INTEGRATION';

  // ---- Основные параметры трекера ----
  bool _isTracking = false;
  bool _isPaused = false;
  bool _isFirstFix = true;
  LocationData? _lastLocation;
  DateTime? _lastTimestamp;
  double _totalDistance = 0.0;

  // ---- Константы фильтрации ----
  static const double MIN_SPEED = 0.2;        // м/с – игнорируем медленное движение (шум)
  static const double MAX_SPEED = 40.0;       // м/с – ограничение (144 км/ч)
  static const double MIN_DISTANCE_INCREMENT = 0.5;  // минимальное приращение для учёта
  static const double MAX_DISTANCE_INCREMENT = 100.0; // максимальное приращение за один шаг

  // ---- Логирование ----
  final List<String> _log = [];
  bool _logEnabled = false;
  String _logFilePath = '';
  final _logFileLock = Object();

  // ---- Стрим для дистанции ----
  final _distanceController = StreamController<double>.broadcast();
  Stream<double> get distanceStream => _distanceController.stream;

  // ---- Инициализация ----
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _totalDistance = prefs.getDouble('totalDistance') ?? 0.0;
    _logFilePath = (await _getLogDirectoryPath()) + '/gps_log.txt';
  }

  // ---- Управление трекингом ----
  void startTracking() {
    _isTracking = true;
    _isPaused = false;
    _isFirstFix = true;
    _lastLocation = null;
    _lastTimestamp = null;
    _log.clear();
    _addLog('🟢 GPS: startTracking() V$VERSION');
  }

  void stopTracking() {
    _isTracking = false;
    _isPaused = false;
    _addLog('🛑 GPS: stopTracking()');
    _saveDistance();
    _distanceController.close();
  }

  void pauseTracking() {
    if (_isTracking && !_isPaused) {
      _isPaused = true;
      _addLog('⏸️ GPS: pauseTracking()');
    }
  }

  void resumeTracking() {
    if (_isTracking && _isPaused) {
      _isPaused = false;
      _isFirstFix = true;
      _addLog('▶️ GPS: resumeTracking()');
    }
  }

  void resetDistance() {
    _totalDistance = 0.0;
    _lastLocation = null;
    _lastTimestamp = null;
    _isFirstFix = true;
    _addLog('🔄 GPS: resetDistance()');
    _distanceController.add(_totalDistance);
  }

  void forceRefresh() {
    _addLog('🔄 GPS: forceRefresh() called');
  }

  // ---- Обработка новых GPS-данных ----
  void onLocationChanged(LocationData location) {
    if (!_isTracking || _isPaused) return;
    if (location.speed == null) return;

    final speed = location.speed!;
    final timestamp = DateTime.now();

    if (_isFirstFix) {
      _lastLocation = location;
      _lastTimestamp = timestamp;
      _isFirstFix = false;
      _addLog('📍 GPS: first position, initializing');
      return;
    }

    final dt = timestamp.difference(_lastTimestamp!).inSeconds.toDouble();
    if (dt <= 0.0) {
      _lastTimestamp = timestamp;
      return;
    }

    final effectiveDt = dt.clamp(0.5, 5.0);
    double effectiveSpeed = speed;
    if (effectiveSpeed < MIN_SPEED) {
      effectiveSpeed = 0.0;
    } else if (effectiveSpeed > MAX_SPEED) {
      effectiveSpeed = MAX_SPEED;
    }

    double distance = effectiveSpeed * effectiveDt;

    if (distance < MIN_DISTANCE_INCREMENT) {
      _lastTimestamp = timestamp;
      _lastLocation = location;
      return;
    }

    if (distance > MAX_DISTANCE_INCREMENT) {
      distance = MAX_DISTANCE_INCREMENT;
    }

    _totalDistance += distance;
    _distanceController.add(_totalDistance);
    _addLog('📏 GPS: accepted ${distance.toStringAsFixed(2)}m, total: ${(_totalDistance/1000).toStringAsFixed(4)} km');

    _lastTimestamp = timestamp;
    _lastLocation = location;
  }

  // ---- Расчёт расстояния (не используется, но оставлен для совместимости) ----
  double _calculateDistance(LocationData from, LocationData to) {
    const R = 6371000;
    final dLat = _toRadians(to.latitude! - from.latitude!);
    final dLon = _toRadians(to.longitude! - from.longitude!);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(from.latitude!)) * cos(_toRadians(to.latitude!)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180.0;

  // ---- Сохранение состояния ----
  Future<void> _saveDistance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('totalDistance', _totalDistance);
  }

  // ---- Логирование в файл ----
  Future<void> startLogging() async {
    _logEnabled = true;
    _log.clear();
    _addLog('=== GPS LOG STARTED (V$VERSION) ===');
    _addLog('Timestamp: ${DateTime.now().toIso8601String()}');
    _addLog('========================');
    try {
      final file = File(_logFilePath);
      if (await file.exists()) await file.delete();
      await file.create(recursive: true);
      await file.writeAsString('');
    } catch (e) {
      print('Ошибка создания лог-файла: $e');
    }
  }

  Future<void> stopLogging() async {
    _logEnabled = false;
    await _flushLogToFile();
    _addLog('📁 Log saved to: $_logFilePath');
  }

  Future<void> _flushLogToFile() async {
    if (_log.isEmpty) return;
    try {
      final file = File(_logFilePath);
      await file.writeAsString(_log.join('\n') + '\n', mode: FileMode.append);
      _log.clear();
    } catch (e) {
      print('Ошибка записи лога: $e');
    }
  }

  Future<String> getLogFilePath() async {
    return _logFilePath;
  }

  Future<String> _getLogDirectoryPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  void _addLog(String message) {
    if (_logEnabled) {
      final timestamp = DateTime.now().toIso8601String();
      _log.add('[$timestamp] $message');
      if (_log.length > 100) {
        _flushLogToFile();
      }
    }
  }

  // ---- Геттеры ----
  double get totalDistance => _totalDistance;
  bool get isTracking => _isTracking;
  String get version => VERSION;
}