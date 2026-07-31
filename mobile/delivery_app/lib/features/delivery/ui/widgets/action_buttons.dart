import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/delivery/providers/order_route_provider.dart';

class ActionButtons extends ConsumerWidget {
  final OrderRouteState state;
  final OrderRouteNotifier notifier;

  const ActionButtons({super.key, required this.state, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String mainButtonText = 'Далее';
    bool isMainEnabled = true;

    final deliveryLabel = state.deliveryNumber > 1 ? ' #${state.deliveryNumber}' : '';

    switch (state.currentSegment) {
      case 0:
        mainButtonText = 'Получить бандероль';
        isMainEnabled = true;
        break;
      case 1:
        mainButtonText = 'Выехал к получателю$deliveryLabel';
        isMainEnabled = state.isWeightValid;
        break;
      case 2:
        mainButtonText = 'Выдать бандероль$deliveryLabel';
        isMainEnabled = true;
        break;
      case 3:
        mainButtonText = 'Завершить доставку$deliveryLabel';
        isMainEnabled = state.isPrivateHouse || state.isApartmentValid;
        break;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isMainEnabled ? () => notifier.handleMainAction() : null,
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