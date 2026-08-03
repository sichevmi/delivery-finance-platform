// lib/features/delivery/providers/shift_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShiftState {
  final bool isActive;
  final DateTime? shiftStartTime;
  final DateTime? shiftEndTime;
  final Duration totalOrdersTime;         // суммарное время всех заказов
  final Duration currentOrderTime;        // время текущего заказа (если в процессе)
  final DateTime? currentOrderStartTime;  // время начала текущего заказа
  final double totalDistance;
  final double paidDistance;
  final double idleDistance;
  final int ordersCount;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final bool isOnOrder;

  const ShiftState({
    this.isActive = false,
    this.shiftStartTime,
    this.shiftEndTime,
    this.totalOrdersTime = Duration.zero,
    this.currentOrderTime = Duration.zero,
    this.currentOrderStartTime,
    this.totalDistance = 0.0,
    this.paidDistance = 0.0,
    this.idleDistance = 0.0,
    this.ordersCount = 0,
    this.totalIncome = 0.0,
    this.totalExpenses = 0.0,
    this.netProfit = 0.0,
    this.isOnOrder = false,
  });

  ShiftState copyWith({
    bool? isActive,
    DateTime? shiftStartTime,
    DateTime? shiftEndTime,
    Duration? totalOrdersTime,
    Duration? currentOrderTime,
    DateTime? currentOrderStartTime,
    double? totalDistance,
    double? paidDistance,
    double? idleDistance,
    int? ordersCount,
    double? totalIncome,
    double? totalExpenses,
    double? netProfit,
    bool? isOnOrder,
  }) {
    return ShiftState(
      isActive: isActive ?? this.isActive,
      shiftStartTime: shiftStartTime ?? this.shiftStartTime,
      shiftEndTime: shiftEndTime ?? this.shiftEndTime,
      totalOrdersTime: totalOrdersTime ?? this.totalOrdersTime,
      currentOrderTime: currentOrderTime ?? this.currentOrderTime,
      currentOrderStartTime: currentOrderStartTime ?? this.currentOrderStartTime,
      totalDistance: totalDistance ?? this.totalDistance,
      paidDistance: paidDistance ?? this.paidDistance,
      idleDistance: idleDistance ?? this.idleDistance,
      ordersCount: ordersCount ?? this.ordersCount,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      netProfit: netProfit ?? this.netProfit,
      isOnOrder: isOnOrder ?? this.isOnOrder,
    );
  }

  // Время работы = сумма времени всех заказов + текущий заказ (если есть)
  Duration get workTime => totalOrdersTime + currentOrderTime;

  // Время простоя = общее время смены - время работы
  Duration getIdleTime(DateTime now) {
    if (!isActive || shiftStartTime == null) return Duration.zero;
    final totalShiftTime = now.difference(shiftStartTime!);
    final result = totalShiftTime - workTime;
    return result > Duration.zero ? result : Duration.zero;
  }

  String get formattedWorkTime {
    final total = workTime;
    final hours = total.inHours;
    final minutes = total.inMinutes.remainder(60);
    final seconds = total.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String formattedIdleTime(DateTime now) {
    final total = getIdleTime(now);
    final hours = total.inHours;
    final minutes = total.inMinutes.remainder(60);
    final seconds = total.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get avgDistancePerOrder => ordersCount > 0 ? paidDistance / ordersCount : 0.0;
  double get avgTimePerOrder => ordersCount > 0 ? totalOrdersTime.inSeconds / ordersCount / 60 : 0.0;
  double get avgCheck => ordersCount > 0 ? totalIncome / ordersCount : 0.0;
  double get totalDistanceAll => paidDistance + idleDistance;
}

class ShiftNotifier extends StateNotifier<ShiftState> {
  ShiftNotifier() : super(const ShiftState()) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final isActive = prefs.getBool('shift_active') ?? false;
    final shiftStart = prefs.getInt('shift_start');
    final ordersTime = prefs.getInt('shift_orders_time') ?? 0;
    final totalDist = prefs.getDouble('shift_total_distance') ?? 0.0;
    final paidDist = prefs.getDouble('shift_paid_distance') ?? 0.0;
    final idleDist = prefs.getDouble('shift_idle_distance') ?? 0.0;
    final orders = prefs.getInt('shift_orders') ?? 0;
    final income = prefs.getDouble('shift_income') ?? 0.0;
    final expenses = prefs.getDouble('shift_expenses') ?? 0.0;

    state = state.copyWith(
      isActive: isActive,
      shiftStartTime: shiftStart != null ? DateTime.fromMillisecondsSinceEpoch(shiftStart) : null,
      totalOrdersTime: Duration(seconds: ordersTime),
      totalDistance: totalDist,
      paidDistance: paidDist,
      idleDistance: idleDist,
      ordersCount: orders,
      totalIncome: income,
      totalExpenses: expenses,
      netProfit: income - expenses,
    );
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('shift_active', state.isActive);
    if (state.shiftStartTime != null) {
      await prefs.setInt('shift_start', state.shiftStartTime!.millisecondsSinceEpoch);
    }
    await prefs.setInt('shift_orders_time', state.totalOrdersTime.inSeconds);
    await prefs.setDouble('shift_total_distance', state.totalDistance);
    await prefs.setDouble('shift_paid_distance', state.paidDistance);
    await prefs.setDouble('shift_idle_distance', state.idleDistance);
    await prefs.setInt('shift_orders', state.ordersCount);
    await prefs.setDouble('shift_income', state.totalIncome);
    await prefs.setDouble('shift_expenses', state.totalExpenses);
  }

  void startShift() {
    final now = DateTime.now();
    state = state.copyWith(
      isActive: true,
      shiftStartTime: state.shiftStartTime ?? now,
      totalOrdersTime: Duration.zero,
      currentOrderTime: Duration.zero,
    );
    _saveState();
  }

  void stopShift() {
    state = state.copyWith(
      isActive: false,
      shiftEndTime: DateTime.now(),
    );
    _saveState();
  }

  void startOrder() {
    state = state.copyWith(
      isOnOrder: true,
      currentOrderStartTime: DateTime.now(),
      currentOrderTime: Duration.zero,
    );
    _saveState();
  }

  void finishOrder(double orderDistance, double orderIncome, double orderExpenses, Duration orderDuration) {
    final newPaidDistance = state.paidDistance + orderDistance;
    final newOrders = state.ordersCount + 1;
    final newIncome = state.totalIncome + orderIncome;
    final newExpenses = state.totalExpenses + orderExpenses;
    final newOrdersTime = state.totalOrdersTime + orderDuration;

    state = state.copyWith(
      isOnOrder: false,
      currentOrderStartTime: null,
      currentOrderTime: Duration.zero,
      paidDistance: newPaidDistance,
      ordersCount: newOrders,
      totalIncome: newIncome,
      totalExpenses: newExpenses,
      netProfit: newIncome - newExpenses,
      totalOrdersTime: newOrdersTime,
    );
    _saveState();
  }

  void addIdleDistance(double distance) {
    if (!state.isActive || state.isOnOrder) return;
    state = state.copyWith(
      idleDistance: state.idleDistance + distance,
    );
    _saveState();
  }

  void updateTotalDistance(double newDistance) {
    if (!state.isActive) return;
    final delta = newDistance - state.totalDistance;
    if (delta <= 0) return;
    
    if (state.isOnOrder) {
      state = state.copyWith(
        totalDistance: state.totalDistance + delta,
        paidDistance: state.paidDistance + delta,
      );
    } else {
      state = state.copyWith(
        totalDistance: state.totalDistance + delta,
        idleDistance: state.idleDistance + delta,
      );
    }
    _saveState();
  }

  void tick() {
    if (!state.isActive) return;
    
    // Если в заказе – обновляем время текущего заказа
    if (state.isOnOrder && state.currentOrderStartTime != null) {
      final now = DateTime.now();
      final duration = now.difference(state.currentOrderStartTime!);
      state = state.copyWith(
        currentOrderTime: duration,
      );
    }
  }

  void resetDailyStats() {
    // Не сбрасываем полностью
  }
}

final shiftProvider = StateNotifierProvider<ShiftNotifier, ShiftState>((ref) {
  return ShiftNotifier();
});