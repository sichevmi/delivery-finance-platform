import 'package:flutter_riverpod/flutter_riverpod.dart';

class PricingConfig {
  final double pricePerKg; // цена за кг
  final double receivingFee; // получение в магазине
  final double deliveryFee; // выдача
  final double pricePerKm; // цена за км

  const PricingConfig({
    this.pricePerKg = 2.0,
    this.receivingFee = 75.0,
    this.deliveryFee = 105.0,
    this.pricePerKm = 30.0,
  });
}

final pricingProvider = Provider<PricingConfig>((ref) {
  return const PricingConfig();
});