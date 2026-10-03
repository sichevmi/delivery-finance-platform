import 'analytics_enums.dart';

// ===== СВОДКА =====
class AnalyticsSummary {
  final int totalOrders;
  final double totalIncome;
  final double totalDistance;
  final Duration totalTime;

  AnalyticsSummary({
    required this.totalOrders,
    required this.totalIncome,
    required this.totalDistance,
    required this.totalTime,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) => AnalyticsSummary(
        totalOrders: (json['totalOrders'] ?? 0) as int,
        totalIncome: ((json['totalIncome'] ?? 0) as num).toDouble(),
        totalDistance: ((json['totalDistance'] ?? 0) as num).toDouble(),
        totalTime: Duration(seconds: (json['totalTimeSeconds'] ?? 0) as int),
      );
}

// ===== ТОЧКА ГРАФИКА =====
class AnalyticsChartPoint {
  final String label;
  final double value;
  final int ordersCount;

  AnalyticsChartPoint({
    required this.label,
    required this.value,
    required this.ordersCount,
  });

  factory AnalyticsChartPoint.fromJson(Map<String, dynamic> json) => AnalyticsChartPoint(
        label: (json['label'] ?? '').toString(),
        value: ((json['value'] ?? 0) as num).toDouble(),
        ordersCount: (json['ordersCount'] ?? 0) as int,
      );
}

// ===== ПЛАШКА =====
class AnalyticsPeriodTile {
  final String title;
  final double profit;
  final int ordersCount;
  final DateTime? startDate;
  final DateTime? endDate;

  // Поля для плашек "день" (заказы)
  final int? orderId;
  final String? serviceName;
  final int? deliveriesCount;

  AnalyticsPeriodTile({
    required this.title,
    required this.profit,
    required this.ordersCount,
    this.startDate,
    this.endDate,
    this.orderId,
    this.serviceName,
    this.deliveriesCount,
  });

  factory AnalyticsPeriodTile.fromJson(Map<String, dynamic> json) {
    final orderId = json['orderId'];
    final serviceName = json['serviceName'];
    final deliveriesCount = json['deliveriesCount'];

    // Если это заказ (есть orderId) — title собираем из serviceName + ID
    final title = orderId != null
        ? 'Заказ #$orderId'
        : (json['title'] ?? '').toString();

    return AnalyticsPeriodTile(
      title: title,
      profit: ((json['profit'] ?? 0) as num).toDouble(),
      ordersCount: (json['ordersCount'] ?? 0) as int,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'])
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'])
          : null,
      orderId: orderId != null ? orderId as int : null,
      serviceName: serviceName?.toString(),
      deliveriesCount: deliveriesCount != null ? deliveriesCount as int : null,
    );
  }
}

// ===== ПОЛНЫЙ НАБОР =====
class AnalyticsData {
  final AnalyticsSummary summary;
  final List<AnalyticsChartPoint> chartPoints;
  final List<AnalyticsPeriodTile> periodTiles;

  AnalyticsData({
    required this.summary,
    required this.chartPoints,
    required this.periodTiles,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) => AnalyticsData(
        summary: AnalyticsSummary.fromJson(
            json['summary'] as Map<String, dynamic>),
        chartPoints: (json['chartPoints'] as List)
            .map((e) => AnalyticsChartPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        periodTiles: (json['periodTiles'] as List)
            .map((e) => AnalyticsPeriodTile.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ===== ДЕТАЛИ ЗАКАЗА =====
class OrderDetails {
  final int id;
  final int? shiftId;
  final String? serviceName;
  final double? coefficient;
  final int? deliveryNumber;
  final double totalPaidDistance;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final int totalTimeSeconds;
  final String? shopAddress;
  final String? status;
  final DateTime? createdAt;
  final List<OrderDeliveryItem> deliveries;

  OrderDetails({
    required this.id,
    this.shiftId,
    this.serviceName,
    this.coefficient,
    this.deliveryNumber,
    required this.totalPaidDistance,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
    required this.totalTimeSeconds,
    this.shopAddress,
    this.status,
    this.createdAt,
    required this.deliveries,
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) => OrderDetails(
        id: json['id'] as int,
        shiftId: json['shiftId'] as int?,
        serviceName: json['serviceName'] as String?,
        coefficient: (json['coefficient'] as num?)?.toDouble(),
        deliveryNumber: json['deliveryNumber'] as int?,
        totalPaidDistance: ((json['totalPaidDistance'] ?? 0) as num).toDouble(),
        totalIncome: ((json['totalIncome'] ?? 0) as num).toDouble(),
        totalExpenses: ((json['totalExpenses'] ?? 0) as num).toDouble(),
        netProfit: ((json['netProfit'] ?? 0) as num).toDouble(),
        totalTimeSeconds: (json['totalTimeSeconds'] ?? 0) as int,
        shopAddress: json['shopAddress'] as String?,
        status: json['status'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'])
            : null,
        deliveries: (json['deliveries'] as List? ?? [])
            .map((e) => OrderDeliveryItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class OrderDeliveryItem {
  final int? id;
  final int? number;
  final String? clientAddress;
  final String? apartment;
  final double? weight;
  final int? timeToShop;
  final double? distanceToShop;
  final int? timeReceiving;
  final int? timeToClient;
  final double? distanceToClient;
  final int? timeDelivery;
  final double? tip;
  final String? status;

  OrderDeliveryItem({
    this.id,
    this.number,
    this.clientAddress,
    this.apartment,
    this.weight,
    this.timeToShop,
    this.distanceToShop,
    this.timeReceiving,
    this.timeToClient,
    this.distanceToClient,
    this.timeDelivery,
    this.tip,
    this.status,
  });

  factory OrderDeliveryItem.fromJson(Map<String, dynamic> json) => OrderDeliveryItem(
        id: json['id'] as int?,
        number: json['number'] as int?,
        clientAddress: json['clientAddress'] as String?,
        apartment: json['apartment'] as String?,
        weight: (json['weight'] as num?)?.toDouble(),
        timeToShop: json['timeToShop'] as int?,
        distanceToShop: (json['distanceToShop'] as num?)?.toDouble(),
        timeReceiving: json['timeReceiving'] as int?,
        timeToClient: json['timeToClient'] as int?,
        distanceToClient: (json['distanceToClient'] as num?)?.toDouble(),
        timeDelivery: json['timeDelivery'] as int?,
        tip: (json['tip'] as num?)?.toDouble(),
        status: json['status'] as String?,
      );
}