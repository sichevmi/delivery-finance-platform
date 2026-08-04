// lib/features/delivery/providers/shift_provider.dart
import 'package:flutter/material.dart'; // <-- ДОБАВЛЕНО
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/features/delivery/providers/gps_provider.dart';
import 'package:delivery_app/features/delivery/services/gps_service.dart';

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
    // Инициализируем GPS после загрузки состояния
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initGpsService();
    });
  }

  void _initGpsService() {
    try {
      _gpsService = _ref.read(gpsServiceProvider);
      print('🟢 ShiftNotifier: GPS сервис получен');
      if (state.isActive) {
        _gpsService!.startTracking();
        print('🟢 ShiftNotifier: GPS запущен (смена активна)');
      }
    } catch (e) {
      print('⚠️ ShiftNotifier: GPS сервис ещё не готов: $e');
    }
  }

  // ===== ЗАГРУЗКА И СОХРАНЕНИЕ =====

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString('shift_last_date');
    final today = _getTodayKey();

    if (lastDate != today) {
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
    state = const ShiftState();
    await _saveState();
    _stopGpsTracking();
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  DateTime? _fromMillis(int? ms) => ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;

  // ===== УПРАВЛЕНИЕ GPS =====

  void _startGpsTracking() {
    if (_gpsService == null) {
      try {
        _gpsService = _ref.read(gpsServiceProvider);
      } catch (e) {
        print('⚠️ Не удалось получить GPS сервис: $e');
        return;
      }
    }
    if (_gpsService != null) {
      print('🟢 Запускаем GPS трекинг (смена активна)');
      _gpsService!.startTracking();
    } else {
      print('⚠️ GpsService не найден');
    }
  }

  void _stopGpsTracking() {
    if (_gpsService != null) {
      print('🛑 Останавливаем GPS трекинг (смена не активна)');
      _gpsService!.stopTracking();
    }
  }

  // ===== ОСНОВНЫЕ МЕТОДЫ =====

  void startShift() {
    if (state.isActive) return;
    final now = DateTime.now();
    state = state.copyWith(
      isActive: true,
      shiftStartTime: now,
      shiftEndTime: null,
      idleStartTime: now,
    );
    _saveState();
    _startGpsTracking();
  }

  void stopShift() {
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
  }

  void addIdleDistance(double distance) {
    if (!state.isActive || state.isOnOrder || distance <= 0) return;
    state = state.copyWith(
      totalIdleDistance: state.totalIdleDistance + distance,
    );
    _saveState();
  }

  void updatePaidDistance(double distance) {
    if (!state.isActive || !state.isOnOrder || distance <= 0) return;
    state = state.copyWith(
      totalPaidDistance: state.totalPaidDistance + distance,
    );
    _saveState();
  }

  void tick() {
    if (!state.isActive) return;
    state = state.copyWith(lastTick: DateTime.now().millisecondsSinceEpoch);
  }

  void resetDay() {
    _resetDay();
  }
}

final shiftProvider = StateNotifierProvider<ShiftNotifier, ShiftState>((ref) {
  return ShiftNotifier(ref);
});