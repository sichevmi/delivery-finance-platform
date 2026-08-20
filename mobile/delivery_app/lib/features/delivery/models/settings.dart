class Settings {
  final int? id;
  final double fuelConsumption;
  final double fuelPrice;
  final double repairCost;
  final double additionalCosts;
  final int version;

  Settings({
    this.id,
    required this.fuelConsumption,
    required this.fuelPrice,
    required this.repairCost,
    required this.additionalCosts,
    this.version = 1,
  });

  factory Settings.defaults() => Settings(
    fuelConsumption: 10.0,
    fuelPrice: 50.0,
    repairCost: 2.0,
    additionalCosts: 0.0,
  );

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      id: json['id'],
      fuelConsumption: _roundToTwo((json['fuelConsumption'] ?? 10.0).toDouble()),
      fuelPrice: _roundToTwo((json['fuelPrice'] ?? 50.0).toDouble()),
      repairCost: _roundToTwo((json['repairCost'] ?? 2.0).toDouble()),
      additionalCosts: _roundToTwo((json['additionalCosts'] ?? 0.0).toDouble()),
      version: json['version'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fuelConsumption': _roundToTwo(fuelConsumption),
      'fuelPrice': _roundToTwo(fuelPrice),
      'repairCost': _roundToTwo(repairCost),
      'additionalCosts': _roundToTwo(additionalCosts),
    };
  }

  static double _roundToTwo(double value) {
    return double.parse(value.toStringAsFixed(2));
  }
}