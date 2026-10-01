// models/shift.dart
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
  final Duration? totalOrderTime;
  final int? durationSeconds;
  final int? totalOrderTimeSeconds;

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
    this.durationSeconds,
    this.totalOrderTimeSeconds,
  });

  /// Парсит дату из строки и приводит к ЛОКАЛЬНОМУ времени.
  /// Если пришло без таймзоны — считаем UTC.
  static DateTime _parseLocal(dynamic value) {
    if (value is DateTime) return value.toLocal();
    final s = value.toString();
    final parsed = DateTime.parse(s);
    // Если строка без таймзоны (нет 'Z' и нет '+/-' в конце) — считаем UTC
    if (!s.contains('Z') && !s.contains('+') && !RegExp(r'-\d{2}:\d{2}$').hasMatch(s)) {
      return DateTime.utc(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
        parsed.millisecond,
        parsed.microsecond,
      ).toLocal();
    }
    return parsed.toLocal();
  }

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'],
      startTime: _parseLocal(json['startTime']),
      endTime: json['endTime'] != null ? _parseLocal(json['endTime']) : null,
      duration: json['durationSeconds'] != null
          ? Duration(seconds: json['durationSeconds'])
          : null,
      totalPaidDistance: _roundToTwo((json['totalPaidDistance'] ?? 0).toDouble()),
      totalIdleDistance: _roundToTwo((json['totalIdleDistance'] ?? 0).toDouble()),
      ordersCount: json['ordersCount'] ?? 0,
      totalIncome: _roundToTwo((json['totalIncome'] ?? 0).toDouble()),
      totalExpenses: _roundToTwo((json['totalExpenses'] ?? 0).toDouble()),
      netProfit: _roundToTwo((json['netProfit'] ?? 0).toDouble()),
      status: json['status'] ?? 'active',
      totalIdleTime: json['totalIdleTimeSeconds'] != null
          ? Duration(seconds: json['totalIdleTimeSeconds'])
          : null,
      totalOrderTime: json['totalOrderTimeSeconds'] != null
          ? Duration(seconds: json['totalOrderTimeSeconds'])
          : null,
      durationSeconds: json['durationSeconds'],
      totalOrderTimeSeconds: json['totalOrderTimeSeconds'],
    );
  }

  static double _roundToTwo(double value) {
    return double.parse(value.toStringAsFixed(2));
  }
}