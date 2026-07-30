import 'package:delivery_app/models/analytics_models.dart';
import 'dart:math';

class MockAnalyticsRepository {
  final Random _random = Random();

  // Генерация данных для периода (год, месяц, день)
  AnalyticsData getData({
    required int year,
    int? month,
    int? day,
    AnalyticsPeriod period = AnalyticsPeriod.year,
  }) {
    // В зависимости от периода генерируем соответствующие точки и плитки
    if (period == AnalyticsPeriod.year) {
      return _getYearData(year);
    } else if (period == AnalyticsPeriod.month) {
      return _getMonthData(year, month ?? DateTime.now().month);
    } else {
      return _getDayData(year, month ?? DateTime.now().month, day ?? DateTime.now().day);
    }
  }

  // Данные за год: 12 месяцев
  AnalyticsData _getYearData(int year) {
    final months = List.generate(12, (i) => i + 1);
    final chartPoints = months.map((m) {
      final profit = 1000 + _random.nextDouble() * 5000;
      final orders = 50 + _random.nextInt(100);
      return AnalyticsChartPoint(
        label: _monthName(m),
        value: profit,
        ordersCount: orders,
      );
    }).toList();

    final totalProfit = chartPoints.fold(0.0, (sum, p) => sum + p.value);
    final totalOrders = chartPoints.fold(0, (sum, p) => sum + p.ordersCount);
    final totalExpenses = totalProfit * 0.4;
    final totalDistance = 500 + _random.nextDouble() * 1000;

    final tiles = months.map((m) {
      final profit = chartPoints[m - 1].value;
      final orders = chartPoints[m - 1].ordersCount;
      return AnalyticsPeriodTile(
        title: _monthName(m),
        profit: profit,
        ordersCount: orders,
        startDate: DateTime(year, m, 1),
        endDate: DateTime(year, m, 1).add(const Duration(days: 30)),
      );
    }).toList();

    return AnalyticsData(
      summary: AnalyticsSummary(
        totalOrders: totalOrders,
        totalExpenses: totalExpenses,
        netProfit: totalProfit,
        totalDistance: totalDistance,
        totalTime: Duration(hours: 200 + _random.nextInt(300)),
      ),
      chartPoints: chartPoints,
      periodTiles: tiles,
    );
  }

  // Данные за месяц: дни (1-30)
  AnalyticsData _getMonthData(int year, int month) {
    final days = List.generate(30, (i) => i + 1);
    final chartPoints = days.map((d) {
      final profit = 50 + _random.nextDouble() * 200;
      final orders = 2 + _random.nextInt(15);
      return AnalyticsChartPoint(
        label: '$d',
        value: profit,
        ordersCount: orders,
      );
    }).toList();

    final totalProfit = chartPoints.fold(0.0, (sum, p) => sum + p.value);
    final totalOrders = chartPoints.fold(0, (sum, p) => sum + p.ordersCount);
    final totalExpenses = totalProfit * 0.4;
    final totalDistance = 30 + _random.nextDouble() * 100;

    final tiles = days.map((d) {
      final profit = chartPoints[d - 1].value;
      final orders = chartPoints[d - 1].ordersCount;
      return AnalyticsPeriodTile(
        title: '$d ${_monthName(month)}',
        profit: profit,
        ordersCount: orders,
        startDate: DateTime(year, month, d),
        endDate: DateTime(year, month, d),
      );
    }).toList();

    return AnalyticsData(
      summary: AnalyticsSummary(
        totalOrders: totalOrders,
        totalExpenses: totalExpenses,
        netProfit: totalProfit,
        totalDistance: totalDistance,
        totalTime: Duration(hours: 10 + _random.nextInt(50)),
      ),
      chartPoints: chartPoints,
      periodTiles: tiles,
    );
  }

  // Данные за день: список заказов (имитация)
  AnalyticsData _getDayData(int year, int month, int day) {
    // Для дня нет графика, только список заказов
    // Создаём фиктивные заказы
    final ordersCount = 3 + _random.nextInt(10);
    final chartPoints = List.generate(ordersCount, (i) {
      final profit = 100 + _random.nextDouble() * 300;
      return AnalyticsChartPoint(
        label: 'Заказ #${i + 1}',
        value: profit,
        ordersCount: 1,
      );
    });

    final totalProfit = chartPoints.fold(0.0, (sum, p) => sum + p.value);
    final totalOrders = ordersCount;
    final totalExpenses = totalProfit * 0.4;
    final totalDistance = 5 + _random.nextDouble() * 20;

    // Плитки - заказы
    final tiles = chartPoints.asMap().entries.map((entry) {
      final idx = entry.key;
      final point = entry.value;
      return AnalyticsPeriodTile(
        title: 'Заказ #${idx + 1}',
        profit: point.value,
        ordersCount: 1,
        startDate: DateTime(year, month, day, 9 + idx * 2),
        endDate: DateTime(year, month, day, 9 + idx * 2 + 1),
      );
    }).toList();

    return AnalyticsData(
      summary: AnalyticsSummary(
        totalOrders: totalOrders,
        totalExpenses: totalExpenses,
        netProfit: totalProfit,
        totalDistance: totalDistance,
        totalTime: Duration(hours: 1 + _random.nextInt(3)),
      ),
      chartPoints: chartPoints,
      periodTiles: tiles,
    );
  }

  String _monthName(int month) {
    const names = ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'];
    return names[month - 1];
  }
}