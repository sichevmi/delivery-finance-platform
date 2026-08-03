import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/delivery/providers/tab_provider.dart';
import 'package:delivery_app/features/delivery/providers/pricing_provider.dart';
import 'package:delivery_app/features/delivery/models/delivery.dart';
import 'package:delivery_app/features/delivery/models/pricing_config.dart';

class OrderSummaryScreen extends ConsumerWidget {
  final String serviceName;
  final double coefficient;
  final List<Delivery> deliveries;
  final double totalCost;
  final int totalTime;
  final double totalDistance;

  const OrderSummaryScreen({
    super.key,
    required this.serviceName,
    required this.coefficient,
    required this.deliveries,
    required this.totalCost,
    required this.totalTime,
    required this.totalDistance,
  });

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricing = ref.watch(pricingProvider);

    final firstDelivery = deliveries.isNotEmpty ? deliveries.first : null;

    // Данные по магазину
    final shopDistance = firstDelivery?.distanceToShop ?? 0.0;
    final shopWeight = firstDelivery?.weight ?? 0.0;
    final shopCost = (pricing.receivingFee + (shopWeight * pricing.pricePerKg)) * coefficient;

    // Расходы (бензин) – пока заглушка
    final fuelConsumption = 0.0;
    final fuelPrice = 0.0;
    final totalFuelLiters = totalDistance * (fuelConsumption / 100);
    final totalFuelCost = totalFuelLiters * fuelPrice;
    final totalExpenses = totalFuelCost;

    // Рассчитываем стоимость каждой доставки
    double totalDeliveriesCost = 0.0;
    for (final d in deliveries) {
      final deliveryCost = (pricing.deliveryFee + (d.distanceToClient * pricing.pricePerKm)) * coefficient;
      totalDeliveriesCost += deliveryCost;
    }

    final totalCostFinal = shopCost + totalDeliveriesCost;
    final netProfit = totalCostFinal - totalExpenses;

    return Scaffold(
      appBar: AppBar(
        title: Text('Сводка заказа • $serviceName'),
        backgroundColor: const Color(0xFF1E1E1E),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с количеством доставок
            Row(
              children: [
                const Icon(Icons.receipt_long, color: Color(0xFF6C63FF), size: 24),
                const SizedBox(width: 8),
                Text(
                  'Доставок: ${deliveries.length}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Коэф. ${coefficient.toString()}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6C63FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Карточка "Магазин" (укрупнённая)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2C2C2C)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront, size: 22, color: Color(0xFF6C63FF)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Магазин',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _buildChip(Icons.route, '${shopDistance.toStringAsFixed(2)} км', size: 14),
                            _buildChip(Icons.fitness_center, '${shopWeight.toStringAsFixed(1)} кг', size: 14),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${shopCost.toStringAsFixed(0)} руб.',
                      style: const TextStyle(
                        color: Color(0xFF6C63FF),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Список доставок (укрупнённый)
            Expanded(
              child: ListView.separated(
                itemCount: deliveries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final d = deliveries[index];
                  final deliveryCost = (pricing.deliveryFee + (d.distanceToClient * pricing.pricePerKm)) * coefficient;
                  return _buildDeliveryCard(d, deliveryCost);
                },
              ),
            ),

            const SizedBox(height: 12),

            // Итоги (укрупнённые, симметричные)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2C2C2C)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Общее время – слева
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Общее время',
                              style: TextStyle(color: Color(0xFF888888), fontSize: 12),
                            ),
                            Text(
                              _formatTime(totalTime),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Платный пробег – справа
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Платный пробег',
                              style: TextStyle(color: Color(0xFF888888), fontSize: 12),
                            ),
                            Text(
                              '${totalDistance.toStringAsFixed(2)} км',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF2C2C2C), height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Стоимость заказа',
                              style: TextStyle(color: Color(0xFF888888), fontSize: 12),
                            ),
                            Text(
                              '${totalCostFinal.toStringAsFixed(0)} руб.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Чистая прибыль',
                              style: TextStyle(color: Color(0xFF888888), fontSize: 12),
                            ),
                            Text(
                              '${netProfit.toStringAsFixed(0)} руб.',
                              style: TextStyle(
                                color: netProfit >= 0 ? Colors.green : Colors.red,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (totalExpenses > 0) ...[
                    const Divider(color: Color(0xFF2C2C2C), height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Расходы',
                                style: TextStyle(color: Color(0xFF888888), fontSize: 12),
                              ),
                              Text(
                                'Бензин: ${totalFuelLiters.toStringAsFixed(1)} л × ${fuelPrice.toStringAsFixed(0)} руб.',
                                style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '-${totalExpenses.toStringAsFixed(0)} руб.',
                          style: const TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Кнопки
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6C63FF),
                      side: const BorderSide(color: Color(0xFF6C63FF)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Добавить ещё доставку',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Завершить заказ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(Delivery d, double deliveryCost) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFF6C63FF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${d.number}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.clientAddress,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'кв. ${d.apartment}',
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                _buildChip(Icons.route, '${d.distanceToClient.toStringAsFixed(2)} км', size: 13),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${deliveryCost.toStringAsFixed(0)} руб.',
              style: const TextStyle(
                color: Color(0xFF6C63FF),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String text, {double size = 12}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: size, color: const Color(0xFF888888)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: size,
              color: const Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }
}