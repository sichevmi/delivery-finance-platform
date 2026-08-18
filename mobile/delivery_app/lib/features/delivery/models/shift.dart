class Shift {
  final int id;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;
  final double totalPaidDistance;
  final double totalIdleDistance;
  final int ordersCount;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final String status;
  final Duration? totalIdleTime;
  final Duration? totalOrderTime;  // <-- ДОБАВЛЯЕМ

  Shift({
    required this.id,
    required this.startTime,
    this.endTime,
    this.duration,
    this.totalPaidDistance = 0.0,
    this.totalIdleDistance = 0.0,
    this.ordersCount = 0,
    this.totalIncome = 0.0,
    this.totalExpenses = 0.0,
    this.netProfit = 0.0,
    required this.status,
    this.totalIdleTime,
    this.totalOrderTime,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      duration: json['durationSeconds'] != null ? Duration(seconds: json['durationSeconds']) : null,
      totalPaidDistance: (json['totalPaidDistance'] ?? 0).toDouble(),
      totalIdleDistance: (json['totalIdleDistance'] ?? 0).toDouble(),
      ordersCount: json['ordersCount'] ?? 0,
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      totalExpenses: (json['totalExpenses'] ?? 0).toDouble(),
      netProfit: (json['netProfit'] ?? 0).toDouble(),
      status: json['status'] ?? 'active',
      totalIdleTime: json['totalIdleTimeSeconds'] != null 
          ? Duration(seconds: json['totalIdleTimeSeconds']) 
          : null,
      totalOrderTime: json['totalOrderTimeSeconds'] != null 
          ? Duration(seconds: json['totalOrderTimeSeconds']) 
          : null,
    );
  }
}