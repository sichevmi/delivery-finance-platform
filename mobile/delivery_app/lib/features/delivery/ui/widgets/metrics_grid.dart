import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/delivery/providers/metrics_provider.dart';
import 'metric_card.dart';

class MetricsGrid extends ConsumerWidget {
  const MetricsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(metricsProvider);

    // Создаём пары карточек (5 строк по 2)
    final pairs = [
      [
        MetricCard(
          icon: Icons.attach_money,
          value: '${metrics.profit} ₽',
          label: 'Оплата за заказы',
          iconColor: Colors.green,
        ),
        MetricCard(
          icon: Icons.trending_up,
          value: '${metrics.netIncome} ₽',
          label: 'Чистая прибыль',
          iconColor: const Color(0xFF6C63FF),
        ),
      ],
      [
        MetricCard(
          icon: Icons.shopping_bag_outlined,
          value: metrics.orders.toString(),
          label: 'Кол-во заказов',
          iconColor: Colors.blue,
        ),
        MetricCard(
          icon: Icons.money_off_outlined,
          value: '${metrics.profit - metrics.netIncome} ₽',
          label: 'Расходы',
          iconColor: Colors.red,
        ),
      ],
      [
        MetricCard(
          icon: Icons.route,
          value: '${metrics.kmPerOrder} км',
          label: 'Пробег/заказ',
          iconColor: Colors.orange,
        ),
        MetricCard(
          icon: Icons.ev_station,
          value: '${metrics.idleKm} км',
          label: 'Холостой пробег',
          iconColor: Colors.amber,
        ),
      ],
      [
        MetricCard(
          icon: Icons.access_time,
          value: '${metrics.timePerOrder} мин',
          label: 'Время заказа',
          iconColor: Colors.purple,
        ),
        MetricCard(
          icon: Icons.receipt_long,
          value: '${metrics.checkPerOrder} ₽',
          label: 'Чек/заказ',
          iconColor: Colors.teal,
        ),
      ],
      [
        MetricCard(
          icon: Icons.timer,
          value: '${metrics.workTime} ч',
          label: 'Время работы',
          iconColor: Colors.indigo,
        ),
        MetricCard(
          icon: Icons.pause_circle_outline,
          value: '${metrics.downtime} ч',
          label: 'Время простоя',
          iconColor: Colors.red,
        ),
      ],
    ];

    // Растягиваем строки на всю доступную высоту
    return Column(
      children: pairs.map((pair) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: pair[0]),
                const SizedBox(width: 10),
                Expanded(child: pair[1]),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}