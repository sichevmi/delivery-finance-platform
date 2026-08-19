import 'package:delivery_app/features/delivery/models/delivery.dart';

class Order {
  final int id;
  final int? shiftId;
  final String serviceName;
  final double coefficient;
  final int deliveryNumber;
  final double totalPaidDistance;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final Duration totalTime;
  final String? shopAddress;  // <-- ДОБАВЛЯЕМ
  final String status;
  final List<Delivery> deliveries;

  Order({
    required this.id,
    this.shiftId,
    required this.serviceName,
    this.coefficient = 1.0,
    this.deliveryNumber = 1,
    this.totalPaidDistance = 0.0,
    this.totalIncome = 0.0,
    this.totalExpenses = 0.0,
    this.netProfit = 0.0,
    this.totalTime = Duration.zero,
    this.shopAddress,
    this.status = 'active',
    this.deliveries = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      shiftId: json['shiftId'],
      serviceName: json['serviceName'] ?? '',
      coefficient: (json['coefficient'] ?? 1.0).toDouble(),
      deliveryNumber: json['deliveryNumber'] ?? 1,
      totalPaidDistance: (json['totalPaidDistance'] ?? 0).toDouble(),
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      totalExpenses: (json['totalExpenses'] ?? 0).toDouble(),
      netProfit: (json['netProfit'] ?? 0).toDouble(),
      totalTime: json['totalTimeSeconds'] != null ? Duration(seconds: json['totalTimeSeconds']) : Duration.zero,
      shopAddress: json['shopAddress'],  // <-- ДОБАВЛЯЕМ
      status: json['status'] ?? 'active',
      deliveries: (json['deliveries'] as List?)?.map((d) => Delivery.fromJson(d)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shiftId': shiftId,
      'serviceName': serviceName,
      'coefficient': coefficient,
      'deliveryNumber': deliveryNumber,
      'totalPaidDistance': totalPaidDistance,
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netProfit': netProfit,
      'totalTimeSeconds': totalTime.inSeconds,
      'shopAddress': shopAddress,  // <-- ДОБАВЛЯЕМ
      'status': status,
      'deliveries': deliveries.map((d) => d.toJson()).toList(),
    };
  }
}