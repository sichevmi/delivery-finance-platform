import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/core/services/api_service.dart';
import 'package:delivery_app/features/delivery/models/shift.dart';

class ShiftState {
  final bool isActive;
  final DateTime? shiftStartTime;
  final DateTime? shiftEndTime;
  final Duration totalWorkTime;
  final double totalPaidDistance;
  final double totalIdleDistance;
  final int ordersCount;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final int? shiftId;

  const ShiftState({
    this.isActive = false,
    this.shiftStartTime,
    this.shiftEndTime,
    this.totalWorkTime = Duration.zero,
    this.totalPaidDistance = 0.0,
    this.totalIdleDistance = 0.0,
    this.ordersCount = 0,
    this.totalIncome = 0.0,
    this.totalExpenses = 0.0,
    this.netProfit = 0.0,
    this.shiftId,
  });

  ShiftState copyWith({
    bool? isActive,
    DateTime? shiftStartTime,
    DateTime? shiftEndTime,
    Duration? totalWorkTime,
    double? totalPaidDistance,
    double? totalIdleDistance,
    int? ordersCount,
    double? totalIncome,
    double? totalExpenses,
    double? netProfit,
    int? shiftId,
  }) {
    return ShiftState(
      isActive: isActive ?? this.isActive,
      shiftStartTime: shiftStartTime ?? this.shiftStartTime,
      shiftEndTime: shiftEndTime ?? this.shiftEndTime,
      totalWorkTime: totalWorkTime ?? this.totalWorkTime,
      totalPaidDistance: totalPaidDistance ?? this.totalPaidDistance,
      totalIdleDistance: totalIdleDistance ?? this.totalIdleDistance,
      ordersCount: ordersCount ?? this.ordersCount,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      netProfit: netProfit ?? this.netProfit,
      shiftId: shiftId ?? this.shiftId,
    );
  }

  Duration get workTime {
    if (!isActive || shiftStartTime == null) return totalWorkTime;
    return totalWorkTime + DateTime.now().difference(shiftStartTime!);
  }

  double get totalDistance => totalPaidDistance + totalIdleDistance;
  double get avgCheck => ordersCount > 0 ? totalIncome / ordersCount : 0.0;
}

final shiftProvider = StateNotifierProvider<ShiftNotifier, ShiftState>((ref) {
  return ShiftNotifier(ref);
});

class ShiftNotifier extends StateNotifier<ShiftState> {
  final Ref _ref;
  final ApiService _apiService = ApiService();

  ShiftNotifier(this._ref) : super(const ShiftState()) {
    _loadFromCache();
  }

  void _loadFromCache() {
    final cache = _apiService.cache;
    if (cache.activeShift != null) {
      final shift = cache.activeShift!;
      state = ShiftState(
        isActive: true,
        shiftStartTime: shift.startTime,
        shiftId: shift.id,
        totalPaidDistance: shift.totalPaidDistance,
        totalIdleDistance: shift.totalIdleDistance,
        ordersCount: shift.ordersCount,
        totalIncome: shift.totalIncome,
        totalExpenses: shift.totalExpenses,
        netProfit: shift.netProfit,
      );
    }
  }

  Future<void> startShift() async {
    if (state.isActive) return;
    try {
      final shift = await _apiService.startShift();
      state = ShiftState(
        isActive: true,
        shiftStartTime: shift.startTime,
        shiftId: shift.id,
        totalPaidDistance: shift.totalPaidDistance,
        totalIdleDistance: shift.totalIdleDistance,
        ordersCount: shift.ordersCount,
        totalIncome: shift.totalIncome,
        totalExpenses: shift.totalExpenses,
        netProfit: shift.netProfit,
      );
      logMessage('✅ Смена начата на сервере', category: 'SHIFT');
    } catch (e) {
      logMessage('❌ Ошибка начала смены: $e', category: 'SHIFT', level: LogLevel.error);
    }
  }

  Future<void> stopShift() async {
    if (!state.isActive || state.shiftId == null) return;
    try {
      await _apiService.completeShift(state.shiftId!);
      state = const ShiftState();
      logMessage('✅ Смена завершена на сервере', category: 'SHIFT');
    } catch (e) {
      logMessage('❌ Ошибка завершения смены: $e', category: 'SHIFT', level: LogLevel.error);
    }
  }
}