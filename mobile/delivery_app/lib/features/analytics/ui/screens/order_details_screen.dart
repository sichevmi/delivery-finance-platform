import 'package:flutter/material.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/features/analytics/models/analytics_models.dart';
import 'package:delivery_app/features/analytics/services/analytics_repository.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final _repo = AnalyticsRepository();
  OrderDetails? _details;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final details = await _repo.getOrderDetails(widget.orderId);
      if (mounted) {
        setState(() {
          _details = details;
          _loading = false;
        });
      }
    } catch (e) {
      logMessage('❌ [ORDER DETAILS] $e', category: 'API', level: LogLevel.error);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Заказ #${widget.orderId}'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Ошибка: $_error', style: const TextStyle(color: Colors.red)))
              : _buildContent(_details!),
    );
  }

  Widget _buildContent(OrderDetails o) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('Общая информация', [
            _row('ID', '#${o.id}'),
            _row('Сервис', o.serviceName ?? '—'),
            _row('Статус', o.status ?? '—'),
            _row('Коэффициент', o.coefficient?.toStringAsFixed(2) ?? '—'),
            _row('Магазин', o.shopAddress ?? '—'),
            _row('Создан', o.createdAt?.toLocal().toString() ?? '—'),
          ]),
          const SizedBox(height: 16),
          _section('Финансы', [
            _row('Доход', '${o.totalIncome.toStringAsFixed(0)} ₽'),
            _row('Расходы', '${o.totalExpenses.toStringAsFixed(0)} ₽'),
            _row('Чистая прибыль', '${o.netProfit.toStringAsFixed(0)} ₽'),
          ]),
          const SizedBox(height: 16),
          _section('Пробег и время', [
            _row('Платный пробег', '${o.totalPaidDistance.toStringAsFixed(2)} км'),
            _row('Общее время', _formatDuration(o.totalTimeSeconds)),
          ]),
          const SizedBox(height: 16),
          Text(
            'Доставки (${o.deliveries.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ...o.deliveries.map(_buildDelivery),
        ],
      ),
    );
  }

  Widget _buildDelivery(OrderDeliveryItem d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Доставка #${d.number ?? '—'}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          if (d.clientAddress != null)
            Text('Адрес: ${d.clientAddress}',
                style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
          if (d.apartment != null)
            Text('Кв: ${d.apartment}',
                style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
          if (d.weight != null)
            Text('Вес: ${d.weight} кг',
                style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
          if (d.distanceToShop != null)
            Text('До магазина: ${d.distanceToShop} км',
                style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
          if (d.distanceToClient != null)
            Text('До клиента: ${d.distanceToClient} км',
                style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
          if (d.tip != null && d.tip! > 0)
            Text('Чаевые: ${d.tip} ₽',
                style: const TextStyle(color: Colors.green, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}