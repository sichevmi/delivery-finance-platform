import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/features/delivery/providers/gps_provider.dart';
import 'package:delivery_app/features/delivery/services/gps_service.dart';
import 'package:delivery_app/core/database/database_provider.dart';
import 'package:drift/drift.dart';
import 'package:delivery_app/features/delivery/providers/daily_stats_provider.dart';
import 'package:delivery_app/features/delivery/providers/sync_provider.dart';

class ShiftState {
  final bool isActive;
  final DateTime? shiftStartTime;
  final DateTime? shiftEndTime;
  final Duration totalWorkTime;

  final Duration totalIdleTime;
  final DateTime? idleStartTime;

  final bool isOnOrder;
  final DateTime? orderStartTime;
  final Duration totalOrderTime;

  final double totalPaidDistance;
  final double totalIdleDistance;

  final int ordersCount;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;

  final int lastTick;
  
  final int? localShiftId;

  const ShiftState({
    this.isActive = false,
    this.shiftStartTime,
    this.shiftEndTime,
    this.totalWorkTime = Duration.zero,
    this.totalIdleTime = Duration.zero,
    this.idleStartTime,
    this.isOnOrder = false,
    this.orderStartTime,
    this.totalOrderTime = Duration.zero,
    this.totalPaidDistance = 0.0,
    this.totalIdleDistance = 0.0,
    this.ordersCount = 0,
    this.totalIncome = 0.0,
    this.totalExpenses = 0.0,
    this.netProfit = 0.0,
    this.lastTick = 0,
    this.localShiftId,
  });

  ShiftState copyWith({
    bool? isActive,
    DateTime? shiftStartTime,
    DateTime? shiftEndTime,
    Duration? totalWorkTime,
    Duration? totalIdleTime,
    DateTime? idleStartTime,
    bool? isOnOrder,
    DateTime? orderStartTime,
    Duration? totalOrderTime,
    double? totalPaidDistance,
    double? totalIdleDistance,
    int? ordersCount,
    double? totalIncome,
    double? totalExpenses,
    double? netProfit,
    int? lastTick,
    int? localShiftId,
  }) {
    return ShiftState(
      isActive: isActive ?? this.isActive,
      shiftStartTime: shiftStartTime ?? this.shiftStartTime,
      shiftEndTime: shiftEndTime ?? this.shiftEndTime,
      totalWorkTime: totalWorkTime ?? this.totalWorkTime,
      totalIdleTime: totalIdleTime ?? this.totalIdleTime,
      idleStartTime: idleStartTime ?? this.idleStartTime,
      isOnOrder: isOnOrder ?? this.isOnOrder,
      orderStartTime: orderStartTime ?? this.orderStartTime,
      totalOrderTime: totalOrderTime ?? this.totalOrderTime,
      totalPaidDistance: totalPaidDistance ?? this.totalPaidDistance,
      totalIdleDistance: totalIdleDistance ?? this.totalIdleDistance,
      ordersCount: ordersCount ?? this.ordersCount,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      netProfit: netProfit ?? this.netProfit,
      lastTick: lastTick ?? this.lastTick,
      localShiftId: localShiftId ?? this.localShiftId,
    );
  }

  // ===== ВЫЧИСЛЯЕМЫЕ ПОЛЯ =====

  Duration get workTime {
    if (!isActive || shiftStartTime == null) {
      return totalWorkTime;
    }
    return totalWorkTime + DateTime.now().difference(shiftStartTime!);
  }

  Duration get currentIdlePeriod {
    if (!isActive) return Duration.zero;
    if (isOnOrder) return Duration.zero;
    if (idleStartTime == null) return Duration.zero;
    return DateTime.now().difference(idleStartTime!);
  }

  Duration get totalIdleTimeDisplay => totalIdleTime + currentIdlePeriod;

  Duration get currentOrderTime {
    if (!isOnOrder || orderStartTime == null) return Duration.zero;
    return DateTime.now().difference(orderStartTime!);
  }

  Duration get totalOrderTimeDisplay => totalOrderTime + currentOrderTime;

