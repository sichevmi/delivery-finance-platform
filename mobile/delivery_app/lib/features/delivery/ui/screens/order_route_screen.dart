import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/delivery/providers/order_route_provider.dart';
import 'package:delivery_app/features/delivery/ui/widgets/segment_progress.dart';
import 'package:delivery_app/features/delivery/ui/widgets/order_card.dart';
import 'package:delivery_app/features/delivery/ui/widgets/gps_control.dart';
import 'package:delivery_app/features/delivery/ui/widgets/segment_content.dart';
import 'package:delivery_app/features/delivery/ui/widgets/action_buttons.dart';
import 'package:delivery_app/features/delivery/ui/screens/order_summary_screen.dart';
import 'package:delivery_app/features/delivery/providers/pricing_provider.dart';

class OrderRouteScreen extends ConsumerStatefulWidget {
  final String serviceName;
  final double coefficient;
  final int segmentIndex;

  const OrderRouteScreen({
    super.key,
    required this.serviceName,
    required this.coefficient,
    required this.segmentIndex,
  });

  @override
  ConsumerState<OrderRouteScreen> createState() => _OrderRouteScreenState();
}

class _OrderRouteScreenState extends ConsumerState<OrderRouteScreen> {
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderRouteProvider.notifier).init(
            coefficient: widget.coefficient,
            segmentIndex: widget.segmentIndex,
          );
    });
  }

  @override
  void dispose() {
    ref.read(orderRouteProvider.notifier).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderRouteProvider);
    final notifier = ref.read(orderRouteProvider.notifier);
    final pricing = ref.watch(pricingProvider);

    // Если доставка только что завершена и мы ещё не начали навигацию
    if (state.isDeliveryComplete && !_isNavigating) {
      _isNavigating = true;
      // Получаем последнюю доставку
      final lastDelivery = state.completedDeliveries.last;
      // Рассчитываем итоговые показатели для одной доставки
      final totalTime = _calculateTotalTime(state);
      final totalDistance = _calculateTotalDistance(state);
      final totalCost = _calculateTotalCost(state, pricing);

      // Переходим на экран итогов
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => OrderSummaryScreen(
              serviceName: widget.serviceName,
              coefficient: state.coefficient,
              deliveries: state.completedDeliveries,
              totalCost: totalCost,
              totalTime: totalTime,
              totalDistance: totalDistance,
            ),
          ),
        );

        // Сбрасываем флаг и решаем, что делать дальше
        _isNavigating = false;
        if (result == true) {
          // Пользователь выбрал "Продолжить" – начинаем следующую доставку
          notifier.startNextDelivery();
        } else {
          // Пользователь выбрал "Завершить" или закрыл экран
          notifier.finishOrder();
          // Дополнительно можно закрыть текущий экран и перейти на главную
          Navigator.of(context, rootNavigator: false).pop();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.serviceName),
            if (state.deliveryNumber > 1) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Доставка #${state.deliveryNumber}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          TextButton(
            onPressed: () => notifier.cancelOrder(),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Отменить', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentProgress(currentSegment: state.currentSegment),
            const SizedBox(height: 12),
            OrderCard(state: state),
            const SizedBox(height: 10),
            GpsControl(state: state, notifier: notifier),
            const SizedBox(height: 12),
            SegmentContent(state: state, notifier: notifier),
            const SizedBox(height: 20),
            ActionButtons(state: state, notifier: notifier),
          ],
        ),
      ),
    );
  }

  // Вспомогательные методы для расчёта итогов (можно вынести в отдельный файл)
  int _calculateTotalTime(OrderRouteState state) {
    if (state.completedDeliveries.isEmpty) return 0;
    final first = state.completedDeliveries.first;
    int total = first.timeToShop + first.timeReceiving;
    for (final d in state.completedDeliveries) {
      total += d.timeToClient + d.timeDelivery;
    }
    return total;
  }

  double _calculateTotalDistance(OrderRouteState state) {
    if (state.completedDeliveries.isEmpty) return 0.0;
    double total = state.completedDeliveries.first.distanceToShop;
    for (final d in state.completedDeliveries) {
      total += d.distanceToClient;
    }
    return total;
  }

  double _calculateTotalCost(OrderRouteState state, PricingConfig pricing) {
    if (state.completedDeliveries.isEmpty) return 0.0;
    final first = state.completedDeliveries.first;
    double total = (pricing.receivingFee + (first.weight * pricing.pricePerKg)) * state.coefficient;
    for (final d in state.completedDeliveries) {
      total += (pricing.deliveryFee + (d.distanceToClient * pricing.pricePerKm)) * state.coefficient;
    }
    return total;
  }
}