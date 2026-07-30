// Сводка по периоду
class AnalyticsSummary {
  final int totalOrders;
  final double totalExpenses;
  final double netProfit;
  final double totalDistance; // км
  final Duration totalTime;   // затраченное время

  AnalyticsSummary({
    required this.totalOrders,
    required this.totalExpenses,
    required this.netProfit,
    required this.totalDistance,
    required this.totalTime,
  });
}

// Данные для одного столбца графика (месяц, день, час)
class AnalyticsChartPoint {
  final String label;      // "Янв", "01", "10:00"
  final double value;      // прибыль или другая метрика
  final int ordersCount;   // кол-во заказов (для всплывающей подсказки)

  AnalyticsChartPoint({
    required this.label,
    required this.value,
    required this.ordersCount,
  });
}

// Данные для плашки периода (год, месяц, день)
class AnalyticsPeriodTile {
  final String title;      // "2025", "Март", "15 марта"
  final double profit;
  final int ordersCount;
  final DateTime? startDate; // для навигации
  final DateTime? endDate;

  AnalyticsPeriodTile({
    required this.title,
    required this.profit,
    required this.ordersCount,
    this.startDate,
    this.endDate,
  });
}

// Полный набор данных для отображения на экране
class AnalyticsData {
  final AnalyticsSummary summary;
  final List<AnalyticsChartPoint> chartPoints; // точки для графика
  final List<AnalyticsPeriodTile> periodTiles; // плашки для детализации

  AnalyticsData({
    required this.summary,
    required this.chartPoints,
    required this.periodTiles,
  });
}