  Duration get avgTimePerOrder {
    if (ordersCount == 0) return Duration.zero;
    return Duration(
      milliseconds: (totalOrderTimeDisplay.inMilliseconds / ordersCount).round()
    );
  }

  String get formattedAvgTimePerOrder {
    final d = avgTimePerOrder;
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    if (minutes > 0 && seconds > 0) {
      return '$minutes мин $seconds сек';
    } else if (minutes > 0) {
      return '$minutes мин';
    } else {
      return '$seconds сек';
    }
  }

  double get totalDistance => totalPaidDistance + totalIdleDistance;
  double get avgDistancePerOrder => ordersCount > 0 ? totalPaidDistance / ordersCount : 0.0;
  double get avgCheck => ordersCount > 0 ? totalIncome / ordersCount : 0.0;

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedWorkTime => formatDuration(workTime);
  String get formattedIdleTime => formatDuration(totalIdleTimeDisplay);
}

class ShiftNotifier extends StateNotifier<ShiftState> {
  final Ref _ref;
  GpsService? _gpsService;

  ShiftNotifier(this._ref) : super(const ShiftState()) {
    _loadState();
    _initGpsService();
    _loadShiftFromDatabase();
  }

  // ===== ЗАГРУЗКА ИЗ БД =====

  Future<void> _loadShiftFromDatabase() async {
    try {
      final db = _ref.read(appDatabaseProvider);
      final savedShift = await db.shiftDao.getActiveShift();
      
      if (savedShift != null) {
        logMessage('📁 Загружена активная смена из БД: id=${savedShift.id}', category: 'SHIFT');
        logMessage('   startTime: ${savedShift.startTime}', category: 'SHIFT');
        logMessage('   totalPaidDistance: ${savedShift.totalPaidDistance}', category: 'SHIFT');
        logMessage('   ordersCount: ${savedShift.ordersCount}', category: 'SHIFT');
        
        if (!state.isActive) {
          state = state.copyWith(
            localShiftId: savedShift.id,
            isActive: savedShift.status == 'active',
            shiftStartTime: DateTime.tryParse(savedShift.startTime),
            shiftEndTime: savedShift.endTime != null ? DateTime.tryParse(savedShift.endTime!) : null,
            totalWorkTime: Duration(seconds: savedShift.durationSeconds),
            totalPaidDistance: savedShift.totalPaidDistance,
            totalIdleDistance: savedShift.totalIdleDistance,
            ordersCount: savedShift.ordersCount,
            totalIncome: savedShift.totalIncome,
            totalExpenses: savedShift.totalExpenses,
            netProfit: savedShift.netProfit,
            idleStartTime: savedShift.status == 'active' ? DateTime.now() : null,
          );
          
          if (state.isActive) {
            _startGpsTracking();
          }
          
          logMessage('✅ Состояние восстановлено из БД', category: 'SHIFT');
        }
      } else {
        logMessage('📁 Активная смена в БД не найдена', category: 'SHIFT');
      }
    } catch (e) {
      logMessage('⚠️ Ошибка загрузки смены из БД: $e', category: 'SHIFT', level: LogLevel.error);
    }
  }

  // ===== СОХРАНЕНИЕ В БД =====

  Future<void> _saveShiftToDatabase() async {
  try {
    final db = _ref.read(appDatabaseProvider);
    
    if (state.localShiftId != null) {
      final success = await db.shiftDao.updateShift(
        state.localShiftId!,
        startTime: state.shiftStartTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
        endTime: state.shiftEndTime?.toIso8601String(),
        durationSeconds: state.workTime.inSeconds,
        totalPaidDistance: state.totalPaidDistance,
        totalIdleDistance: state.totalIdleDistance,
        totalOrderTimeSeconds: state.totalOrderTimeDisplay.inSeconds,
        ordersCount: state.ordersCount,
        totalIncome: state.totalIncome,
        totalExpenses: state.totalExpenses,
        netProfit: state.netProfit,
        status: state.isActive ? 'active' : 'completed',
      );
      if (success) {
        logMessage('🔄 Смена ${state.localShiftId} обновлена в БД', category: 'SHIFT');
      }
    } else {
      final id = await db.shiftDao.insertShift(
        startTime: state.shiftStartTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
        endTime: state.shiftEndTime?.toIso8601String(),
        durationSeconds: state.workTime.inSeconds,
        totalPaidDistance: state.totalPaidDistance,
        totalIdleDistance: state.totalIdleDistance,
        totalOrderTimeSeconds: state.totalOrderTimeDisplay.inSeconds,
        ordersCount: state.ordersCount,
        totalIncome: state.totalIncome,
        totalExpenses: state.totalExpenses,
        netProfit: state.netProfit,
        status: state.isActive ? 'active' : 'completed',
      );
      state = state.copyWith(localShiftId: id);
      logMessage('💾 Смена $id сохранена в БД', category: 'SHIFT');
    }
  } catch (e) {
    logMessage('❌ Ошибка сохранения смены в БД: $e', category: 'SHIFT', level: LogLevel.error);
  }
}

