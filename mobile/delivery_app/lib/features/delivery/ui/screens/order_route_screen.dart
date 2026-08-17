import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/core/services/api_service.dart';
import 'package:delivery_app/features/delivery/models/delivery.dart';
import 'order_summary_screen.dart';
import 'package:delivery_app/features/delivery/providers/pricing_provider.dart';
import 'package:delivery_app/features/delivery/providers/settings_provider.dart';
import 'package:delivery_app/features/delivery/providers/daily_stats_provider.dart';
import 'package:delivery_app/features/delivery/models/pricing_config.dart';

// ===== ЛОКАЛЬНОЕ СОСТОЯНИЕ =====
class _OrderRouteState {
  final int currentSegment;
  final int deliveryNumber;
  final double coefficient;
  final double totalAllDistance;
  final double totalCost;
  final double totalExpenses;
  final int totalTime;
  final List<Delivery> completedDeliveries;
  final bool showSummary;
  final bool shouldNavigateToHome;

  _OrderRouteState({
    this.currentSegment = 0,
    this.deliveryNumber = 1,
    this.coefficient = 1.0,
    this.totalAllDistance = 0.0,
    this.totalCost = 0.0,
    this.totalExpenses = 0.0,
    this.totalTime = 0,
    this.completedDeliveries = const [],
    this.showSummary = false,
    this.shouldNavigateToHome = false,
  });

  _OrderRouteState copyWith({
    int? currentSegment,
    int? deliveryNumber,
    double? coefficient,
    double? totalAllDistance,
    double? totalCost,
    double? totalExpenses,
    int? totalTime,
    List<Delivery>? completedDeliveries,
    bool? showSummary,
    bool? shouldNavigateToHome,
  }) {
    return _OrderRouteState(
      currentSegment: currentSegment ?? this.currentSegment,
      deliveryNumber: deliveryNumber ?? this.deliveryNumber,
      coefficient: coefficient ?? this.coefficient,
      totalAllDistance: totalAllDistance ?? this.totalAllDistance,
      totalCost: totalCost ?? this.totalCost,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalTime: totalTime ?? this.totalTime,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      showSummary: showSummary ?? this.showSummary,
      shouldNavigateToHome: shouldNavigateToHome ?? this.shouldNavigateToHome,
    );
  }
}

