import 'package:flutter/material.dart';
import 'package:delivery_app/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/features/delivery/providers/order_route_provider.dart';

class GpsControl extends ConsumerWidget {
  final OrderRouteState state;
  final OrderRouteNotifier notifier;

  const GpsControl({super.key, required this.state, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.currentSegment == 1 || state.currentSegment == 3) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2C2C2C), width: 1),
      ),
      child: Row(
        children: [
          _buildToggleButton('GPS', state.useGps, () {
            notifier.state = notifier.state.copyWith(useGps: true);
            // перезапуск gps
          }),
          const SizedBox(width: 6),
          _buildToggleButton('Вручную', !state.useGps, () {
            notifier.state = notifier.state.copyWith(useGps: false);
          }),
          const Spacer(),
          if (state.useGps)
            Row(
              children: [
                const Icon(Icons.straighten, size: 16, color: Color(0xFF6C63FF)),
                const SizedBox(width: 4),
                Text(
                  '${state.distance.toStringAsFixed(2)} км',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: 60,
              child: TextField(
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: '0.0',
                  hintStyle: TextStyle(color: Color(0xFF666666)),
                ),
                onChanged: (value) {
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed != null && parsed >= 0) {
                    // Обновляем manualDistance через специальный метод
                    notifier.updateManualDistance(parsed);
                  }
                },
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: notifier.togglePause,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: state.isPaused
                    ? Colors.green.withOpacity(0.15)
                    : Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: state.isPaused
                      ? Colors.green.withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    state.isPaused ? Icons.play_arrow : Icons.pause,
                    size: 14,
                    color: state.isPaused ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    state.isPaused ? 'Старт' : 'Пауза',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: state.isPaused ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF2C2C2C),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : const Color(0xFF888888),
          ),
        ),
      ),
    );
  }
}