  // ===== ЗАГРУЗКА ИЗ SHARED_PREFERENCES =====

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString('shift_last_date');
    final today = _getTodayKey();

    if (lastDate != today) {
      logMessage('🔄 Новая дата: $today, предыдущая: $lastDate', category: 'SHIFT');
      await _resetDay();
      return;
    }

    state = state.copyWith(
      isActive: prefs.getBool('shift_active') ?? false,
      shiftStartTime: _fromMillis(prefs.getInt('shift_start_time')),
      shiftEndTime: _fromMillis(prefs.getInt('shift_end_time')),
      totalWorkTime: Duration(seconds: prefs.getInt('shift_total_work_time') ?? 0),
      totalIdleTime: Duration(seconds: prefs.getInt('shift_idle_time') ?? 0),
      idleStartTime: _fromMillis(prefs.getInt('shift_idle_start')),
      isOnOrder: prefs.getBool('shift_on_order') ?? false,
      orderStartTime: _fromMillis(prefs.getInt('shift_order_start')),
      totalOrderTime: Duration(seconds: prefs.getInt('shift_total_order_time') ?? 0),
      totalPaidDistance: prefs.getDouble('shift_paid_distance') ?? 0.0,
      totalIdleDistance: prefs.getDouble('shift_idle_distance') ?? 0.0,
      ordersCount: prefs.getInt('shift_orders') ?? 0,
      totalIncome: prefs.getDouble('shift_income') ?? 0.0,
      totalExpenses: prefs.getDouble('shift_expenses') ?? 0.0,
      netProfit: prefs.getDouble('shift_net_profit') ?? 0.0,
      localShiftId: null,
    );

