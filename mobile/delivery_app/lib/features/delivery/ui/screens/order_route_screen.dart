import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/delivery/providers/order_route_provider.dart';
import 'package:delivery_app/features/delivery/ui/widgets/segment_progress.dart';
import 'package:delivery_app/features/delivery/ui/widgets/order_card.dart';
import 'package:delivery_app/features/delivery/ui/widgets/gps_control.dart';
import 'package:delivery_app/features/delivery/ui/widgets/segment_content.dart';
import 'package:delivery_app/features/delivery/ui/widgets/action_buttons.dart';
import 'order_summary_screen.dart';
import 'package:delivery_app/features/delivery/providers/pricing_provider.dart';
import 'package:delivery_app/features/delivery/models/pricing_config.dart';

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
  bool _isSummaryShown = false;

  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final notifier = ref.read(orderRouteProvider.notifier);
    notifier.resetToInitial(); // Обязательно сбрасываем
    notifier.init(
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

    // Обработка отмены заказа
    if (state.shouldNavigateToHome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.resetNavigationFlag();
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
    }

    // Показываем экран итогов
    if (state.showSummary && !_isSummaryShown) {
      _isSummaryShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSummary(context, state, notifier);
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

  void _showSummary(BuildContext context, OrderRouteState state, OrderRouteNotifier notifier) {
    final pricing = ref.read(pricingProvider);

    final totalTime = _calculateTotalTime(state);
    final totalDistance = _calculateTotalDistance(state);
    final totalCost = _calculateTotalCost(state, pricing);

    Navigator.push(
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
    ).then((result) {
      _isSummaryShown = false;
      if (result == true) {
        notifier.resetAfterSummary();
      } else {
        notifier.finishOrder();
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

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