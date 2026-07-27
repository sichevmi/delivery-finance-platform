import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/delivery/providers/tab_provider.dart';
import 'package:delivery_app/features/delivery/providers/pricing_provider.dart';
import 'order_route_screen.dart';

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

    // Берём первую доставку для общих данных
    final firstDelivery = deliveries.isNotEmpty ? deliveries.first : null;

    // Данные по магазину (только из первой доставки)
    final shopTime = firstDelivery?.timeToShop ?? 0;
    final shopDistance = firstDelivery?.distanceToShop ?? 0.0;
    final receivingTime = firstDelivery?.timeReceiving ?? 0;

    // Рассчитываем стоимость магазина (получение + вес)
    final shopWeight = firstDelivery?.weight ?? 0.0;
    final shopCost = pricing.receivingFee + (shopWeight * pricing.pricePerKg);

    // Рассчитываем стоимость каждой доставки
    double totalDeliveriesCost = 0.0;
    for (final d in deliveries) {
      final deliveryCost = pricing.deliveryFee + (d.distanceToClient * pricing.pricePerKm);
      totalDeliveriesCost += deliveryCost;
    }

    // Общая стоимость = магазин + все доставки
    final totalCostFinal = shopCost + totalDeliveriesCost;

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
                    fontSize: 18,
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
                      fontSize: 12,
                      color: Color(0xFF6C63FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Карточка "Магазин"
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2C2C2C)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront, size: 18, color: Color(0xFF6C63FF)),
                      const SizedBox(width: 8),
                      const Text(
                        'Магазин',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildDetailChip(Icons.access_time, 'В пути: ${_formatTime(shopTime)}'),
                      const SizedBox(width: 6),
                      _buildDetailChip(Icons.route, '${shopDistance.toStringAsFixed(2)} км'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildDetailChip(Icons.fitness_center, 'Вес: ${shopWeight.toStringAsFixed(1)} кг'),
                      const SizedBox(width: 6),
                      _buildDetailChip(Icons.timer, 'Получение: ${_formatTime(receivingTime)}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildDetailChip(
                        Icons.attach_money,
                        'Стоимость: ${shopCost.toStringAsFixed(0)} руб.',
                        color: const Color(0xFF6C63FF),
                      ),
                      const SizedBox(width: 6),
                      _buildDetailChip(
                        Icons.info_outline,
                        '(${pricing.receivingFee.toStringAsFixed(0)} руб. + ${shopWeight.toStringAsFixed(1)} кг × ${pricing.pricePerKg.toStringAsFixed(0)} руб.)',
                        color: const Color(0xFF888888),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Список доставок
            Expanded(
              child: ListView.separated(
                itemCount: deliveries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final d = deliveries[index];
                  final deliveryCost = pricing.deliveryFee + (d.distanceToClient * pricing.pricePerKm);
                  return _buildDeliveryCard(d, deliveryCost, pricing);
                },
              ),
            ),

            const SizedBox(height: 12),

            // Итоги
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2C2C2C)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Общее время', style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
                        Text(_formatTime(totalTime), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Общий пробег', style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
                        Text('${totalDistance.toStringAsFixed(2)} км', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Итого', style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
                        Text('${totalCostFinal.toStringAsFixed(0)} руб.', style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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

  Widget _buildDeliveryCard(Delivery d, double deliveryCost, PricingConfig pricing) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
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
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.clientAddress,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'кв. ${d.apartment}',
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${deliveryCost.toStringAsFixed(0)} руб.',
                  style: const TextStyle(
                    color: Color(0xFF6C63FF),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildDetailChip(Icons.route, '${d.distanceToClient.toStringAsFixed(2)} км'),
              _buildDetailChip(Icons.access_time, 'В пути: ${_formatTime(d.timeToClient)}'),
              _buildDetailChip(Icons.home, 'Выдача: ${_formatTime(d.timeDelivery)}'),
              _buildDetailChip(
                Icons.attach_money,
                '${pricing.deliveryFee.toStringAsFixed(0)} руб. + ${d.distanceToClient.toStringAsFixed(1)} км × ${pricing.pricePerKm.toStringAsFixed(0)} руб.',
                color: const Color(0xFF888888),
                fontSize: 10,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text, {Color color = const Color(0xFF888888), double fontSize = 11}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}