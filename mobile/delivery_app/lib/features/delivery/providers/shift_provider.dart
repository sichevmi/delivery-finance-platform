import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/core/services/api_service.dart';
import 'package:delivery_app/features/delivery/providers/gps_provider.dart';
import 'package:delivery_app/features/delivery/providers/settings_provider.dart';
import 'package:delivery_app/features/delivery/services/gps_service.dart';
import 'package:delivery_app/features/delivery/models/shift.dart';

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
  
  double get loadFactor {
    final total = currentWorkTime.inSeconds;
    final order = currentOrderTime.inSeconds;
    if (total == 0) return 0.0;
    return (order / total) * 100;
  }
  
  double get ordersPerHour {
    final hours = currentWorkTime.inSeconds / 3600.0;
    if (hours == 0) return 0.0;
    return ordersCount / hours;
  }
  
  double get efficiency {
    final hours = currentWorkTime.inSeconds / 3600.0;
    if (hours == 0) return 0.0;
    return netProfit / hours;
  }
  
  String get formattedLoadFactor => '${loadFactor.toStringAsFixed(0)}%';
  String get formattedOrdersPerHour => ordersPerHour.toStringAsFixed(1);
  String get formattedEfficiency => efficiency.toStringAsFixed(0);
  
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
  bool _isCompleting = false;
  Timer? _timer;
  Timer? _autoSaveTimer;
  Timer? _midnightCheckTimer;
  bool _isInitialized = false;
  
  ShiftNotifier(this._ref) : super(const ShiftState()) {
    logMessage('🔵 [SHIFT] ShiftNotifier конструктор', category: 'SHIFT');
    _initGpsService();
    _startTimer();
    _startAutoSave();
    _startMidnightCheck();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    _midnightCheckTimer?.cancel();
    super.dispose();
  }
  
  // ===== ПРОВЕРКА СМЕНЫ ДНЯ (КАЖДУЮ МИНУТУ) =====
  void _startMidnightCheck() {
    _midnightCheckTimer?.cancel();
    _midnightCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkDayChange();
    });
    logMessage('🔄 [SHIFT] Запущена проверка смены дня (каждую минуту)', category: 'SHIFT');
  }

  Future<void> _checkDayChange() async {
    if (_isCompleting) return;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if ((state.isActive || state.isPaused) && !state.isCompleted && state.shiftStartTime != null) {
      final shiftDate = DateTime(
        state.shiftStartTime!.year,
        state.shiftStartTime!.month,
        state.shiftStartTime!.day,
      );
      
      if (shiftDate.isBefore(today)) {
        logMessage('🔄 [SHIFT] Обнаружена смена за предыдущий день (${shiftDate.toLocal()}), автоматически завершаем...', category: 'SHIFT');
        _isCompleting = true;
        await _completePreviousShift();
        _isCompleting = false;
      }
    }
  }

  Future<void> _completePreviousShift() async {
    if (_isLoading) return;
    _isLoading = true;
    
    try {
      logMessage('🔄 [SHIFT] Начинаем автоматическое завершение смены за предыдущий день', category: 'SHIFT');
      
      // Синхронизируем данные
      await _syncShiftToServer();
      
      // Завершаем смену с ТЕКУЩИМИ данными
      if (state.isActive && !state.isCompleted) {
        await _apiService.completeShift(
          state.shiftId!,
          durationSeconds: state.totalWorkTime.inSeconds,
          totalPaidDistance: _roundToTwo(state.totalPaidDistance),
          totalIdleDistance: _roundToTwo(state.totalIdleDistance),
          totalOrderTimeSeconds: state.totalOrderTime.inSeconds,
          ordersCount: state.ordersCount,
          totalIncome: _roundToTwo(state.totalIncome),
          totalExpenses: _roundToTwo(state.totalExpenses),
          netProfit: _roundToTwo(state.netProfit),
        );
        
        // Помечаем как завершённую, НЕ сбрасываем данные
        state = state.copyWith(
          isCompleted: true,
          isActive: false,
          isPaused: false,
        );
        
        logMessage('✅ [SHIFT] Смена за предыдущий день завершена', category: 'SHIFT');
        
        // Останавливаем GPS
        _stopGpsTracking();
        _timer?.cancel();
        
        // Создаём новую смену (данные сбросятся на нули)
        await _createPausedShift();
      }
      
    } catch (e) {
      logMessage('⚠️ [SHIFT] Ошибка при автоматическом завершении смены: $e', category: 'SHIFT', level: LogLevel.error);
    }
    
    _isLoading = false;
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
        durationSeconds: currentWorkSeconds,
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
  // ЗАГРУЗКА ДАННЫХ (только с сервера, без локального кэша)
  // ============================================================
  
  Future<void> _loadFromCache() async {
    if (_isInitialized) return;
    _isInitialized = true;
    
    logMessage('🔵 [SHIFT] _loadFromCache() начат', category: 'SHIFT');
    
    final cache = _apiService.cache;
    
    logMessage('🔵 [SHIFT] cache.todayShifts.length=${cache.todayShifts.length}', category: 'SHIFT');
    logMessage('🔵 [SHIFT] cache.activeShift = ${cache.activeShift?.id ?? 'null'}, status=${cache.activeShift?.status ?? 'null'}', category: 'SHIFT');
    
    if (cache.activeShift != null) {
      final shift = cache.activeShift!;
      logMessage('🔵 [SHIFT] Найдена смена на сервере: id=${shift.id}, status=${shift.status}', category: 'SHIFT');
      
      bool isCompleted = shift.status == 'completed';
      bool isActive = !isCompleted && (shift.status == 'active' || shift.status == 'paused');
      bool isPaused = shift.status == 'paused';
      
      logMessage('🔵 [SHIFT] Определены статусы: isActive=$isActive, isPaused=$isPaused, isCompleted=$isCompleted', category: 'SHIFT');
      
      // ===== ВСЕГДА используем данные из БАЗЫ (через cache) =====
      state = state.copyWith(
        isActive: isActive,
        isPaused: isPaused,
        isCompleted: isCompleted,
        shiftStartTime: shift.startTime,
        shiftId: shift.id,
        totalPaidDistance: shift.totalPaidDistance ?? 0.0,
        totalIdleDistance: shift.totalIdleDistance ?? 0.0,
        ordersCount: shift.ordersCount ?? 0,
        totalIncome: shift.totalIncome ?? 0.0,
        totalExpenses: shift.totalExpenses ?? 0.0,
        netProfit: shift.netProfit ?? 0.0,
        totalWorkTime: Duration(seconds: shift.durationSeconds ?? 0),
        totalIdleTime: Duration.zero,
        totalOrderTime: Duration(seconds: shift.totalOrderTimeSeconds ?? 0),
        processedIdleDistance: 0.0,
        resumedAt: (isActive && !isPaused && !isCompleted) ? DateTime.now() : null,
        idleStartTime: (isActive && !isPaused && !isCompleted) ? DateTime.now() : null,
      );
      
      logMessage('📁 [SHIFT] Смена восстановлена: id=${shift.id}, статус=${shift.status}, workTime=${state.totalWorkTime.inSeconds} сек', category: 'SHIFT');
      
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
      logMessage('📅 [SHIFT] Создаём новую смену...', category: 'SHIFT');
      
      // Проверяем кэш (данные уже загружены)
      if (_apiService.cache.activeShift != null) {
        logMessage('⚠️ [SHIFT] Смена уже существует на сервере: id=${_apiService.cache.activeShift!.id}', category: 'SHIFT');
        return;
      }
      
      final shift = await _apiService.startShift();
      logMessage('📅 [SHIFT] Создана новая смена: id=${shift.id}, status=${shift.status}', category: 'SHIFT');
      
      bool isPaused = shift.status == 'paused' || shift.status == 'active';
      
      // Сбрасываем state на нули для новой смены
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
      
      // Обновляем кэш (новая смена теперь активна)
      await _apiService.loadAllData();
      
      logMessage('✅ [SHIFT] Новая смена создана, статус=paused', category: 'SHIFT');
    } catch (e) {
      logMessage('❌ [SHIFT] Ошибка создания смены: $e', category: 'SHIFT', level: LogLevel.error);
    }
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
        durationSeconds: state.currentWorkTime.inSeconds,
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
      // Синхронизируем данные
      await _syncShiftToServer();
      
      // Завершаем смену с ТЕКУЩИМИ данными
      await _apiService.completeShift(
        state.shiftId!,
        durationSeconds: state.totalWorkTime.inSeconds,
        totalPaidDistance: _roundToTwo(state.totalPaidDistance),
        totalIdleDistance: _roundToTwo(state.totalIdleDistance),
        totalOrderTimeSeconds: state.totalOrderTime.inSeconds,
        ordersCount: state.ordersCount,
        totalIncome: _roundToTwo(state.totalIncome),
        totalExpenses: _roundToTwo(state.totalExpenses),
        netProfit: _roundToTwo(state.netProfit),
      );
      
      // Помечаем как завершённую, НЕ сбрасываем данные
      state = state.copyWith(
        isActive: false,
        isPaused: false,
        isCompleted: true,
      );
      
      _stopGpsTracking();
      _timer?.cancel();
      _autoSaveTimer?.cancel();
      
      logMessage('✅ [SHIFT] Смена завершена', category: 'SHIFT');
      
      // Создаём новую смену
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
    
    Duration addedIdle = Duration.zero;
    if (state.idleStartTime != null) {
      addedIdle = now.difference(state.idleStartTime!);
      logMessage('📊 [SHIFT] Добавлено время простоя перед заказом: ${addedIdle.inSeconds} сек', category: 'SHIFT');
    }
    
    state = state.copyWith(
      isOnOrder: true,
      orderStartTime: now,
      idleStartTime: null,
      totalIdleTime: state.totalIdleTime + addedIdle,
    );
    
    logMessage('🟢 [SHIFT] Заказ начат, isOnOrder=${state.isOnOrder}', category: 'SHIFT');
  }

  void cancelOrder() {
    if (!state.isOnOrder) return;
    final now = DateTime.now();
    state = state.copyWith(
      isOnOrder: false,
      orderStartTime: null,
      idleStartTime: now,
    );
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
    
    final unprocessedIdle = _roundToTwo(state.totalIdleDistance - state.processedIdleDistance);
    final settings = _ref.read(settingsProvider);
    final idleCost = _roundToTwo(_calculateIdleCost(unprocessedIdle, settings));
    
    if (unprocessedIdle > 0) {
      logMessage('📊 [SHIFT] Списание холостого пробега: ${unprocessedIdle.toStringAsFixed(2)} км на сумму ${idleCost.toStringAsFixed(2)} руб', category: 'SHIFT');
    }
    
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
    
    _syncShiftToServer();
    
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