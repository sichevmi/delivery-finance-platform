// gps_service.dart – Версия A: Adaptive Kalman V3.0
import 'dart:async';
import 'dart:math';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GpsService {
  static const String VERSION = '3.0 - ADAPTIVE KALMAN (IMPROVED)';
  
  // Состояние трекера
  bool _isTracking = false;
  bool _isFirstFix = true;
  LocationData? _lastLocation;
  DateTime? _lastTimestamp;
  double _totalDistance = 0.0;
  
  // Параметры фильтра Калмана
  double _filteredDistance = 0.0;
  double _k = 0.268;        // коэффициент Калмана (адаптивный)
  double _q = 0.1;          // шум процесса
  double _r = 3.0;          // шум измерения
  
  // Константы
  static const double MIN_GAIN = 0.12;
  static const double MAX_GAIN = 0.8;
  static const double STATIONARY_SPEED_THRESHOLD = 0.3; // м/с
  
  // Логирование
  final List<String> _log = [];
  bool _logEnabled = false;
  
  // Геттеры
  double get totalDistance => _totalDistance;
  String get version => VERSION;
  bool get isTracking => _isTracking;
  
  // Инициализация
  Future<void> init() async {
    // Загружаем сохранённую дистанцию (опционально)
    final prefs = await SharedPreferences.getInstance();
    _totalDistance = prefs.getDouble('totalDistance') ?? 0.0;
  }
  
  // Старт трекинга
  void startTracking() {
    _isTracking = true;
    _isFirstFix = true;
    _lastLocation = null;
    _filteredDistance = 0.0;
    _log.clear();
    _addLog('🟢 GPS: startTracking() V$VERSION');
  }
  
  // Стоп трекинга
  void stopTracking() {
    _isTracking = false;
    _addLog('🛑 GPS: stopTracking()');
    _saveDistance();
  }
  
  // Сброс дистанции
  void resetDistance() {
    _totalDistance = 0.0;
    _filteredDistance = 0.0;
    _lastLocation = null;
    _isFirstFix = true;
    _addLog('🔄 GPS: resetDistance()');
  }
  
  // Основной обработчик новых GPS-данных
  void onLocationChanged(LocationData location) {
    if (!_isTracking) return;
    
    // Проверяем валидность данных
    if (location.latitude == null || location.longitude == null) return;
    
    if (_isFirstFix) {
      _lastLocation = location;
      _lastTimestamp = DateTime.now();
      _isFirstFix = false;
      _addLog('📍 GPS: first position, initializing');
      return;
    }
    
    // Расчёт сырого расстояния
    final rawDistance = _calculateDistance(_lastLocation!, location);
    final speed = location.speed ?? 0.0;
    final accuracy = location.accuracy ?? 0.0;
    
    // Минимальный порог для игнорирования шума
    if (rawDistance < 0.5) {
      _lastLocation = location;
      return;
    }
    
    // --- Адаптация параметров фильтра ---
    _adaptParameters(speed, accuracy);
    
    // --- Динамический порог для "большого скачка" ---
    final dynamicThreshold = _calculateDynamicThreshold(speed);
    double clampedRaw = rawDistance;
    if (rawDistance > dynamicThreshold && speed > 1.0) {
      clampedRaw = rawDistance.clamp(0.0, dynamicThreshold);
      _addLog('⚠️ GPS: large jump limited to ${clampedRaw.toStringAsFixed(1)}m');
    }
    
    // --- Применение фильтра Калмана ---
    _applyKalman(clampedRaw, speed);
    
    // --- Обновление позиции ---
    _lastLocation = location;
    _lastTimestamp = DateTime.now();
  }
  
  // Адаптация коэффициента усиления
  void _adaptParameters(double speed, double accuracy) {
    double newK;
    if (accuracy > 30.0) {
      newK = 0.1;  // очень плохая точность – почти не доверяем
    } else if (accuracy > 15.0) {
      newK = 0.2;
    } else if (speed > 10.0) {
      newK = 0.8;  // быстрая езда – доверяем данным
    } else if (speed > 5.0) {
      newK = 0.6;
    } else if (speed > 2.0) {
      newK = 0.4;
    } else if (speed > 0.5) {
      newK = 0.25;
    } else {
      newK = 0.12; // стоя – сильное сглаживание
    }
    // Плавное изменение, чтобы избежать резких переходов
    _k = _k * 0.7 + newK * 0.3;
    
    // Адаптация q и r
    _q = (0.1 + speed * 0.05).clamp(0.05, 0.8);
    _r = (1.0 + accuracy * 0.3).clamp(1.0, 10.0);
  }
  
  // Динамический порог для скачка
  double _calculateDynamicThreshold(double speed) {
    // Ожидаемое приращение за интервал ~2 секунды с запасом
    final expected = speed * 2.0 * 1.5 + 10.0;
    return expected.clamp(10.0, 80.0);
  }
  
  // Применение фильтра Калмана
  void _applyKalman(double rawDistance, double speed) {
    // Предсказание: используем предыдущее отфильтрованное значение
    final predicted = _filteredDistance;
    // Обновление по Калману
    final innovation = rawDistance - predicted;
    _filteredDistance = predicted + _k * innovation;
    
    // Добавляем к общей дистанции, если > 0.01 м
    if (_filteredDistance > 0.01) {
      _totalDistance += _filteredDistance;
      _addLog('📏 GPS: accepted ${_filteredDistance.toStringAsFixed(2)}m, total: ${(_totalDistance/1000).toStringAsFixed(4)} km');
    }
    
    // Сбрасываем фильтр для следующего шага
    _filteredDistance = 0.0;
  }
  
  // Расчёт расстояния по гаверсинусам
  double _calculateDistance(LocationData from, LocationData to) {
    const R = 6371000; // радиус Земли в метрах
    final dLat = _toRadians(to.latitude! - from.latitude!);
    final dLon = _toRadians(to.longitude! - from.longitude!);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(from.latitude!)) * cos(_toRadians(to.latitude!)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }
  
  double _toRadians(double degrees) => degrees * pi / 180.0;
  
  // Логирование
  void _addLog(String message) {
    if (_logEnabled) {
      final timestamp = DateTime.now().toIso8601String();
      _log.add('[$timestamp] $message');
    }
  }
  
  Future<void> _saveDistance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('totalDistance', _totalDistance);
  }
  
  // Получение лога
  List<String> getLog() => _log;
  
  // Включение/выключение логов
  void setLoggingEnabled(bool enabled) {
    _logEnabled = enabled;
  }
}