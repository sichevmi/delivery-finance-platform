// lib/features/delivery/providers/daily_stats_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/core/database/database_provider.dart';
import 'package:delivery_app/features/delivery/providers/shift_provider.dart';
import 'package:delivery_app/logger.dart';

class DailyStats {
  final double totalPaidDistance;
  final double totalIdleDistance;
  final int ordersCount;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final Duration totalWorkTime;
  final Duration totalIdleTime;

  DailyStats({
    this.totalPaidDistance = 0.0,
    this.totalIdleDistance = 0.0,
    this.ordersCount = 0,
    this.totalIncome = 0.0,
    this.totalExpenses = 0.0,
    this.netProfit = 0.0,
    this.totalWorkTime = Duration.zero,
    this.totalIdleTime = Duration.zero,
  });

  DailyStats copyWith({
    double? totalPaidDistance,
    double? totalIdleDistance,
    int? ordersCount,
    double? totalIncome,
    double? totalExpenses,
    double? netProfit,
    Duration? totalWorkTime,
    Duration? totalIdleTime,
  }) {
    return DailyStats(
      totalPaidDistance: totalPaidDistance ?? this.totalPaidDistance,
      totalIdleDistance: totalIdleDistance ?? this.totalIdleDistance,
      ordersCount: ordersCount ?? this.ordersCount,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      netProfit: netProfit ?? this.netProfit,
      totalWorkTime: totalWorkTime ?? this.totalWorkTime,
      totalIdleTime: totalIdleTime ?? this.totalIdleTime,
    );
  }

  double get totalDistance => totalPaidDistance + totalIdleDistance;
  double get avgDistancePerOrder => ordersCount > 0 ? totalPaidDistance / ordersCount : 0.0;
  double get avgCheck => ordersCount > 0 ? totalIncome / ordersCount : 0.0;
  
  Duration get avgTimePerOrder => ordersCount > 0 
      ? Duration(milliseconds: (totalWorkTime.inMilliseconds / ordersCount).round()) 
      : Duration.zero;

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedWorkTime => formatDuration(totalWorkTime);
  String get formattedIdleTime => formatDuration(totalIdleTime);
  
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
}

final dailyStatsProvider = FutureProvider<DailyStats>((ref) async {
  final db = ref.read(appDatabaseProvider);
  final now = DateTime.now();
  
  // Получаем все смены за сегодня
  final shifts = await db.shiftDao.getShiftsForDate(now);

  var totalPaid = 0.0;
  var totalIdle = 0.0;
  var orders = 0;
  var income = 0.0;
  var expenses = 0.0;
  var profit = 0.0;
  var workDuration = Duration.zero;
  var idleDuration = Duration.zero;

  // Суммируем все смены из БД
  for (final shift in shifts) {
    totalPaid += shift.totalPaidDistance;
    totalIdle += shift.totalIdleDistance;
    orders += shift.ordersCount;
    income += shift.totalIncome;
    expenses += shift.totalExpenses;
    profit += shift.netProfit;
    workDuration += Duration(seconds: shift.durationSeconds);
  }

  // Добавляем текущую активную смену (если есть)
  final shiftState = ref.read(shiftProvider);
  if (shiftState.isActive && shiftState.localShiftId != null) {
    // Проверяем, не учтена ли эта смена уже в БД
    final alreadyInDb = shifts.any((s) => s.id == shiftState.localShiftId);
    if (!alreadyInDb) {
      // Если смена ещё не в БД — добавляем её данные
      totalPaid += shiftState.totalPaidDistance;
      totalIdle += shiftState.totalIdleDistance;
      orders += shiftState.ordersCount;
      income += shiftState.totalIncome;
      expenses += shiftState.totalExpenses;
      profit += shiftState.netProfit;
      workDuration += shiftState.workTime;
      idleDuration += shiftState.totalIdleTimeDisplay;
    }
  } else if (shiftState.isActive && shiftState.localShiftId == null) {
    // Если смена только что создана и ещё не сохранена в БД
    totalPaid += shiftState.totalPaidDistance;
    totalIdle += shiftState.totalIdleDistance;
    orders += shiftState.ordersCount;
    income += shiftState.totalIncome;
    expenses += shiftState.totalExpenses;
    profit += shiftState.netProfit;
    workDuration += shiftState.workTime;
    idleDuration += shiftState.totalIdleTimeDisplay;
  }

  logMessage('📊 Дневная статистика: заказов=$orders, пробег=$totalPaid, доход=$income', category: 'STATS');

  return DailyStats(
    totalPaidDistance: totalPaid,
    totalIdleDistance: totalIdle,
    ordersCount: orders,
    totalIncome: income,
    totalExpenses: expenses,
    netProfit: profit,
    totalWorkTime: workDuration,
    totalIdleTime: idleDuration,
  );
});