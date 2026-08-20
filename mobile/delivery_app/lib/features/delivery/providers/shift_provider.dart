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
  final bool isActive;
  final bool isPaused;
  final bool isCompleted;
  final DateTime? shiftStartTime;
  final DateTime? pausedAt;
  final DateTime? resumedAt;
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
  final bool isOnOrder;
  final DateTime? orderStartTime;
  final DateTime? idleStartTime;
  
  // ===== ВЫЧИСЛЯЕМЫЕ ПОЛЯ =====
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
  Timer? _autoSaveTimer;
  
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
  static const String _keyShiftId = 'shift_id';
  static const String _keyIsActive = 'shift_is_active';
  static const String _keyIsPaused = 'shift_is_paused';
  static const String _keyResumedAt = 'shift_resumed_at';

  ShiftNotifier(this._ref) : super(const ShiftState()) {
    logMessage('🔵 [SHIFT] ShiftNotifier конструктор', category: 'SHIFT');
    _initGpsService();
    _loadFromCache();
    _startTimer();
    _startAutoSave();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    super.dispose();
  }
  
  // ===== ТАЙМЕР ДЛЯ ОБНОВЛЕНИЯ UI =====
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isActive && !state.isPaused && !state.isCompleted) {
        // Обновляем состояние только для пересчёта времени
      }
    });
  }
  
  // ===== АВТОСОХРАНЕНИЕ КАЖДЫЕ 30 СЕКУНД =====
  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (state.isActive && !state.isCompleted) {
        _saveShiftState();
        _syncShiftToServer();
        logMessage('💾 [SHIFT] Автосохранение выполнено', category: 'SHIFT');
      }
    });
  }

  // ===== СИНХРОНИЗАЦИЯ С СЕРВЕРОМ =====
  Future<void> _syncShiftToServer() async {
  if (!state.isActive || state.isCompleted || state.shiftId == null) return;
  if (_isLoading) return;
  
  try {
    final currentWorkSeconds = state.currentWorkTime.inSeconds;
    
    logMessage('🔄 [API] Обновление состояния смены ${state.shiftId}, workTime=$currentWorkSeconds сек', category: 'API');
    
    await _apiService.updateShiftState(
      state.shiftId!,
      durationSeconds: currentWorkSeconds,  // <-- ДОБАВЛЯЕМ
      totalPaidDistance: _roundToTwo(state.totalPaidDistance),
      totalIdleDistance: _roundToTwo(state.totalIdleDistance),
      totalOrderTimeSeconds: state.totalOrderTime.inSeconds,
      ordersCount: state.ordersCount,
      totalIncome: _roundToTwo(state.totalIncome),
      totalExpenses: _roundToTwo(state.totalExpenses),
      netProfit: _roundToTwo(state.netProfit),
    );
    logMessage('✅ [API] Состояние смены обновлено', category: 'API');
  } catch (e) {
    logMessage('⚠️ [SHIFT] Ошибка синхронизации: $e', category: 'SHIFT');
  }
}

  // ===== ВСПОМОГАТЕЛЬНЫЙ МЕТОД ОКРУГЛЕНИЯ =====
  static double _roundToTwo(double value) {
    return double.parse(value.toStringAsFixed(2));
  }

  // ============================================================
  // ЗАГРУЗКА ДАННЫХ
  // ============================================================
  
  // В _loadFromCache() исправляем логику определения статуса:

