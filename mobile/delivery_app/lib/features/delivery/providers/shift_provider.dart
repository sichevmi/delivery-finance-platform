import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/core/services/api_service.dart';
import 'package:delivery_app/features/delivery/providers/gps_provider.dart';
import 'package:delivery_app/features/delivery/providers/settings_provider.dart';
import 'package:delivery_app/features/delivery/services/gps_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// СОСТОЯНИЕ СМЕНЫ
// ============================================================
class ShiftState {
  // Основной статус
  final bool isActive;        // true - смена существует (активна или приостановлена)
  final bool isPaused;        // true - приостановлена, false - активна
  final bool isCompleted;     // true - смена завершена
  
  // Временные метки
  final DateTime? shiftStartTime;
  final DateTime? pausedAt;
  final DateTime? resumedAt;
  
  // Накопленные данные
  final Duration totalWorkTime;
  final Duration totalIdleTime;
  final Duration totalOrderTime;
  final double totalPaidDistance;
  final double totalIdleDistance;
  final double processedIdleDistance;
  final int ordersCount;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final int? shiftId;
  
  // Для заказов
  final bool isOnOrder;
  final DateTime? orderStartTime;
  final DateTime? idleStartTime;
  
  // Вычисляемые поля
  bool get isActiveShift => isActive && !isCompleted && !isPaused;
  bool get isPausedShift => isActive && !isCompleted && isPaused;
  
  Duration get currentWorkTime {
    if (!isActive || isCompleted) return totalWorkTime;
    if (isPaused) return totalWorkTime;
    if (resumedAt != null) {
      return totalWorkTime + DateTime.now().difference(resumedAt!);
    }
    return totalWorkTime;
  }
  
  Duration get currentIdleTime {
    if (!isActive || isCompleted) return totalIdleTime;
    if (isPaused) return totalIdleTime;
    if (idleStartTime != null) {
      return totalIdleTime + DateTime.now().difference(idleStartTime!);
    }
    return totalIdleTime;
  }
  
  Duration get currentOrderTime {
    if (!isActive || isCompleted || isPaused) return totalOrderTime;
    if (isOnOrder && orderStartTime != null) {
      return totalOrderTime + DateTime.now().difference(orderStartTime!);
    }
    return totalOrderTime;
  }
  
  const ShiftState({
    this.isActive = false,
    this.isPaused = false,
    this.isCompleted = false,
    this.shiftStartTime,
    this.pausedAt,
    this.resumedAt,
    this.totalWorkTime = Duration.zero,
    this.totalIdleTime = Duration.zero,
    this.totalOrderTime = Duration.zero,
    this.totalPaidDistance = 0.0,
    this.totalIdleDistance = 0.0,
    this.processedIdleDistance = 0.0,
    this.ordersCount = 0,
    this.totalIncome = 0.0,
    this.totalExpenses = 0.0,
    this.netProfit = 0.0,
    this.shiftId,
    this.isOnOrder = false,
    this.orderStartTime,
    this.idleStartTime,
  });
  
  ShiftState copyWith({
    bool? isActive,
    bool? isPaused,
    bool? isCompleted,
    DateTime? shiftStartTime,
    DateTime? pausedAt,
    DateTime? resumedAt,
    Duration? totalWorkTime,
    Duration? totalIdleTime,
    Duration? totalOrderTime,
    double? totalPaidDistance,
    double? totalIdleDistance,
    double? processedIdleDistance,
    int? ordersCount,
    double? totalIncome,
    double? totalExpenses,
    double? netProfit,
    int? shiftId,
    bool? isOnOrder,
    DateTime? orderStartTime,
    DateTime? idleStartTime,
  }) {
    return ShiftState(
      isActive: isActive ?? this.isActive,
      isPaused: isPaused ?? this.isPaused,
      isCompleted: isCompleted ?? this.isCompleted,
      shiftStartTime: shiftStartTime ?? this.shiftStartTime,
      pausedAt: pausedAt ?? this.pausedAt,
      resumedAt: resumedAt ?? this.resumedAt,
      totalWorkTime: totalWorkTime ?? this.totalWorkTime,
      totalIdleTime: totalIdleTime ?? this.totalIdleTime,
      totalOrderTime: totalOrderTime ?? this.totalOrderTime,
      totalPaidDistance: totalPaidDistance ?? this.totalPaidDistance,
      totalIdleDistance: totalIdleDistance ?? this.totalIdleDistance,
      processedIdleDistance: processedIdleDistance ?? this.processedIdleDistance,
      ordersCount: ordersCount ?? this.ordersCount,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      netProfit: netProfit ?? this.netProfit,
      shiftId: shiftId ?? this.shiftId,
      isOnOrder: isOnOrder ?? this.isOnOrder,
      orderStartTime: orderStartTime ?? this.orderStartTime,
      idleStartTime: idleStartTime ?? this.idleStartTime,
    );
  }
  
  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  String get formattedWorkTime => formatDuration(currentWorkTime);
  String get formattedIdleTime => formatDuration(currentIdleTime);
  String get formattedOrderTime => formatDuration(currentOrderTime);
}