    if (state.isActive && !state.isOnOrder && state.idleStartTime == null) {
      state = state.copyWith(idleStartTime: DateTime.now());
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shift_last_date', _getTodayKey());
    await prefs.setBool('shift_active', state.isActive);
    
    if (state.shiftStartTime != null) {
      await prefs.setInt('shift_start_time', state.shiftStartTime!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('shift_start_time');
    }
    if (state.shiftEndTime != null) {
      await prefs.setInt('shift_end_time', state.shiftEndTime!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('shift_end_time');
    }
    await prefs.setInt('shift_total_work_time', state.totalWorkTime.inSeconds);
    await prefs.setInt('shift_idle_time', state.totalIdleTime.inSeconds);
    if (state.idleStartTime != null) {
      await prefs.setInt('shift_idle_start', state.idleStartTime!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('shift_idle_start');
    }
    await prefs.setBool('shift_on_order', state.isOnOrder);
    if (state.orderStartTime != null) {
      await prefs.setInt('shift_order_start', state.orderStartTime!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('shift_order_start');
    }
    await prefs.setInt('shift_total_order_time', state.totalOrderTime.inSeconds);
    await prefs.setDouble('shift_paid_distance', state.totalPaidDistance);
    await prefs.setDouble('shift_idle_distance', state.totalIdleDistance);
    await prefs.setInt('shift_orders', state.ordersCount);
    await prefs.setDouble('shift_income', state.totalIncome);
    await prefs.setDouble('shift_expenses', state.totalExpenses);
    await prefs.setDouble('shift_net_profit', state.netProfit);
  }

  Future<void> _resetDay() async {
  logMessage('🔄 Сброс дня: обнуление всех показателей', category: 'SHIFT');
  
  // Сбрасываем состояние смены
  state = const ShiftState();
  await _saveState();
  _stopGpsTracking();
  
  // Принудительно сбрасываем кеш дневной статистики
  _ref.invalidate(dailyStatsProvider);
  
  logMessage('✅ Дневная статистика сброшена', category: 'SHIFT');
}

  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  DateTime? _fromMillis(int? ms) => ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;

  // ===== УПРАВЛЕНИЕ GPS =====

  void _initGpsService() {
    try {
      _gpsService = _ref.read(gpsServiceProvider);
      logMessage('🟢 ShiftNotifier: GPS сервис получен', category: 'SHIFT');
      if (state.isActive) {
        _gpsService!.startTracking();
        logMessage('🟢 ShiftNotifier: GPS запущен (смена активна)', category: 'SHIFT');
      }
    } catch (e) {
      logMessage('⚠️ ShiftNotifier: GPS сервис ещё не готов: $e', category: 'SHIFT');
    }
  }

  void _startGpsTracking() {
    if (_gpsService == null) {
      try {
        _gpsService = _ref.read(gpsServiceProvider);
      } catch (e) {
        logMessage('⚠️ Не удалось получить GPS сервис: $e', category: 'SHIFT');
        return;
      }
    }
    if (_gpsService != null) {
      logMessage('🟢 Запускаем GPS трекинг (смена активна, isOnOrder=${state.isOnOrder})', category: 'SHIFT');
      _gpsService!.startTracking();
    } else {
      logMessage('⚠️ GpsService не найден', category: 'SHIFT');
    }
  }

  void _stopGpsTracking() {
    if (_gpsService != null) {
      logMessage('🛑 Останавливаем GPS трекинг (смена не активна)', category: 'SHIFT');
      _gpsService!.stopTracking();
    }
  }

  // ===== ОСНОВНЫЕ МЕТОДЫ =====

  void startShift() async {
  if (state.isActive) return;
  
  final db = _ref.read(appDatabaseProvider);
  final existingShift = await db.shiftDao.getActiveShift();
  
  if (existingShift != null) {
    logMessage('⚠️ Найдена активная смена в БД (id=${existingShift.id}), восстанавливаем', category: 'SHIFT');
    state = state.copyWith(
      localShiftId: existingShift.id,
      isActive: true,
      shiftStartTime: DateTime.tryParse(existingShift.startTime),
      shiftEndTime: existingShift.endTime != null ? DateTime.tryParse(existingShift.endTime!) : null,
      totalWorkTime: Duration(seconds: existingShift.durationSeconds),
      totalPaidDistance: existingShift.totalPaidDistance,
      totalIdleDistance: existingShift.totalIdleDistance,
      ordersCount: existingShift.ordersCount,
      totalIncome: existingShift.totalIncome,
      totalExpenses: existingShift.totalExpenses,
      netProfit: existingShift.netProfit,
      idleStartTime: DateTime.now(),
    );
    _saveState();
    _startGpsTracking();
    return;
  }
  
  final now = DateTime.now();
  state = state.copyWith(
    isActive: true,
    shiftStartTime: now,
    shiftEndTime: null,
    idleStartTime: now,
    localShiftId: null,
  );
  _saveState();
  _startGpsTracking();
  
  // 🔥 СОХРАНЯЕМ В БД
  await _saveShiftToDatabase();
  
  // 🔥 СИНХРОНИЗИРУЕМ АКТИВНУЮ СМЕНУ С СЕРВЕРОМ
  _syncActiveShift();
}

// ===== СИНХРОНИЗАЦИЯ АКТИВНОЙ СМЕНЫ =====

void _syncActiveShift() async {
  try {
    final syncService = _ref.read(syncServiceProvider);
    await syncService.syncActiveShift();
    logMessage('✅ Активная смена синхронизирована с сервером', category: 'SHIFT');
  } catch (e) {
    logMessage('⚠️ Ошибка синхронизации активной смены: $e', category: 'SHIFT', level: LogLevel.error);
  }
}

  void stopShift() {
    logMessage('🛑 stopShift() вызван', category: 'SHIFT');
    if (!state.isActive) return;
    final now = DateTime.now();
    final addedWork = now.difference(state.shiftStartTime!);
    final idleDuration = state.currentIdlePeriod;
    
    Duration addedOrderTime = Duration.zero;
    if (state.isOnOrder && state.orderStartTime != null) {
      addedOrderTime = now.difference(state.orderStartTime!);
    }

    state = state.copyWith(
      isActive: false,
      shiftStartTime: null,
      shiftEndTime: now,
      totalWorkTime: state.totalWorkTime + addedWork,
      totalIdleTime: state.totalIdleTime + idleDuration,
      idleStartTime: null,
      isOnOrder: false,
      orderStartTime: null,
      totalOrderTime: state.totalOrderTime + addedOrderTime,
    );
    _saveState();
    _stopGpsTracking();
    _saveShiftToDatabase();
    
    // ===== СИНХРОНИЗАЦИЯ ПОСЛЕ ЗАВЕРШЕНИЯ СМЕНЫ =====
    _syncAfterShift();
  }

  // ===== СИНХРОНИЗАЦИЯ ПОСЛЕ ЗАВЕРШЕНИЯ СМЕНЫ =====
  
  void _syncAfterShift() {
    try {
      final syncService = _ref.read(syncServiceProvider);
      syncService.syncAll().then((_) {
        logMessage('✅ Синхронизация после завершения смены выполнена', category: 'SHIFT');
      }).catchError((e) {
        logMessage('⚠️ Ошибка синхронизации после завершения смены: $e', category: 'SHIFT', level: LogLevel.error);
      });
    } catch (e) {
      logMessage('⚠️ Ошибка вызова синхронизации: $e', category: 'SHIFT', level: LogLevel.error);
    }
  }

  void startOrder() {
    if (!state.isActive || state.isOnOrder) return;
    final now = DateTime.now();
    final idleDuration = state.currentIdlePeriod;

    state = state.copyWith(
      isOnOrder: true,
      orderStartTime: now,
      totalIdleTime: state.totalIdleTime + idleDuration,
      idleStartTime: null,
    );
    _saveState();
    _saveShiftToDatabase();
  }

  void cancelOrder() {
    if (!state.isOnOrder) return;
    final now = DateTime.now();
    state = state.copyWith(
      isOnOrder: false,
      orderStartTime: null,
      idleStartTime: now,
    );
    _saveState();
    _saveShiftToDatabase();
  }

  void finishOrder({
    required double paidDistance,
    required double income,
    required double expenses,
    required Duration orderDuration,
  }) {
    if (!state.isOnOrder) return;
    final now = DateTime.now();
    final orderTime = now.difference(state.orderStartTime!);

    state = state.copyWith(
      isOnOrder: false,
      orderStartTime: null,
      totalOrderTime: state.totalOrderTime + orderTime,
      totalPaidDistance: state.totalPaidDistance + paidDistance,
      ordersCount: state.ordersCount + 1,
      totalIncome: state.totalIncome + income,
      totalExpenses: state.totalExpenses + expenses,
      netProfit: state.totalIncome + income - (state.totalExpenses + expenses),
      idleStartTime: now,
    );
    _saveState();
    _saveShiftToDatabase();
  }

  void addIdleDistance(double distance) {
    logMessage('📊 addIdleDistance вызван: distance=$distance, isActive=${state.isActive}, isOnOrder=${state.isOnOrder}', category: 'SHIFT');
    if (!state.isActive || state.isOnOrder || distance <= 0) return;
    state = state.copyWith(
      totalIdleDistance: state.totalIdleDistance + distance,
    );
    _saveState();
    _saveShiftToDatabase();
  }

  void updatePaidDistance(double distance) {
    // Этот метод больше не используется — платный пробег добавляется только через finishOrder
  }

  // ===== ТАЙМЕР =====
  
  void tick() {
  
  }

  void resetDay() {
    _resetDay();
  }
}

final shiftProvider = StateNotifierProvider<ShiftNotifier, ShiftState>((ref) {
  return ShiftNotifier(ref);
});