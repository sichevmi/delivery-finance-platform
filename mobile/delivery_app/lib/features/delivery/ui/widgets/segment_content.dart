import 'package:flutter/material.dart';
import 'package:delivery_app/features/delivery/ui/widgets/weight_input.dart';
import 'package:delivery_app/features/delivery/ui/widgets/apartment_input.dart';

class SegmentContent extends StatelessWidget {
  final int currentSegment;
  final double? weight;
  final bool isWeightValid;
  final String? apartment;
  final bool isApartmentValid;
  final bool isPrivateHouse;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<String> onApartmentChanged;
  final ValueChanged<bool> onPrivateHouseChanged;

  const SegmentContent({
    super.key,
    required this.currentSegment,
    this.weight,
    required this.isWeightValid,
    this.apartment,
    required this.isApartmentValid,
    required this.isPrivateHouse,
    required this.onWeightChanged,
    required this.onApartmentChanged,
    required this.onPrivateHouseChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (currentSegment) {
      case 0:
        return const Text(
          'Пробег до магазина (бесплатный)',
          style: TextStyle(fontSize: 14, color: Colors.white),
        );
      case 1:
        return WeightInput(
          initialWeight: weight ?? 0.0,
          onWeightChanged: onWeightChanged,
        );
      case 2:
        return const Text(
          'Пробег до клиента (платный)',
          style: TextStyle(fontSize: 14, color: Colors.white),
        );
      case 3:
        return ApartmentInput(
          initialApartment: apartment ?? '',
          initialIsPrivateHouse: isPrivateHouse,
          onApartmentChanged: onApartmentChanged,
          onPrivateHouseChanged: onPrivateHouseChanged,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}