// ============================================================
// NOTIFIER
// ============================================================
class ShiftNotifier extends StateNotifier<ShiftState> {
  final Ref _ref;
  final ApiService _apiService = ApiService();
  GpsService? _gpsService;
  bool _isLoading = false;
  Timer? _timer;
  
  static const String _keyIdleTime = 'shift_idle_time_seconds';
  static const String _keyIdleDistance = 'shift_idle_distance';
  static const String _keyProcessedIdleDistance = 'shift_processed_idle_distance';
  static const String _keyOrdersCount = 'shift_orders_count';
  static const String _keyTotalIncome = 'shift_total_income';
  static const String _keyTotalExpenses = 'shift_total_expenses';
  static const String _keyNetProfit = 'shift_net_profit';
  static const String _keyTotalPaidDistance = 'shift_total_paid_distance';
  static const String _keyTotalOrderTime = 'shift_total_order_time_seconds';
  static const String _keyTotalWorkTime = 'shift_total_work_time_seconds';

  ShiftNotifier(this._ref) : super(const ShiftState()) {
    logMessage('🔵 [SHIFT] ShiftNotifier конструктор', category: 'SHIFT');
    _initGpsService();
    _loadFromCache();
    _startTimer();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Обновляем состояние только если смена активна или на паузе
      if (state.isActive && !state.isCompleted) {
        // Триггерим обновление UI через setState
        // Так как мы не храним состояние внутри виджета, просто пересчитываем геттеры
      }
    });
  }

  // ============================================================
  // ЗАГРУЗКА ДАННЫХ
  // ============================================================
  
  Future<void> _loadFromCache() async {
    logMessage('🔵 [SHIFT] _loadFromCache() начат', category: 'SHIFT');
    
    final cache = _apiService.cache;
    final savedState = await _loadSavedShiftState();
    final savedIdleSeconds = await _loadSavedIdleTime();
    final restoredIdleTime = Duration(seconds: savedIdleSeconds);
    
    logMessage('🔵 [SHIFT] cache.todayShifts.length=${cache.todayShifts.length}', category: 'SHIFT');
    logMessage('🔵 [SHIFT] cache.activeShift = ${cache.activeShift?.id ?? 'null'}, status=${cache.activeShift?.status ?? 'null'}', category: 'SHIFT');
    
    // ===== 1. ПРОВЕРЯЕМ ЕСТЬ ЛИ СМЕНА НА СЕРВЕРЕ =====
    if (cache.activeShift != null) {
      final shift = cache.activeShift!;
      logMessage('🔵 [SHIFT] Найдена смена на сервере: id=${shift.id}, status=${shift.status}', category: 'SHIFT');
      
      bool isPaused = shift.status == 'paused';
      bool isActive = shift.status == 'active' || shift.status == 'paused';
      
      // Восстанавливаем состояние из кэша
      state = state.copyWith(
        isActive: isActive,
        isPaused: isPaused,
        isCompleted: false,
        shiftStartTime: shift.startTime,
        shiftId: shift.id,
        totalPaidDistance: shift.totalPaidDistance,
        totalIdleDistance: shift.totalIdleDistance,
        ordersCount: shift.ordersCount,
        totalIncome: shift.totalIncome,
        totalExpenses: shift.totalExpenses,
        netProfit: shift.netProfit,
        totalWorkTime: savedState['totalWorkTime'] ?? Duration.zero,
        totalIdleTime: restoredIdleTime,
        totalOrderTime: savedState['totalOrderTime'] ?? Duration.zero,
        processedIdleDistance: savedState['processedIdleDistance'] ?? 0.0,
      );
      
      logMessage('📁 [SHIFT] Смена восстановлена: id=${shift.id}, статус=${shift.status}', category: 'SHIFT');
      
      // Если смена активна (не на паузе) — запускаем GPS
      if (!isPaused && isActive) {
        _startGpsTracking();
      } else {
        _stopGpsTracking();
      }
    } else {
      // ===== 2. НЕТ СМЕНЫ — СОЗДАЁМ НОВУЮ =====
      logMessage('🔵 [SHIFT] Нет активной смены на сервере, создаём новую', category: 'SHIFT');
      await _createPausedShift();
    }
    
    logMessage('🔵 [SHIFT] _loadFromCache() завершён', category: 'SHIFT');
  }
  
  Future<void> _createPausedShift() async {
  try {
    final shift = await _apiService.startShift();
    logMessage('📅 [SHIFT] Создана новая смена: id=${shift.id}, status=${shift.status}', category: 'SHIFT');
    
    // ===== ПРОВЕРЯЕМ СТАТУС =====
    bool isPaused = shift.status == 'paused';
    
    state = state.copyWith(
      isActive: true,
      isPaused: isPaused,
      isCompleted: false,
      shiftStartTime: shift.startTime,
      shiftId: shift.id,
      totalWorkTime: Duration.zero,
      totalIdleTime: Duration.zero,
      totalOrderTime: Duration.zero,
      totalPaidDistance: 0.0,
      totalIdleDistance: 0.0,
      processedIdleDistance: 0.0,
      ordersCount: 0,
      totalIncome: 0.0,
      totalExpenses: 0.0,
      netProfit: 0.0,
      isOnOrder: false,
      orderStartTime: null,
      idleStartTime: null,
    );
    
    // Если статус active — приостанавливаем сразу
    if (!isPaused) {
      logMessage('⚠️ [SHIFT] Смена создана со статусом active, приостанавливаем', category: 'SHIFT');
      await pauseShift();
    }
    
    await _saveShiftState();
  } catch (e) {
    logMessage('❌ [SHIFT] Ошибка создания смены: $e', category: 'SHIFT', level: LogLevel.error);
  }
}
  
  // ============================================================
  // СОХРАНЕНИЕ СОСТОЯНИЯ
  // ============================================================
  
  Future<void> _saveShiftState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyIdleDistance, state.totalIdleDistance);
      await prefs.setDouble(_keyProcessedIdleDistance, state.processedIdleDistance);
      await prefs.setInt(_keyOrdersCount, state.ordersCount);
      await prefs.setDouble(_keyTotalIncome, state.totalIncome);
      await prefs.setDouble(_keyTotalExpenses, state.totalExpenses);
      await prefs.setDouble(_keyNetProfit, state.netProfit);
      await prefs.setDouble(_keyTotalPaidDistance, state.totalPaidDistance);
      await prefs.setInt(_keyTotalOrderTime, state.totalOrderTime.inSeconds);
      await prefs.setInt(_keyTotalWorkTime, state.totalWorkTime.inSeconds);
      logMessage('🔵 [SHIFT] Состояние сохранено', category: 'SHIFT');
    } catch (e) {
      logMessage('⚠️ [SHIFT] Ошибка сохранения: $e', category: 'SHIFT');
    }
  }
  
  Future<Map<String, dynamic>> _loadSavedShiftState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'totalIdleDistance': prefs.getDouble(_keyIdleDistance) ?? 0.0,
        'processedIdleDistance': prefs.getDouble(_keyProcessedIdleDistance) ?? 0.0,
        'ordersCount': prefs.getInt(_keyOrdersCount) ?? 0,
        'totalIncome': prefs.getDouble(_keyTotalIncome) ?? 0.0,
        'totalExpenses': prefs.getDouble(_keyTotalExpenses) ?? 0.0,
        'netProfit': prefs.getDouble(_keyNetProfit) ?? 0.0,
        'totalPaidDistance': prefs.getDouble(_keyTotalPaidDistance) ?? 0.0,
        'totalOrderTime': Duration(seconds: prefs.getInt(_keyTotalOrderTime) ?? 0),
        'totalWorkTime': Duration(seconds: prefs.getInt(_keyTotalWorkTime) ?? 0),
      };
    } catch (e) {
      return {};
    }
  }
  
  Future<int> _loadSavedIdleTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyIdleTime) ?? 0;
    } catch (e) {
      return 0;
    }
  }
  
  Future<void> _saveIdleTime(Duration duration) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyIdleTime, duration.inSeconds);
    } catch (e) {}
  }

  // ============================================================
  // УПРАВЛЕНИЕ СМЕНОЙ
  // ============================================================
  
  /// Возобновить работу (из паузы)
  Future<void> resumeShift() async {
    if (_isLoading) return;
    if (!state.isActive || state.isCompleted) {
      logMessage('⚠️ [SHIFT] Нет активной смены', category: 'SHIFT');
      return;
    }
    if (!state.isPaused) {
      logMessage('⚠️ [SHIFT] Смена уже активна', category: 'SHIFT');
      return;
    }
    
    _isLoading = true;
    final now = DateTime.now();
    
    try {
      await _apiService.resumeShift(state.shiftId!);
      
      state = state.copyWith(
        isPaused: false,
        pausedAt: null,
        resumedAt: now,
        idleStartTime: now,
      );
      
      await _saveShiftState();
      _startGpsTracking();
      
      logMessage('▶️ [SHIFT] Работа возобновлена', category: 'SHIFT');
    } catch (e) {
      logMessage('❌ [SHIFT] Ошибка возобновления: $e', category: 'SHIFT', level: LogLevel.error);
    }
    
    _isLoading = false;
  }
  
  /// Приостановить работу
  Future<void> pauseShift() async {
    if (_isLoading) return;
    if (!state.isActive || state.isCompleted) {
      logMessage('⚠️ [SHIFT] Нет активной смены', category: 'SHIFT');
      return;
    }
    if (state.isPaused) {
      logMessage('⚠️ [SHIFT] Смена уже приостановлена', category: 'SHIFT');
      return;
    }
    
    _isLoading = true;
    final now = DateTime.now();
    
    try {
      Duration addedWork = Duration.zero;
      if (state.resumedAt != null) {
        addedWork = now.difference(state.resumedAt!);
      }
      
      Duration addedIdle = Duration.zero;
      if (state.idleStartTime != null) {
        addedIdle = now.difference(state.idleStartTime!);
      }
      
      await _apiService.pauseShift(
        state.shiftId!,
        addedWorkSeconds: addedWork.inSeconds,
        addedIdleSeconds: addedIdle.inSeconds,
        totalPaidDistance: state.totalPaidDistance,
        totalIdleDistance: state.totalIdleDistance,
        totalOrderTimeSeconds: state.totalOrderTime.inSeconds,
        ordersCount: state.ordersCount,
        totalIncome: state.totalIncome,
        totalExpenses: state.totalExpenses,
        netProfit: state.netProfit,
      );
      
      state = state.copyWith(
        isPaused: true,
        pausedAt: now,
        resumedAt: null,
        idleStartTime: null,
        totalWorkTime: state.totalWorkTime + addedWork,
        totalIdleTime: state.totalIdleTime + addedIdle,
      );
      
      await _saveShiftState();
      await _saveIdleTime(state.totalIdleTime);
      _stopGpsTracking();
      
      logMessage('⏸️ [SHIFT] Работа приостановлена', category: 'SHIFT');
    } catch (e) {
      logMessage('❌ [SHIFT] Ошибка приостановки: $e', category: 'SHIFT', level: LogLevel.error);
    }
    
    _isLoading = false;
  }
  
  /// Завершить смену (вызывается в 23:59 или вручную)
  Future<void> completeShift() async {
    if (_isLoading) return;
    if (!state.isActive || state.isCompleted) {
      logMessage('⚠️ [SHIFT] Нет активной смены', category: 'SHIFT');
      return;
    }
    
    _isLoading = true;
    
    try {
      if (!state.isPaused) {
        await pauseShift();
      }
      
      await _apiService.completeShift(
        state.shiftId!,
        totalPaidDistance: state.totalPaidDistance,
        totalIdleDistance: state.totalIdleDistance,
        totalOrderTimeSeconds: state.totalOrderTime.inSeconds,
        ordersCount: state.ordersCount,
        totalIncome: state.totalIncome,
        totalExpenses: state.totalExpenses,
        netProfit: state.netProfit,
      );
      
      state = state.copyWith(
        isActive: false,
        isPaused: false,
        isCompleted: true,
      );
      
      await _saveShiftState();
      _stopGpsTracking();
      
      logMessage('✅ [SHIFT] Смена завершена', category: 'SHIFT');
      
      // Создаём смену на новый день
      await _createPausedShift();
      
    } catch (e) {
      logMessage('❌ [SHIFT] Ошибка завершения: $e', category: 'SHIFT', level: LogLevel.error);
    }
    
    _isLoading = false;
  }
  
  // ============================================================
  // УПРАВЛЕНИЕ ЗАКАЗАМИ
  // ============================================================
  
  void startOrder() {
    if (!state.isActive || state.isPaused || state.isCompleted) {
      logMessage('⚠️ [SHIFT] Нельзя начать заказ', category: 'SHIFT');
      return;
    }
    if (state.isOnOrder) {
      logMessage('⚠️ [SHIFT] Заказ уже активен', category: 'SHIFT');
      return;
    }
    
    final now = DateTime.now();
    state = state.copyWith(
      isOnOrder: true,
      orderStartTime: now,
      idleStartTime: null,
    );
    _saveShiftState();
    logMessage('🟢 [SHIFT] Заказ начат', category: 'SHIFT');
  }
  
  void cancelOrder() {
    if (!state.isOnOrder) return;
    final now = DateTime.now();
    state = state.copyWith(
      isOnOrder: false,
      orderStartTime: null,
      idleStartTime: now,
    );
    _saveShiftState();
    logMessage('❌ [SHIFT] Заказ отменён', category: 'SHIFT');
  }
  
  void finishOrder({
    required double paidDistance,
    required double income,
    required double expenses,
    required Duration orderDuration,
  }) {
    if (!state.isOnOrder) {
      logMessage('⚠️ [SHIFT] Заказ не активен', category: 'SHIFT');
      return;
    }
    
    final now = DateTime.now();
    final orderTime = now.difference(state.orderStartTime!);
    
    final unprocessedIdle = state.totalIdleDistance - state.processedIdleDistance;
    final settings = _ref.read(settingsProvider);
    final idleCost = _calculateIdleCost(unprocessedIdle, settings);
    
    if (unprocessedIdle > 0) {
      logMessage('📊 [SHIFT] Списание холостого пробега: ${unprocessedIdle.toStringAsFixed(2)} км на сумму ${idleCost.toStringAsFixed(2)} руб', category: 'SHIFT');
    }
    
    state = state.copyWith(
      isOnOrder: false,
      orderStartTime: null,
      totalOrderTime: state.totalOrderTime + orderTime,
      totalPaidDistance: state.totalPaidDistance + paidDistance,
      ordersCount: state.ordersCount + 1,
      totalIncome: state.totalIncome + income,
      totalExpenses: state.totalExpenses + expenses + idleCost,
      netProfit: (state.totalIncome + income) - (state.totalExpenses + expenses + idleCost),
      idleStartTime: now,
      processedIdleDistance: state.totalIdleDistance,
    );
    
    _saveShiftState();
    logMessage('✅ [SHIFT] Заказ завершён', category: 'SHIFT');
  }
  
  // ============================================================
  // GPS
  // ============================================================
  
  void _initGpsService() {
    try {
      _gpsService = _ref.read(gpsServiceProvider);
      if (state.isActive && !state.isPaused && !state.isCompleted) {
        _gpsService!.startTracking();
      }
    } catch (e) {
      logMessage('⚠️ [SHIFT] GPS сервис не готов: $e', category: 'SHIFT');
    }
  }
  
  void _startGpsTracking() {
    logMessage('🟢 [SHIFT] Запуск GPS', category: 'SHIFT');
    if (_gpsService == null) {
      try {
        _gpsService = _ref.read(gpsServiceProvider);
      } catch (e) {
        logMessage('❌ [SHIFT] Не удалось получить GPS: $e', category: 'SHIFT', level: LogLevel.error);
        return;
      }
    }
    if (_gpsService != null) {
      _gpsService!.startTracking();
      logMessage('✅ [SHIFT] GPS запущен', category: 'SHIFT');
    }
  }
  
  void _stopGpsTracking() {
    if (_gpsService != null) {
      _gpsService!.stopTracking();
      logMessage('🛑 [SHIFT] GPS остановлен', category: 'SHIFT');
    }
  }
  
  void addIdleDistance(double distance) {
    if (!state.isActive || state.isPaused || state.isCompleted || state.isOnOrder) return;
    if (distance <= 0) return;
    
    state = state.copyWith(
      totalIdleDistance: state.totalIdleDistance + distance,
    );
    _saveShiftState();
    logMessage('🔄 [SHIFT] Холостой пробег: +$distance км (всего: ${state.totalIdleDistance})', category: 'SHIFT');
  }
  
  // ============================================================
  // ВСПОМОГАТЕЛЬНЫЕ
  // ============================================================
  
  double _calculateIdleCost(double idleKm, SettingsState settings) {
    if (idleKm <= 0) return 0.0;
    final fuelCostPerKm = (settings.fuelConsumption / 100) * settings.fuelPrice;
    final costPerKm = fuelCostPerKm + settings.repairCost;
    return idleKm * costPerKm;
  }
  
  Future<void> loadFromCache() async {
    await _loadFromCache();
  }
  
  bool get isLoading => _isLoading;
}

final shiftProvider = StateNotifierProvider<ShiftNotifier, ShiftState>((ref) {
  return ShiftNotifier(ref);
});