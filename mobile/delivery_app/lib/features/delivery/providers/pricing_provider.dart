import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/delivery/models/pricing_config.dart';

final pricingProvider = Provider<PricingConfig>((ref) {
  return PricingConfig.defaultConfig();
});