import 'package:flutter/material.dart';
import 'package:delivery_app/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/features/delivery/providers/shift_provider.dart';

class StartShiftButton extends ConsumerWidget {
  const StartShiftButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftState = ref.watch(shiftProvider);
    final isActive = shiftState.isActive;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          ref.read(shiftProvider.notifier).toggleShift();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.red : const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.stop : Icons.play_arrow,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              isActive ? 'Завершить смену' : '🚀 Начать работу',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}