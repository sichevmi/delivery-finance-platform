import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/delivery/providers/order_route_provider.dart';
import 'package:delivery_app/features/delivery/providers/pricing_provider.dart';

class OrderCard extends ConsumerWidget {
  final OrderRouteState state;

  const OrderCard({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricing = ref.watch(pricingProvider);
    final deliveryLabel = state.deliveryNumber > 1 ? 'Доставка #${state.deliveryNumber}' : 'Заказ';

    double cost = 0;
    if (state.currentSegment >= 2 && state.weight != null) {
      cost = (pricing.receivingFee + (state.weight! * pricing.pricePerKg)) * state.coefficient;
      if (state.currentSegment == 3) {
        cost += (pricing.deliveryFee + (state.distance * pricing.pricePerKm)) * state.coefficient;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6C63FF), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(deliveryLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'К: ${state.coefficient.toString()}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6C63FF), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (state.shopAddress != null)
            _buildInfoLine(Icons.storefront, 'Магазин', state.shopAddress!),
          if (state.clientAddress != null && state.currentSegment >= 2)
            _buildInfoLine(Icons.location_on, 'Клиент', state.clientAddress!),
          if (state.weight != null)
            _buildInfoLine(Icons.fitness_center, 'Вес', '${state.weight!.toStringAsFixed(1)} кг'),
          if (cost > 0)
            _buildInfoLine(Icons.attach_money, 'Стоимость', '${cost.toStringAsFixed(0)} руб.'),
        ],
      ),
    );
  }

  Widget _buildInfoLine(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6C63FF)),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}