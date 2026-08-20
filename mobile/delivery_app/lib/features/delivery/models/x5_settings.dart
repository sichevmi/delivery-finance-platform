class X5Settings {
  final int? id;
  final double pickupPrice;
  final double deliveryPrice;
  final double perKmPrice;
  final double perKgPrice;
  final int version;

  X5Settings({
    this.id,
    required this.pickupPrice,
    required this.deliveryPrice,
    required this.perKmPrice,
    required this.perKgPrice,
    this.version = 1,
  });

  factory X5Settings.defaults() => X5Settings(
    pickupPrice: 250.0,
    deliveryPrice: 150.0,
    perKmPrice: 25.0,
    perKgPrice: 10.0,
  );

  factory X5Settings.fromJson(Map<String, dynamic> json) {
    return X5Settings(
      id: json['id'],
      pickupPrice: _roundToTwo((json['pickupPrice'] ?? 250.0).toDouble()),
      deliveryPrice: _roundToTwo((json['deliveryPrice'] ?? 150.0).toDouble()),
      perKmPrice: _roundToTwo((json['perKmPrice'] ?? 25.0).toDouble()),
      perKgPrice: _roundToTwo((json['perKgPrice'] ?? 10.0).toDouble()),
      version: json['version'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pickupPrice': _roundToTwo(pickupPrice),
      'deliveryPrice': _roundToTwo(deliveryPrice),
      'perKmPrice': _roundToTwo(perKmPrice),
      'perKgPrice': _roundToTwo(perKgPrice),
    };
  }

  static double _roundToTwo(double value) {
    return double.parse(value.toStringAsFixed(2));
  }
}