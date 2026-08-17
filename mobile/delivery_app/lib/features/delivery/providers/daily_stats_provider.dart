// lib/features/delivery/providers/daily_stats_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/core/services/api_service.dart';

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

Future<DailyStats> _calculateDailyStats(Ref ref) async {
  final cache = ApiService().cache;

  // Считаем из кэша
  int ordersCount = cache.todayOrders.length;
  double totalPaid = 0.0;
  double totalIncome = 0.0;
  double totalExpenses = 0.0;
  double netProfit = 0.0;
  Duration totalOrderTime = Duration.zero;

  for (final order in cache.todayOrders) {
    totalPaid += order.totalPaidDistance;
    totalIncome += order.totalIncome;
    totalExpenses += order.totalExpenses;
    netProfit += order.netProfit;
    totalOrderTime += order.totalTime;
  }

  // Время работы из активной смены
  Duration totalWorkTime = Duration.zero;
  double totalIdle = 0.0;
  Duration totalIdleTime = Duration.zero;

  if (cache.activeShift != null) {
    totalWorkTime = cache.activeShift!.duration ?? Duration.zero;
    totalIdle = cache.activeShift!.totalIdleDistance;
    // Время простоя пока не хранится отдельно, можно добавить позже
  }

  logMessage('📊 Дневная статистика: заказов=$ordersCount, пробег=$totalPaid, доход=$totalIncome', category: 'STATS');

  return DailyStats(
    totalPaidDistance: totalPaid,
    totalIdleDistance: totalIdle,
    ordersCount: ordersCount,
    totalIncome: totalIncome,
    totalExpenses: totalExpenses,
    netProfit: netProfit,
    totalWorkTime: totalWorkTime,
    totalIdleTime: totalIdleTime,
    totalOrderTime: totalOrderTime,
  );
}