Future<void> _loadFromCache() async {
  logMessage('🔵 [SHIFT] _loadFromCache() начат', category: 'SHIFT');
  
  final cache = _apiService.cache;
  final savedState = await _loadSavedShiftState();
  final savedIdleSeconds = await _loadSavedIdleTime();
  final restoredIdleTime = Duration(seconds: savedIdleSeconds);
  
  logMessage('🔵 [SHIFT] cache.todayShifts.length=${cache.todayShifts.length}', category: 'SHIFT');
  logMessage('🔵 [SHIFT] cache.activeShift = ${cache.activeShift?.id ?? 'null'}, status=${cache.activeShift?.status ?? 'null'}', category: 'SHIFT');
  
  if (cache.activeShift != null) {
    final shift = cache.activeShift!;
    logMessage('🔵 [SHIFT] Найдена смена на сервере: id=${shift.id}, status=${shift.status}', category: 'SHIFT');
    
    // ===== ПРАВИЛЬНО ОПРЕДЕЛЯЕМ СТАТУС =====
    // Статусы: 'active' - активна, 'paused' - на паузе, 'completed' - завершена
    bool isCompleted = shift.status == 'completed';
    bool isActive = !isCompleted && (shift.status == 'active' || shift.status == 'paused');
    bool isPaused = shift.status == 'paused';
    
    logMessage('🔵 [SHIFT] Определены статусы: isActive=$isActive, isPaused=$isPaused, isCompleted=$isCompleted', category: 'SHIFT');
    
    // Используем сохранённое состояние если ID совпадает
    final savedShiftId = savedState['shiftId'] as int?;
    bool useSavedData = savedShiftId != null && savedShiftId == shift.id;
    
    if (useSavedData) {
      logMessage('🔵 [SHIFT] Используем сохранённые данные из SharedPreferences', category: 'SHIFT');
    }
    
    state = state.copyWith(
      isActive: isActive,
      isPaused: isPaused,
      isCompleted: isCompleted,
      shiftStartTime: shift.startTime,
      shiftId: shift.id,
      totalPaidDistance: useSavedData ? (savedState['totalPaidDistance'] ?? 0.0) : shift.totalPaidDistance,
      totalIdleDistance: useSavedData ? (savedState['totalIdleDistance'] ?? 0.0) : shift.totalIdleDistance,
      ordersCount: useSavedData ? (savedState['ordersCount'] ?? 0) : shift.ordersCount,
      totalIncome: useSavedData ? (savedState['totalIncome'] ?? 0.0) : shift.totalIncome,
      totalExpenses: useSavedData ? (savedState['totalExpenses'] ?? 0.0) : shift.totalExpenses,
      netProfit: useSavedData ? (savedState['netProfit'] ?? 0.0) : shift.netProfit,
      totalWorkTime: savedState['totalWorkTime'] ?? Duration.zero,
      totalIdleTime: restoredIdleTime,
      totalOrderTime: savedState['totalOrderTime'] ?? Duration.zero,
      processedIdleDistance: savedState['processedIdleDistance'] ?? 0.0,
      // Если смена активна (не на паузе) — устанавливаем resumedAt
      resumedAt: (isActive && !isPaused && !isCompleted) ? DateTime.now() : null,
      idleStartTime: (isActive && !isPaused && !isCompleted) ? DateTime.now() : null,
    );
    
    logMessage('📁 [SHIFT] Смена восстановлена: id=${shift.id}, статус=${shift.status}, isPaused=${state.isPaused}', category: 'SHIFT');
    
    // ===== ЗАПУСКАЕМ GPS И ТАЙМЕРЫ В ЗАВИСИМОСТИ ОТ СТАТУСА =====
    if (isActive && !isPaused && !isCompleted) {
      logMessage('🟢 [SHIFT] Смена активна, запускаем GPS и таймер', category: 'SHIFT');
      _startGpsTracking();
      _startTimer();
    } else if (isActive && isPaused) {
      logMessage('⏸️ [SHIFT] Смена на паузе, GPS не запускаем', category: 'SHIFT');
      _stopGpsTracking();
      _timer?.cancel();
    } else {
      logMessage('⏹️ [SHIFT] Смена завершена или неактивна', category: 'SHIFT');
      _stopGpsTracking();
      _timer?.cancel();
    }
  } else {
    logMessage('🔵 [SHIFT] Нет активной смены на сервере, создаём новую', category: 'SHIFT');
    await _createPausedShift();
  }
  
  logMessage('🔵 [SHIFT] _loadFromCache() завершён', category: 'SHIFT');
}
  
  Future<void> _createPausedShift() async {
  try {
    final shift = await _apiService.startShift();
    logMessage('📅 [SHIFT] Создана новая смена: id=${shift.id}, status=${shift.status}', category: 'SHIFT');
    
    bool isPaused = shift.status == 'paused' || shift.status == 'active';
    
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
      resumedAt: null,
    );
    
    await _saveShiftState();
    await _syncShiftToServer();
    
    logMessage('✅ [SHIFT] Новая смена создана, статус=${state.isPaused ? "paused" : "active"}', category: 'SHIFT');
  } catch (e) {
    logMessage('❌ [SHIFT] Ошибка создания смены: $e', category: 'SHIFT', level: LogLevel.error);
  }
}
  
  // ============================================================
  // СОХРАНЕНИЕ СОСТОЯНИЯ В SHARED_PREFERENCES
  // ============================================================
  
  Future<void> _saveShiftState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyIdleDistance, _roundToTwo(state.totalIdleDistance));
      await prefs.setDouble(_keyProcessedIdleDistance, _roundToTwo(state.processedIdleDistance));
      await prefs.setInt(_keyOrdersCount, state.ordersCount);
      await prefs.setDouble(_keyTotalIncome, _roundToTwo(state.totalIncome));
      await prefs.setDouble(_keyTotalExpenses, _roundToTwo(state.totalExpenses));
      await prefs.setDouble(_keyNetProfit, _roundToTwo(state.netProfit));
      await prefs.setDouble(_keyTotalPaidDistance, _roundToTwo(state.totalPaidDistance));
      await prefs.setInt(_keyTotalOrderTime, state.totalOrderTime.inSeconds);
      await prefs.setInt(_keyTotalWorkTime, state.totalWorkTime.inSeconds);
      await prefs.setInt(_keyShiftId, state.shiftId ?? -1);
      await prefs.setBool(_keyIsActive, state.isActive);
      await prefs.setBool(_keyIsPaused, state.isPaused);
      if (state.resumedAt != null) {
        await prefs.setString(_keyResumedAt, state.resumedAt!.toIso8601String());
      }
      logMessage('🔵 [SHIFT] Состояние сохранено в SharedPreferences', category: 'SHIFT');
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
        'shiftId': prefs.getInt(_keyShiftId),
        'isActive': prefs.getBool(_keyIsActive) ?? false,
        'isPaused': prefs.getBool(_keyIsPaused) ?? true,
        'resumedAt': prefs.getString(_keyResumedAt),
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
      logMessage('🔄 [SHIFT] Отправка запроса на возобновление...', category: 'SHIFT');
      await _apiService.resumeShift(state.shiftId!);
      
      state = state.copyWith(
        isPaused: false,
        pausedAt: null,
        resumedAt: now,
        idleStartTime: now,
      );
      
      await _saveShiftState();
      await _syncShiftToServer();
      _startGpsTracking();
      _startTimer();
      
      logMessage('▶️ [SHIFT] Работа возобновлена', category: 'SHIFT');
    } catch (e) {
      logMessage('❌ [SHIFT] Ошибка возобновления: $e', category: 'SHIFT', level: LogLevel.error);
    }
    
    _isLoading = false;
  }
  
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
        logMessage('📊 [SHIFT] Добавлено время работы: ${addedWork.inSeconds} сек', category: 'SHIFT');
      }
      
      Duration addedIdle = Duration.zero;
      if (state.idleStartTime != null) {
        addedIdle = now.difference(state.idleStartTime!);
        logMessage('📊 [SHIFT] Добавлено время простоя: ${addedIdle.inSeconds} сек', category: 'SHIFT');
      }
      
      await _apiService.pauseShift(
        state.shiftId!,
        durationSeconds: state.currentWorkTime.inSeconds,  // <-- ДОБАВЛЯЕМ
        addedWorkSeconds: addedWork.inSeconds,
        addedIdleSeconds: addedIdle.inSeconds,
        totalPaidDistance: _roundToTwo(state.totalPaidDistance),
        totalIdleDistance: _roundToTwo(state.totalIdleDistance),
        totalOrderTimeSeconds: state.totalOrderTime.inSeconds,
        ordersCount: state.ordersCount,
        totalIncome: _roundToTwo(state.totalIncome),
        totalExpenses: _roundToTwo(state.totalExpenses),
        netProfit: _roundToTwo(state.netProfit),
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
      await _syncShiftToServer();
      _stopGpsTracking();
      _timer?.cancel();
      
      logMessage('⏸️ [SHIFT] Работа приостановлена', category: 'SHIFT');
    } catch (e) {
      logMessage('❌ [SHIFT] Ошибка приостановки: $e', category: 'SHIFT', level: LogLevel.error);
    }
    
    _isLoading = false;
  }
  
  Future<void> completeShift() async {
    if (_isLoading) return;
    if (!state.isActive || state.isCompleted) {
      logMessage('⚠️ [SHIFT] Нет активной смены', category: 'SHIFT');
      return;
    }
    
    _isLoading = true;
    
    try {
      // Сначала синхронизируем последние данные
      await _syncShiftToServer();
      
      if (!state.isPaused) {
        await pauseShift();
      }
      
      await _apiService.completeShift(
        state.shiftId!,
        durationSeconds: state.totalWorkTime.inSeconds,  // <-- ДОБАВЛЯЕМ
        totalPaidDistance: _roundToTwo(state.totalPaidDistance),
        totalIdleDistance: _roundToTwo(state.totalIdleDistance),
        totalOrderTimeSeconds: state.totalOrderTime.inSeconds,
        ordersCount: state.ordersCount,
        totalIncome: _roundToTwo(state.totalIncome),
        totalExpenses: _roundToTwo(state.totalExpenses),
        netProfit: _roundToTwo(state.netProfit),
      );
      
      state = state.copyWith(
        isActive: false,
        isPaused: false,
        isCompleted: true,
      );
      
      await _saveShiftState();
      _stopGpsTracking();
      _timer?.cancel();
      _autoSaveTimer?.cancel();
      
      await _apiService.loadAllData();
      
      logMessage('✅ [SHIFT] Смена завершена', category: 'SHIFT');
      
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
  
  // ===== ВАЖНО: ФИКСИРУЕМ ВРЕМЯ ПРОСТОЯ =====
  // Добавляем текущий период простоя к общему времени простоя
  Duration addedIdle = Duration.zero;
  if (state.idleStartTime != null) {
    addedIdle = now.difference(state.idleStartTime!);
    logMessage('📊 [SHIFT] Добавлено время простоя перед заказом: ${addedIdle.inSeconds} сек', category: 'SHIFT');
  }
  
  state = state.copyWith(
    isOnOrder: true,
    orderStartTime: now,
    idleStartTime: null,  // Останавливаем подсчёт простоя
    totalIdleTime: state.totalIdleTime + addedIdle,  // Сохраняем накопленное время простоя
  );
  
  _saveShiftState();
  logMessage('🟢 [SHIFT] Заказ начат, isOnOrder=${state.isOnOrder}', category: 'SHIFT');
}

void cancelOrder() {
  if (!state.isOnOrder) return;
  final now = DateTime.now();
  state = state.copyWith(
    isOnOrder: false,
    orderStartTime: null,
    idleStartTime: now,  // Возобновляем подсчёт простоя
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
  
  // ===== РАСЧЁТ ХОЛОСТОГО ПРОБЕГА =====
  final unprocessedIdle = _roundToTwo(state.totalIdleDistance - state.processedIdleDistance);
  final settings = _ref.read(settingsProvider);
  final idleCost = _roundToTwo(_calculateIdleCost(unprocessedIdle, settings));
  
  if (unprocessedIdle > 0) {
    logMessage('📊 [SHIFT] Списание холостого пробега: ${unprocessedIdle.toStringAsFixed(2)} км на сумму ${idleCost.toStringAsFixed(2)} руб', category: 'SHIFT');
  }
  
  // ===== ОБНОВЛЯЕМ СОСТОЯНИЕ =====
  final newTotalExpenses = _roundToTwo(state.totalExpenses + expenses + idleCost);
  final newNetProfit = _roundToTwo((state.totalIncome + income) - newTotalExpenses);
  final newTotalPaidDistance = _roundToTwo(state.totalPaidDistance + paidDistance);
  final newTotalOrderTime = state.totalOrderTime + orderTime;
  
  state = state.copyWith(
    isOnOrder: false,
    orderStartTime: null,
    totalOrderTime: newTotalOrderTime,
    totalPaidDistance: newTotalPaidDistance,
    ordersCount: state.ordersCount + 1,
    totalIncome: _roundToTwo(state.totalIncome + income),
    totalExpenses: newTotalExpenses,
    netProfit: newNetProfit,
    idleStartTime: now,
    processedIdleDistance: state.totalIdleDistance,
  );
  
  // ===== СОХРАНЯЕМ ЛОКАЛЬНО =====
  _saveShiftState();
  
  // ===== ОБНОВЛЯЕМ НА СЕРВЕРЕ =====
  _syncShiftToServer();
  
  // ===== ВАЖНО: ПЕРЕЗАГРУЖАЕМ ДАННЫЕ С СЕРВЕРА =====
  // Это нужно, чтобы получить актуальные данные из базы
  // и избежать дублирования
  _apiService.loadAllData().then((_) {
    logMessage('📊 [SHIFT] Данные перезагружены после завершения заказа', category: 'SHIFT');
  }).catchError((e) {
    logMessage('⚠️ [SHIFT] Ошибка перезагрузки данных: $e', category: 'SHIFT');
  });
  
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
    
    logMessage('🔄 [SHIFT] Добавление холостого пробега: $distance км', category: 'SHIFT');
    
    final settings = _ref.read(settingsProvider);
    final fuelCostPerKm = (settings.fuelConsumption / 100) * settings.fuelPrice;
    final costPerKm = fuelCostPerKm + settings.repairCost;
    final idleCost = _roundToTwo(distance * costPerKm);
    final newTotalIdleDistance = _roundToTwo(state.totalIdleDistance + distance);
    final newTotalExpenses = _roundToTwo(state.totalExpenses + idleCost);
    final newNetProfit = _roundToTwo(state.totalIncome - newTotalExpenses);
    
    state = state.copyWith(
      totalIdleDistance: newTotalIdleDistance,
      totalExpenses: newTotalExpenses,
      netProfit: newNetProfit,
    );
    
    // ===== СОХРАНЯЕМ И СИНХРОНИЗИРУЕМ =====
    _saveShiftState();
    _syncShiftToServer();
    
    logMessage('🔄 [SHIFT] Холостой пробег: +$distance км (всего: ${state.totalIdleDistance})', category: 'SHIFT');
    logMessage('🔄 [SHIFT] Расходы: +$idleCost руб (всего: ${state.totalExpenses})', category: 'SHIFT');
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