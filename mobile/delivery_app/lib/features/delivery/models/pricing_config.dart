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
      receivingFee: 75.0,
      deliveryFee: 105.0,
      pricePerKg: 2.0,
      pricePerKm: 30.0,
    );
  }
}