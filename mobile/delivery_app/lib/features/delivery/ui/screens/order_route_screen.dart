import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/features/delivery/providers/order_route_provider.dart';
import 'package:delivery_app/features/delivery/ui/widgets/segment_progress.dart';
import 'package:delivery_app/features/delivery/ui/widgets/order_card.dart';
import 'package:delivery_app/features/delivery/ui/widgets/gps_control.dart';
import 'package:delivery_app/features/delivery/ui/widgets/segment_content.dart';
import 'package:delivery_app/features/delivery/ui/widgets/action_buttons.dart';
import 'order_summary_screen.dart';
import 'package:delivery_app/features/delivery/providers/pricing_provider.dart';
import 'package:delivery_app/features/delivery/providers/settings_provider.dart';
import 'package:delivery_app/features/delivery/providers/shift_provider.dart';
import 'package:delivery_app/features/delivery/providers/daily_stats_provider.dart';
import 'package:delivery_app/features/delivery/models/pricing_config.dart';
import 'package:delivery_app/core/database/database_provider.dart';

class OrderRouteScreen extends ConsumerStatefulWidget {
  final String serviceName;
  final double coefficient;
  final int segmentIndex;

  const OrderRouteScreen({
    super.key,
    required this.serviceName,
    required this.coefficient,
    this.segmentIndex = 0,
  });

  @override
  ConsumerState<OrderRouteScreen> createState() => _OrderRouteScreenState();
}

class _OrderRouteScreenState extends ConsumerState<OrderRouteScreen> {
  bool _isSummaryShown = false;

  @override
  void initState() {
    super.initState();
    logMessage('🟢 OrderRouteScreen.initState()');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initOrderRoute();
    });
  }

  void _initOrderRoute() {
    logMessage('🟢 OrderRouteScreen._initOrderRoute()');
    final notifier = ref.read(orderRouteProvider.notifier);
    notifier.init(
      coefficient: widget.coefficient,
      segmentIndex: widget.segmentIndex,
    );
    // Запускаем заказ
    ref.read(shiftProvider.notifier).startOrder();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderRouteProvider);
    final notifier = ref.read(orderRouteProvider.notifier);

    // Если заказ завершён — переходим на главный экран
    if (state.shouldNavigateToHome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.resetNavigationFlag();
        // Обновляем статистику перед выходом
        ref.invalidate(dailyStatsProvider);
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
    }

    // Если нужно показать итоги
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
    final settings = ref.read(settingsProvider);

    final totalTime = _calculateTotalTime(state);
    final totalDistance = _calculateTotalDistance(state);
    final totalCost = _calculateTotalCost(state, pricing);

    final firstDelivery = state.completedDeliveries.isNotEmpty ? state.completedDeliveries.first : null;
    final shopDistance = firstDelivery?.distanceToShop ?? 0.0;
    final totalPaidDistance = state.completedDeliveries.fold(0.0, (sum, d) => sum + d.distanceToClient);
    final totalAllDistance = shopDistance + totalPaidDistance;

    final fuelCostPerKm = (settings.fuelConsumption / 100) * settings.fuelPrice;
    final totalFuelCost = totalAllDistance * fuelCostPerKm;
    final totalRepairCost = totalAllDistance * settings.repairCost;
    final totalExpenses = totalFuelCost + totalRepairCost;

    logMessage('🟢 _showSummary: завершение заказа');
    logMessage('   paidDistance: $totalAllDistance');
    logMessage('   income: $totalCost');
    logMessage('   expenses: $totalExpenses');

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
    ).then((result) async {
      _isSummaryShown = false;
      if (result == true) {
        logMessage('🟢 Добавление ещё доставки');
        notifier.resetAfterSummary();
      } else {
        logMessage('🟢 Завершение заказа');
        final shiftNotifier = ref.read(shiftProvider.notifier);
        final orderDuration = Duration(seconds: _calculateTotalTime(state));
        final shiftState = ref.read(shiftProvider);
        final db = ref.read(appDatabaseProvider);
        
        logMessage('   Вызов shiftNotifier.finishOrder()');
        shiftNotifier.finishOrder(
          paidDistance: totalAllDistance,
          income: totalCost,
          expenses: totalExpenses,
          orderDuration: orderDuration,
        );
        
        // ===== СОХРАНЯЕМ ЗАКАЗ В БД =====
        try {
          final orderId = await db.orderDao.insertOrder(
            serviceName: widget.serviceName,
            coefficient: state.coefficient,
            deliveryNumber: state.deliveryNumber,
            totalPaidDistance: totalAllDistance,
            totalIncome: totalCost,
            totalExpenses: totalExpenses,
            netProfit: totalCost - totalExpenses,
            totalTimeSeconds: _calculateTotalTime(state),
            shiftId: shiftState.localShiftId,
            status: 'completed',
          );
          logMessage('💾 Заказ сохранён в БД (id=$orderId)', category: 'ORDER');
          
          // Сохраняем доставки
          for (final delivery in state.completedDeliveries) {
            await db.deliveryDao.insertDelivery(
              number: delivery.number,
              clientAddress: delivery.clientAddress,
              apartment: delivery.apartment,
              weight: delivery.weight,
              timeToShop: delivery.timeToShop,
              distanceToShop: delivery.distanceToShop,
              timeReceiving: delivery.timeReceiving,
              timeToClient: delivery.timeToClient,
              distanceToClient: delivery.distanceToClient,
              timeDelivery: delivery.timeDelivery,
              orderId: orderId,
              status: 'completed',
            );
            logMessage('💾 Доставка #${delivery.number} сохранена', category: 'ORDER');
          }
          logMessage('✅ Заказ сохранён в БД (доставок: ${state.completedDeliveries.length})', category: 'ORDER');
        } catch (e) {
          logMessage('❌ Ошибка сохранения заказа в БД: $e', category: 'ORDER', level: LogLevel.error);
        }
        
        // ===== ОБНОВЛЯЕМ СТАТИСТИКУ =====
        ref.invalidate(dailyStatsProvider);
        logMessage('📊 Статистика обновлена', category: 'STATS');
        
        logMessage('   Вызов notifier.finishOrder()');
        notifier.finishOrder();
        
        logMessage('🟢 Возврат на главный экран');
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