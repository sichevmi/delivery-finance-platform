import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/delivery/services/logger.dart';

class Metrics {
  final int orders;
  final double profit;
  final double netIncome;
  final double kmPerOrder;
  final int timePerOrder;
  final double checkPerOrder;
  final double workTime;
  final double downtime;
  final double idleKm;

  Metrics({
    this.orders = 45,
    this.profit = 12500,
    this.netIncome = 8200,
    this.kmPerOrder = 2.3,
    this.timePerOrder = 25,
    this.checkPerOrder = 1200,
    this.workTime = 4.5,
    this.downtime = 1.2,
    this.idleKm = 0.8,
  });

  Metrics copyWith({
    int? orders,
    double? profit,
    double? netIncome,
    double? kmPerOrder,
    int? timePerOrder,
    double? checkPerOrder,
    double? workTime,
    double? downtime,
    double? idleKm,
  }) {
    return Metrics(
      orders: orders ?? this.orders,
      profit: profit ?? this.profit,
      netIncome: netIncome ?? this.netIncome,
      kmPerOrder: kmPerOrder ?? this.kmPerOrder,
      timePerOrder: timePerOrder ?? this.timePerOrder,
      checkPerOrder: checkPerOrder ?? this.checkPerOrder,
      workTime: workTime ?? this.workTime,
      downtime: downtime ?? this.downtime,
      idleKm: idleKm ?? this.idleKm,
    );
  }
}

final metricsProvider = Provider<Metrics>((ref) {
  // В будущем здесь будет загрузка с сервера или из БД
  return Metrics();
});