// gps_service.dart – Версия B: Speed Integration V1.0
import 'dart:async';
import 'dart:math';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GpsService {
  static const String VERSION = '1.0 - SPEED INTEGRATION';
  
  // Состояние трекера
  bool _isTracking = false;
  bool _isFirstFix = true;
  LocationData? _lastLocation;
  DateTime? _lastTimestamp;
  double _totalDistance = 0.0;
  
  // Константы фильтрации
  static const double MIN_SPEED = 0.2;        // м/с – игнорируем медленное движение (шум)
  static const double MAX_SPEED = 40.0;       // м/с – ограничение (144 км/ч)
  static const double MIN_DISTANCE_INCREMENT = 0.5;  // минимальное приращение для учёта
  static const double MAX_DISTANCE_INCREMENT = 100.0; // максимальное приращение за один шаг
  
  // Логирование
  final List<String> _log = [];
  bool _logEnabled = false;
  
  // Геттеры
  double get totalDistance => _totalDistance;
  String get version => VERSION;
  bool get isTracking => _isTracking;
  
  // Инициализация
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _totalDistance = prefs.getDouble('totalDistance') ?? 0.0;
  }
  
  // Старт трекинга
  void startTracking() {
    _isTracking = true;
    _isFirstFix = true;
    _lastLocation = null;
    _lastTimestamp = null;
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
    _lastLocation = null;
    _lastTimestamp = null;
    _isFirstFix = true;
    _addLog('🔄 GPS: resetDistance()');
  }
  
  // Основной обработчик новых GPS-данных
  void onLocationChanged(LocationData location) {
    if (!_isTracking) return;
    
    // Проверяем наличие скорости
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
    
    // Вычисляем временной интервал (секунды)
    final dt = timestamp.difference(_lastTimestamp!).inSeconds.toDouble();
    if (dt <= 0.0) {
      _lastTimestamp = timestamp;
      return;
    }
    
    // Ограничиваем dt, чтобы избежать больших скачков (например, при паузе)
    final effectiveDt = dt.clamp(0.5, 5.0);
    
    // Фильтруем скорость
    double effectiveSpeed = speed;
    if (effectiveSpeed < MIN_SPEED) {
      // Если скорость меньше порога – считаем, что стоим
      effectiveSpeed = 0.0;
    } else if (effectiveSpeed > MAX_SPEED) {
      effectiveSpeed = MAX_SPEED;
    }
    
    // Расстояние = скорость * время
    double distance = effectiveSpeed * effectiveDt;
    
    // Проверка минимального приращения
    if (distance < MIN_DISTANCE_INCREMENT) {
      _lastTimestamp = timestamp;
      _lastLocation = location;
      return;
    }
    
    // Ограничиваем максимальное приращение (защита от выбросов)
    if (distance > MAX_DISTANCE_INCREMENT) {
      distance = MAX_DISTANCE_INCREMENT;
    }
    
    // Добавляем к общей дистанции
    _totalDistance += distance;
    _addLog('📏 GPS: accepted ${distance.toStringAsFixed(2)}m, total: ${(_totalDistance/1000).toStringAsFixed(4)} km');
    
    // Обновляем время и позицию
    _lastTimestamp = timestamp;
    _lastLocation = location;
  }
  
  // Расчёт расстояния (не используется, но оставлен для совместимости)
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