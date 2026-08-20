class PricingConfig {
  final int? id;
  final double receivingFee;
  final double deliveryFee;
  final double pricePerKg;
  final double pricePerKm;
  final double baseCoefficient;
  final int version;

  PricingConfig({
    this.id,
    required this.receivingFee,
    required this.deliveryFee,
    required this.pricePerKg,
    required this.pricePerKm,
    required this.baseCoefficient,
    this.version = 1,
  });

  factory PricingConfig.defaults() => PricingConfig(
    receivingFee: 50.0,
    deliveryFee: 100.0,
    pricePerKg: 5.0,
    pricePerKm: 10.0,
    baseCoefficient: 1.0,
  );

  factory PricingConfig.fromJson(Map<String, dynamic> json) {
    return PricingConfig(
      id: json['id'],
      receivingFee: _roundToTwo((json['receivingFee'] ?? 50.0).toDouble()),
      deliveryFee: _roundToTwo((json['deliveryFee'] ?? 100.0).toDouble()),
      pricePerKg: _roundToTwo((json['pricePerKg'] ?? 5.0).toDouble()),
      pricePerKm: _roundToTwo((json['pricePerKm'] ?? 10.0).toDouble()),
      baseCoefficient: _roundToTwo((json['baseCoefficient'] ?? 1.0).toDouble()),
      version: json['version'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receivingFee': _roundToTwo(receivingFee),
      'deliveryFee': _roundToTwo(deliveryFee),
      'pricePerKg': _roundToTwo(pricePerKg),
      'pricePerKm': _roundToTwo(pricePerKm),
      'baseCoefficient': _roundToTwo(baseCoefficient),
    };
  }

  static double _roundToTwo(double value) {
    return double.parse(value.toStringAsFixed(2));
  }
}