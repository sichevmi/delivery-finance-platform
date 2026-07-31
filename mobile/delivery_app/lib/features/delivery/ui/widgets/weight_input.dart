import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/delivery/providers/order_route_provider.dart';

class WeightInput extends ConsumerWidget {
  final OrderRouteState state;
  final OrderRouteNotifier notifier;

  const WeightInput({super.key, required this.state, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Введите вес бандероли', style: TextStyle(fontSize: 14, color: Colors.white)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: state.isWeightValid ? const Color(0xFF6C63FF) : const Color(0xFF2C2C2C),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fitness_center, size: 18, color: Color(0xFF6C63FF)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Вес', style: TextStyle(fontSize: 11, color: Color(0xFF888888))),
                          TextField(
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              hintText: '0.0',
                              hintStyle: TextStyle(color: Color(0xFF666666)),
                            ),
                            onChanged: (value) {
                              final parsed = double.tryParse(value.replaceAll(',', '.'));
                              notifier.state = notifier.state.copyWith(
                                weight: (parsed != null && parsed > 0) ? parsed : null,
                                isWeightValid: parsed != null && parsed > 0,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    if (state.isWeightValid)
                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}