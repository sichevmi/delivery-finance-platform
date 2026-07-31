class PricingConfig {
  final double receivingFee;
  final double deliveryFee;
  final double pricePerKg;
  final double pricePerKm;

  const PricingConfig({
    required this.receivingFee,
    required this.deliveryFee,
    required this.pricePerKg,
    required this.pricePerKm,
  });

  factory PricingConfig.defaultConfig() {
    return const PricingConfig(
      receivingFee: 50.0,
      deliveryFee: 100.0,
      pricePerKg: 10.0,
      pricePerKm: 15.0,
    );
  }
}