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
  final String? shopAddress;
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
      coefficient: _roundToTwo((json['coefficient'] ?? 1.0).toDouble()),
      deliveryNumber: json['deliveryNumber'] ?? 1,
      totalPaidDistance: _roundToTwo((json['totalPaidDistance'] ?? 0).toDouble()),
      totalIncome: _roundToTwo((json['totalIncome'] ?? 0).toDouble()),
      totalExpenses: _roundToTwo((json['totalExpenses'] ?? 0).toDouble()),
      netProfit: _roundToTwo((json['netProfit'] ?? 0).toDouble()),
      totalTime: json['totalTimeSeconds'] != null ? Duration(seconds: json['totalTimeSeconds']) : Duration.zero,
      shopAddress: json['shopAddress'],
      status: json['status'] ?? 'active',
      deliveries: (json['deliveries'] as List?)?.map((d) => Delivery.fromJson(d)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shiftId': shiftId,
      'serviceName': serviceName,
      'coefficient': _roundToTwo(coefficient),
      'deliveryNumber': deliveryNumber,
      'totalPaidDistance': _roundToTwo(totalPaidDistance),
      'totalIncome': _roundToTwo(totalIncome),
      'totalExpenses': _roundToTwo(totalExpenses),
      'netProfit': _roundToTwo(netProfit),
      'totalTimeSeconds': totalTime.inSeconds,
      'shopAddress': shopAddress,
      'status': status,
      'deliveries': deliveries.map((d) => d.toJson()).toList(),
    };
  }

  static double _roundToTwo(double value) {
    return double.parse(value.toStringAsFixed(2));
  }
}