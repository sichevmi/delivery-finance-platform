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
  final Duration totalOrderTime;

  DailyStats({
    this.totalPaidDistance = 0.0,
    this.totalIdleDistance = 0.0,
    this.ordersCount = 0,
    this.totalIncome = 0.0,
    this.totalExpenses = 0.0,
    this.netProfit = 0.0,
    this.totalWorkTime = Duration.zero,
    this.totalIdleTime = Duration.zero,
    this.totalOrderTime = Duration.zero,
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
    Duration? totalOrderTime,
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
      totalOrderTime: totalOrderTime ?? this.totalOrderTime,
    );
  }

  double get totalDistance => totalPaidDistance + totalIdleDistance;
  double get avgDistancePerOrder => ordersCount > 0 ? totalPaidDistance / ordersCount : 0.0;
  double get avgCheck => ordersCount > 0 ? totalIncome / ordersCount : 0.0;
  
  Duration get avgTimePerOrder {
    if (ordersCount == 0) return Duration.zero;
    return Duration(
      milliseconds: (totalOrderTime.inMilliseconds / ordersCount).round()
    );
  }

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
    if (d == Duration.zero) return '0 мин';
    
    final totalSeconds = d.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    
    if (seconds >= 30) {
      return '${minutes + 1} мин';
    } else if (minutes > 0) {
      return '$minutes мин';
    } else {
      return '$seconds сек';
    }
  }
}

final dailyStatsProvider = FutureProvider<DailyStats>((ref) {
  logMessage('📊 Пересчёт дневной статистики', category: 'STATS');
  return _calculateDailyStats(ref);
});

// Отдельная функция для расчёта статистики
Future<DailyStats> _calculateDailyStats(Ref ref) async {
  final db = ref.read(appDatabaseProvider);
  final now = DateTime.now();
  
  // Получаем все заказы за сегодня из БД
  final orders = await db.orderDao.getOrdersForDate(now);
  
  var totalPaid = 0.0;
  var totalIncome = 0.0;
  var totalExpenses = 0.0;
  var totalProfit = 0.0;
  var totalOrderTime = Duration.zero;
  var ordersCount = orders.length;
  
  for (final order in orders) {
    totalPaid += order.totalPaidDistance;
    totalIncome += order.totalIncome;
    totalExpenses += order.totalExpenses;
    totalProfit += order.netProfit;
    totalOrderTime += Duration(seconds: order.totalTimeSeconds);
  }
  
  // Получаем смены для рабочего времени и холостого пробега
  final shifts = await db.shiftDao.getShiftsForDate(now);
  
  var totalIdle = 0.0;
  var workDuration = Duration.zero;
  var idleDuration = Duration.zero;

  for (final shift in shifts) {
    totalIdle += shift.totalIdleDistance;
    workDuration += Duration(seconds: shift.durationSeconds);
  }

  // Добавляем текущую активную смену (если есть)
  final shiftState = ref.read(shiftProvider);
  if (shiftState.isActive && shiftState.localShiftId != null) {
    final alreadyInDb = shifts.any((s) => s.id == shiftState.localShiftId);
    if (!alreadyInDb) {
      totalIdle += shiftState.totalIdleDistance;
      workDuration += shiftState.workTime;
      idleDuration += shiftState.totalIdleTimeDisplay;
      // Заказы из активной смены не дублируем, они уже сохранены в БД
    }
  } else if (shiftState.isActive && shiftState.localShiftId == null) {
    totalIdle += shiftState.totalIdleDistance;
    workDuration += shiftState.workTime;
    idleDuration += shiftState.totalIdleTimeDisplay;
  }

  logMessage('📊 Дневная статистика: заказов=$ordersCount, пробег=$totalPaid, доход=$totalIncome', category: 'STATS');

  return DailyStats(
    totalPaidDistance: totalPaid,
    totalIdleDistance: totalIdle,
    ordersCount: ordersCount,
    totalIncome: totalIncome,
    totalExpenses: totalExpenses,
    netProfit: totalProfit,
    totalWorkTime: workDuration,
    totalIdleTime: idleDuration,
    totalOrderTime: totalOrderTime,
  );
}

// Провайдер для ручного обновления статистики
final refreshStatsProvider = Provider<void>((ref) {
  return null;
});

extension RefreshStats on ProviderContainer {
  void refreshStats() {
    this.invalidate(dailyStatsProvider);
  }
}