// ===== ОСНОВНОЙ ЭКРАН =====
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
  _OrderRouteState _state = _OrderRouteState();
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
    setState(() {
      _state = _OrderRouteState(
        coefficient: widget.coefficient,
        currentSegment: widget.segmentIndex,
        deliveryNumber: 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_state.shouldNavigateToHome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(dailyStatsProvider);
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
    }

    if (_state.showSummary && !_isSummaryShown) {
      _isSummaryShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSummary(context);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.serviceName),
            if (_state.deliveryNumber > 1) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Доставка #${_state.deliveryNumber}',
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
            onPressed: () => _cancelOrder(),
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
            // Простой индикатор прогресса
            _buildProgress(),
            const SizedBox(height: 12),
            // Карточка заказа
            _buildOrderCard(),
            const SizedBox(height: 10),
            // GPS контроль (заглушка)
            _buildGpsControl(),
            const SizedBox(height: 12),
            // Содержимое сегмента
            _buildSegmentContent(),
            const SizedBox(height: 20),
            // Кнопки действий
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // ===== ЛОКАЛЬНЫЕ ВИДЖЕТЫ =====

  Widget _buildProgress() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 50,
          height: 6,
          decoration: BoxDecoration(
            color: index <= _state.currentSegment
                ? const Color(0xFF6C63FF)
                : const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildOrderCard() {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Заказ: ${widget.serviceName}',
                style: const TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Доставка #${_state.deliveryNumber}',
                style: const TextStyle(color: Color(0xFF888888))),
            Text('Завершено доставок: ${_state.completedDeliveries.length}',
                style: const TextStyle(color: Color(0xFF888888))),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsControl() {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.gps_fixed, color: Color(0xFF6C63FF)),
            const SizedBox(width: 8),
            const Text('GPS: включён', style: TextStyle(color: Colors.white)),
            const Spacer(),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: const Text('Переключить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentContent() {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Сегмент ${_state.currentSegment + 1} из 4',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Здесь будет содержимое сегмента',
                style: const TextStyle(color: Color(0xFF888888))),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (_state.currentSegment < 3)
          Expanded(
            child: ElevatedButton(
              onPressed: _nextSegment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Далее', style: TextStyle(fontSize: 16)),
            ),
          ),
        if (_state.currentSegment == 3)
          Expanded(
            child: ElevatedButton(
              onPressed: _finishOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Завершить заказ', style: TextStyle(fontSize: 16)),
            ),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: _addDelivery,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF6C63FF)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('+ Доставка', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  // ===== МЕТОДЫ-ОБРАБОТЧИКИ =====

  void _addDelivery() {
    setState(() {
      final newDelivery = Delivery(
        id: 0,
        number: _state.deliveryNumber + 1,
        clientAddress: 'Адрес ${_state.deliveryNumber + 1}',
        apartment: 'Кв. ${_state.deliveryNumber + 1}',
        weight: 1.0,
      );
      _state = _state.copyWith(
        completedDeliveries: [..._state.completedDeliveries, newDelivery],
        deliveryNumber: _state.deliveryNumber + 1,
      );
    });
  }

  void _nextSegment() {
    setState(() {
      _state = _state.copyWith(
        currentSegment: _state.currentSegment + 1,
      );
    });
  }

  void _finishOrder() {
    setState(() {
      _state = _state.copyWith(showSummary: true);
    });
  }

  void _cancelOrder() {
    logMessage('🟢 Заказ отменён');
    Navigator.of(context).pop();
  }

  void _showSummary(BuildContext context) {
    final pricing = ref.read(pricingProvider);
    final settings = ref.read(settingsProvider);

    final totalTime = _calculateTotalTime();
    final totalDistance = _calculateTotalDistance();
    final totalCost = _calculateTotalCost(pricing);

    final firstDelivery = _state.completedDeliveries.isNotEmpty ? _state.completedDeliveries.first : null;
    final shopDistance = firstDelivery?.distanceToShop ?? 0.0;
    final totalPaidDistance = _state.completedDeliveries.fold(0.0, (sum, d) => sum + d.distanceToClient);
    final totalAllDistance = shopDistance + totalPaidDistance;

    final fuelCostPerKm = (settings.fuelConsumption / 100) * settings.fuelPrice;
    final totalFuelCost = totalAllDistance * fuelCostPerKm;
    final totalRepairCost = totalAllDistance * settings.repairCost;
    final totalExpenses = totalFuelCost + totalRepairCost;

    logMessage('🟢 _showSummary: завершение заказа');
    logMessage('   paidDistance: $totalAllDistance');
    logMessage('   income: $totalCost');
    logMessage('   expenses: $totalExpenses');

    setState(() {
      _state = _state.copyWith(
        totalAllDistance: totalAllDistance,
        totalCost: totalCost,
        totalExpenses: totalExpenses,
        totalTime: totalTime,
      );
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderSummaryScreen(
          serviceName: widget.serviceName,
          coefficient: _state.coefficient,
          deliveries: _state.completedDeliveries,
          totalCost: totalCost,
          totalTime: totalTime,  // <-- ИСПРАВЛЕНО: теперь передаём int, а не Duration
          totalDistance: totalDistance,
        ),
      ),
    ).then((result) async {
      _isSummaryShown = false;
      if (result == true) {
        logMessage('🟢 Добавление ещё доставки');
        setState(() {
          _state = _state.copyWith(
            showSummary: false,
            completedDeliveries: [],
            deliveryNumber: 1,
            currentSegment: 0,
          );
        });
      } else {
        logMessage('🟢 Завершение заказа через API');
        try {
          final apiService = ApiService();
          final orderData = {
            'serviceName': widget.serviceName,
            'coefficient': _state.coefficient,
            'deliveryNumber': _state.deliveryNumber,
            'totalPaidDistance': totalAllDistance,
            'totalIncome': totalCost,
            'totalExpenses': totalExpenses,
            'netProfit': totalCost - totalExpenses,
            'totalTimeSeconds': totalTime,
          };
          await apiService.createOrder(orderData);
          logMessage('✅ Заказ создан на сервере');
        } catch (e) {
          logMessage('❌ Ошибка создания заказа: $e');
        }
        setState(() {
          _state = _state.copyWith(shouldNavigateToHome: true);
        });
      }
    });
  }

  int _calculateTotalTime() {
    if (_state.completedDeliveries.isEmpty) return 0;
    final first = _state.completedDeliveries.first;
    int total = first.timeToShop + first.timeReceiving;
    for (final d in _state.completedDeliveries) {
      total += d.timeToClient + d.timeDelivery;
    }
    return total;
  }

  double _calculateTotalDistance() {
    if (_state.completedDeliveries.isEmpty) return 0.0;
    double total = _state.completedDeliveries.first.distanceToShop;
    for (final d in _state.completedDeliveries) {
      total += d.distanceToClient;
    }
    return total;
  }

  double _calculateTotalCost(PricingConfig pricing) {
    if (_state.completedDeliveries.isEmpty) return 0.0;
    final first = _state.completedDeliveries.first;
    double total = (pricing.receivingFee + (first.weight * pricing.pricePerKg)) * _state.coefficient;
    for (final d in _state.completedDeliveries) {
      total += (pricing.deliveryFee + (d.distanceToClient * pricing.pricePerKm)) * _state.coefficient;
    }
    return total;
  }
}