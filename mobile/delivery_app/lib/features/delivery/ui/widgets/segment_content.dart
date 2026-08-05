import 'package:flutter/material.dart';
import 'package:delivery_app/features/delivery/services/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/delivery/services/logger.dart';
import 'package:delivery_app/features/delivery/providers/order_route_provider.dart';
import 'package:delivery_app/features/delivery/ui/widgets/weight_input.dart';
import 'package:delivery_app/features/delivery/ui/widgets/apartment_input.dart';

class SegmentContent extends ConsumerWidget {
  final OrderRouteState state;
  final OrderRouteNotifier notifier;

  const SegmentContent({super.key, required this.state, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (state.currentSegment) {
      case 0:
        return const Text(
          'Пробег до магазина (бесплатный)',
          style: TextStyle(fontSize: 14, color: Colors.white),
        );
      case 1:
        return WeightInput(state: state, notifier: notifier);
      case 2:
        return const Text(
          'Пробег до клиента (платный)',
          style: TextStyle(fontSize: 14, color: Colors.white),
        );
      case 3:
        return ApartmentInput(state: state, notifier: notifier);
      default:
        return const SizedBox.shrink();
    }
  }
}