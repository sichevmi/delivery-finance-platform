import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final int currentSegment;
  final int deliveryNumber;
  final bool isWeightValid;
  final bool isApartmentValid;
  final bool isPrivateHouse;
  final VoidCallback onMainAction;

  const ActionButtons({
    super.key,
    required this.currentSegment,
    required this.deliveryNumber,
    required this.isWeightValid,
    required this.isApartmentValid,
    required this.isPrivateHouse,
    required this.onMainAction,
  });

  @override
  Widget build(BuildContext context) {
    String mainButtonText = 'Далее';
    bool isMainEnabled = true;

    final deliveryLabel = deliveryNumber > 1 ? ' #$deliveryNumber' : '';

    switch (currentSegment) {
      case 0:
        mainButtonText = 'Получить бандероль';
        isMainEnabled = true;
        break;
      case 1:
        mainButtonText = 'Выехал к получателю$deliveryLabel';
        isMainEnabled = isWeightValid;
        break;
      case 2:
        mainButtonText = 'Выдать бандероль$deliveryLabel';
        isMainEnabled = true;
        break;
      case 3:
        mainButtonText = 'Завершить доставку$deliveryLabel';
        isMainEnabled = isPrivateHouse || isApartmentValid;
        break;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isMainEnabled ? onMainAction : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isMainEnabled ? const Color(0xFF6C63FF) : const Color(0xFF2C2C2C),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          mainButtonText,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isMainEnabled ? Colors.white : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}