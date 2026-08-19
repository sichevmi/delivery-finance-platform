import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/features/delivery/providers/tab_provider.dart';
import 'package:delivery_app/features/delivery/providers/pricing_provider.dart';
import 'package:delivery_app/features/delivery/providers/settings_provider.dart';
import 'package:delivery_app/features/delivery/providers/daily_stats_provider.dart';
import 'package:delivery_app/features/delivery/models/delivery.dart';
import 'package:delivery_app/features/delivery/models/pricing_config.dart';

class OrderSummaryScreen extends ConsumerWidget {
  final String serviceName;
  final double coefficient;
  final List<Delivery> deliveries;
  final double totalCost;
  final int totalTime;
  final double totalDistance;
  final String? shopAddress; // <-- ДОБАВЛЯЕМ

  const OrderSummaryScreen({
    super.key,
    required this.serviceName,
    required this.coefficient,
    required this.deliveries,
    required this.totalCost,
    required this.totalTime,
    required this.totalDistance,
    this.shopAddress, // <-- ДОБАВЛЯЕМ
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
    final settings = ref.watch(settingsProvider);

    final firstDelivery = deliveries.isNotEmpty ? deliveries.first : null;

    // Данные по магазину
    final shopDistance = firstDelivery?.distanceToShop ?? 0.0;
    final shopWeight = firstDelivery?.weight ?? 0.0;
    final shopCost = (pricing.receivingFee + (shopWeight * pricing.pricePerKg)) * coefficient;

    // Платный пробег = сумма расстояний до клиентов по всем доставкам
    final totalPaidDistance = deliveries.fold(0.0, (sum, d) => sum + d.distanceToClient);

    // ОБЩИЙ пробег = пробег до магазина + все платные пробеги
    final totalAllDistance = shopDistance + totalPaidDistance;

    // ===== РАСЧЁТ РАСХОДОВ (из справочника) =====
    final fuelCostPerKm = (settings.fuelConsumption / 100) * settings.fuelPrice;
    final totalFuelCost = totalAllDistance * fuelCostPerKm;
    final totalRepairCost = totalAllDistance * settings.repairCost;
    final totalExpenses = totalFuelCost + totalRepairCost;

    // Рассчитываем стоимость каждой доставки
    double totalDeliveriesCost = 0.0;
    for (final d in deliveries) {
      final deliveryCost = (pricing.deliveryFee + (d.distanceToClient * pricing.pricePerKm)) * coefficient;
      totalDeliveriesCost += deliveryCost;
    }

    final totalCostFinal = shopCost + totalDeliveriesCost;
    final netProfit = totalCostFinal - totalExpenses;

    // ===== ПОКАЗЫВАЕМ АДРЕС МАГАЗИНА =====
    final displayShopAddress = shopAddress ?? 'Адрес не определён';

    logMessage('🟢 OrderSummaryScreen: отображение сводки');
    logMessage('   shopAddress: $displayShopAddress');
    logMessage('   totalAllDistance: $totalAllDistance');
    logMessage('   totalExpenses: $totalExpenses');
    logMessage('   totalCostFinal: $totalCostFinal');
    logMessage('   netProfit: $netProfit');

    return Scaffold(
      appBar: AppBar(
        title: Text('Сводка заказа • $serviceName'),
        backgroundColor: const Color(0xFF1E1E1E),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // ===== СКРОЛЛИРУЕМАЯ ЧАСТЬ =====
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок
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
                  const SizedBox(height: 12),

                  // ===== КАРТОЧКА "МАГАЗИН" =====
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2C2C2C)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront, size: 20, color: Color(0xFF6C63FF)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Магазин',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // ===== АДРЕС МАГАЗИНА (ВСЕГДА ПОКАЗЫВАЕМ) =====
                              Text(
                                displayShopAddress,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6C63FF),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 2,
                                children: [
                                  _buildChip(Icons.route, '${shopDistance.toStringAsFixed(2)} км', size: 12),
                                  _buildChip(Icons.fitness_center, '${shopWeight.toStringAsFixed(1)} кг', size: 12),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${shopCost.toStringAsFixed(0)} руб.',
                            style: const TextStyle(
                              color: Color(0xFF6C63FF),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Список доставок
                  ...deliveries.map((d) {
                    final deliveryCost = (pricing.deliveryFee + (d.distanceToClient * pricing.pricePerKm)) * coefficient;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildDeliveryCard(d, deliveryCost),
                    );
                  }).toList(),

                  // Дополнительная информация о расходах
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2C2C2C)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📊 Детали расчёта',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow('Общий пробег', '${totalAllDistance.toStringAsFixed(2)} км'),
                        _buildDetailRow('Стоимость бензина на 1 км', '${fuelCostPerKm.toStringAsFixed(4)} руб.'),
                        _buildDetailRow('Стоимость ремонта на 1 км', '${settings.repairCost.toStringAsFixed(2)} руб.'),
                        const Divider(color: Color(0xFF2C2C2C), height: 12),
                        _buildDetailRow('Расход на бензин', '${totalFuelCost.toStringAsFixed(0)} руб.', bold: true),
                        _buildDetailRow('Расход на ремонт', '${totalRepairCost.toStringAsFixed(0)} руб.', bold: true),
                        _buildDetailRow('Итого расходы', '${totalExpenses.toStringAsFixed(0)} руб.', 
                          bold: true, 
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== НИЖНЯЯ ЧАСТЬ (фиксированная) =====
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              border: Border(
                top: BorderSide(color: const Color(0xFF2C2C2C), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Итоги
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Общее время', style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
                          Text(_formatTime(totalTime), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Платный пробег', style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
                          Text('${totalPaidDistance.toStringAsFixed(2)} км', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Стоимость заказа', style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
                          Text('${totalCostFinal.toStringAsFixed(0)} руб.', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Чистая прибыль', style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
                          Text(
                            '${netProfit.toStringAsFixed(0)} руб.',
                            style: TextStyle(
                              color: netProfit >= 0 ? Colors.green : Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Кнопки
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          logMessage('🟢 Нажата кнопка "Добавить ещё доставку"');
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          logMessage('🟢 Нажата кнопка "Завершить заказ"');
                          ref.invalidate(dailyStatsProvider);
                          logMessage('📊 Статистика обновлена', category: 'STATS');
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
                            fontSize: 14,
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
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(Delivery d, double deliveryCost) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
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
                  fontSize: 13,
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
                  softWrap: true,
                ),
                const SizedBox(height: 2),
                Text(
                  'кв. ${d.apartment}',
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                _buildChip(Icons.route, '${d.distanceToClient.toStringAsFixed(2)} км', size: 12),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${deliveryCost.toStringAsFixed(0)} руб.',
              style: const TextStyle(
                color: Color(0xFF6C63FF),
                fontSize: 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(10),
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

  Widget _buildDetailRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF888888),
              fontSize: bold ? 13 : 12,
              fontWeight: bold ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}