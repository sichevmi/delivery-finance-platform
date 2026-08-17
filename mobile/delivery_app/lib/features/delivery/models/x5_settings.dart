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
      pickupPrice: (json['pickupPrice'] ?? 250.0).toDouble(),
      deliveryPrice: (json['deliveryPrice'] ?? 150.0).toDouble(),
      perKmPrice: (json['perKmPrice'] ?? 25.0).toDouble(),
      perKgPrice: (json['perKgPrice'] ?? 10.0).toDouble(),
      version: json['version'] ?? 1,
    );
  }
}