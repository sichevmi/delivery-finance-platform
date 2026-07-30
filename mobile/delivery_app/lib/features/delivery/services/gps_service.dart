// gps_service.dart – Версия 1: Адаптивный Калман V3.0 (исправленная)
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GpsService {
  static const String VERSION = 'ADAPTIVE KALMAN v3.0 (geolocator)';

  // ---- Состояние трекера ----
  bool _isTracking = false;
  bool _isPaused = false;
  bool _isFirstFix = true;
  Position? _lastPosition;
  DateTime? _lastTimestamp;
  double _totalDistance = 0.0;

  // ---- Фильтр Калмана ----
  double _filteredDistance = 0.0;
  double _k = 0.268;
  double _q = 0.1;
  double _r = 3.0;

  static const double MIN_GAIN = 0.12;
  static const double MAX_GAIN = 0.8;
  static const double STATIONARY_SPEED_THRESHOLD = 0.3;

  // ---- Логирование ----
  final List<String> _log = [];
  bool _logEnabled = false;
  String _logFilePath = '';
  final _logFileLock = Object();

  // ---- Стрим для дистанции ----
  StreamController<double>? _distanceController;
  Stream<double> get distanceStream {
    // Если контроллер null или закрыт, создаём новый (broadcast)
    if (_distanceController == null || _distanceController!.isClosed) {
      _distanceController = StreamController<double>.broadcast();
    }
    return _distanceController!.stream;
  }

  // ---- Инициализация ----
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _totalDistance = prefs.getDouble('totalDistance') ?? 0.0;
    final dir = Directory.systemTemp;
    _logFilePath = '${dir.path}/gps_log.txt';
  }

  // ---- Управление трекингом ----
  void startTracking() {
    _isTracking = true;
    _isPaused = false;
    _isFirstFix = true;
    _lastPosition = null;
    _filteredDistance = 0.0;
    _log.clear();
    _addLog('🟢 GPS: startTracking() V$VERSION');
    // Если контроллер закрыт, он будет создан при первом добавлении события.
    // Но чтобы быть уверенным, создаём новый, если нужно.
    if (_distanceController == null || _distanceController!.isClosed) {
      _distanceController = StreamController<double>.broadcast();
    }
  }

  void stopTracking() {
    _isTracking = false;
    _isPaused = false;
    _addLog('🛑 GPS: stopTracking()');
    _saveDistance();
    // Не закрываем контроллер здесь, чтобы не мешать другим подпискам.
    // Просто перестаём добавлять события.
    // Если хотите закрыть, можно закрыть, но тогда нужно пересоздавать при следующем старте.
    // Для надёжности — не закрываем, просто перестаём использовать.
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
    _filteredDistance = 0.0;
    _lastPosition = null;
    _isFirstFix = true;
    _addLog('🔄 GPS: resetDistance()');
    // Добавляем в стрим, если контроллер открыт, иначе создаём новый
    try {
      final controller = _getController();
      controller.add(_totalDistance);
    } catch (e) {
      // Если ошибка — просто игнорируем, создадим новый контроллер при следующем добавлении
    }
  }

  void forceRefresh() {
    _addLog('🔄 GPS: forceRefresh() called');
  }

  // ---- Получение контроллера с проверкой ----
  StreamController<double> _getController() {
    if (_distanceController == null || _distanceController!.isClosed) {
      _distanceController = StreamController<double>.broadcast();
    }
    return _distanceController!;
  }

  // ---- Обработка новых GPS-данных (геолокатор) ----
  void onLocationChanged(Position position) {
    if (!_isTracking || _isPaused) return;

    if (_isFirstFix) {
      _lastPosition = position;
      _lastTimestamp = DateTime.now();
      _isFirstFix = false;
      _addLog('📍 GPS: first position, initializing');
      return;
    }

    final rawDistance = _calculateDistance(_lastPosition!, position);
    final speed = position.speed; // в м/с
    final accuracy = position.accuracy; // в метрах

    if (rawDistance < 0.5) {
      _lastPosition = position;
      return;
    }

    _adaptParameters(speed, accuracy);

    final dynamicThreshold = _calculateDynamicThreshold(speed);
    double clampedRaw = rawDistance;
    if (rawDistance > dynamicThreshold && speed > 1.0) {
      clampedRaw = rawDistance.clamp(0.0, dynamicThreshold);
      _addLog('⚠️ GPS: large jump limited to ${clampedRaw.toStringAsFixed(1)}m');
    }

    _applyKalman(clampedRaw, speed);

    _lastPosition = position;
    _lastTimestamp = DateTime.now();
  }

  // ---- Вспомогательные методы фильтра ----
  void _adaptParameters(double speed, double accuracy) {
    double newK;
    if (accuracy > 30.0) newK = 0.1;
    else if (accuracy > 15.0) newK = 0.2;
    else if (speed > 10.0) newK = 0.8;
    else if (speed > 5.0) newK = 0.6;
    else if (speed > 2.0) newK = 0.4;
    else if (speed > 0.5) newK = 0.25;
    else newK = 0.12;
    _k = _k * 0.7 + newK * 0.3;
    _q = (0.1 + speed * 0.05).clamp(0.05, 0.8);
    _r = (1.0 + accuracy * 0.3).clamp(1.0, 10.0);
  }

  double _calculateDynamicThreshold(double speed) {
    final expected = speed * 2.0 * 1.5 + 10.0;
    return expected.clamp(10.0, 80.0);
  }

  void _applyKalman(double rawDistance, double speed) {
    final predicted = _filteredDistance;
    final innovation = rawDistance - predicted;
    _filteredDistance = predicted + _k * innovation;

    if (_filteredDistance > 0.01) {
      _totalDistance += _filteredDistance;
      try {
        final controller = _getController();
        controller.add(_totalDistance);
      } catch (e) {
        // Если контроллер закрыт, игнорируем, но создадим новый при следующем вызове
        _addLog('⚠️ Ошибка добавления в стрим: $e');
      }
      _addLog('📏 GPS: accepted ${_filteredDistance.toStringAsFixed(2)}m, total: ${(_totalDistance/1000).toStringAsFixed(4)} km');
    }
    _filteredDistance = 0.0;
  }

  // ---- Расчёт расстояния по гаверсинусам ----
  double _calculateDistance(Position from, Position to) {
    const R = 6371000;
    final dLat = _toRadians(to.latitude - from.latitude);
    final dLon = _toRadians(to.longitude - from.longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(from.latitude)) * cos(_toRadians(to.latitude)) *
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