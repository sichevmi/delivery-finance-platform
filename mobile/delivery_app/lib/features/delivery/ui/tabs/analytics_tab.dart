import 'package:flutter/material.dart';
import 'package:delivery_app/models/analytics_models.dart';
import 'package:delivery_app/models/analytics_enums.dart';
import 'package:delivery_app/services/mock_analytics_repository.dart';
import 'package:delivery_app/widgets/kpi_card.dart';
import 'package:delivery_app/widgets/analytics_chart.dart';
import 'package:delivery_app/widgets/analytics_period_selector.dart';
import 'package:delivery_app/widgets/analytics_tile.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  final _repository = MockAnalyticsRepository();

  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.year;
  int _selectedYear = DateTime.now().year;
  int? _selectedMonth;
  int? _selectedDay;

  AnalyticsData? _data;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    final data = _repository.getData(
      year: _selectedYear,
      month: _selectedMonth,
      day: _selectedDay,
      period: _selectedPeriod,
    );
    setState(() {
      _data = data;
      _isLoading = false;
    });
  }

  void _onPeriodChanged(AnalyticsPeriod period) {
    if (period == AnalyticsPeriod.year) {
      _selectedMonth = null;
      _selectedDay = null;
    } else if (period == AnalyticsPeriod.month) {
      if (_selectedMonth == null) _selectedMonth = DateTime.now().month;
      _selectedDay = null;
    } else if (period == AnalyticsPeriod.day) {
      if (_selectedMonth == null) _selectedMonth = DateTime.now().month;
      if (_selectedDay == null) _selectedDay = DateTime.now().day;
    }
    setState(() {
      _selectedPeriod = period;
    });
    _loadData();
  }

  void _onTileTap(AnalyticsPeriodTile tile) {
    if (_selectedPeriod == AnalyticsPeriod.year && tile.startDate != null) {
      setState(() {
        _selectedPeriod = AnalyticsPeriod.month;
        _selectedMonth = tile.startDate!.month;
        _selectedDay = null;
      });
      _loadData();
    } else if (_selectedPeriod == AnalyticsPeriod.month && tile.startDate != null) {
      setState(() {
        _selectedPeriod = AnalyticsPeriod.day;
        _selectedDay = tile.startDate!.day;
      });
      _loadData();
    } else if (_selectedPeriod == AnalyticsPeriod.day) {
      _showOrderDetails(tile);
    }
  }

  void _showOrderDetails(AnalyticsPeriodTile tile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tile.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Прибыль: ${tile.profit.toStringAsFixed(0)} ₽'),
            Text('Заказов: ${tile.ordersCount}'),
            if (tile.startDate != null)
              Text('Время: ${tile.startDate!.toLocal()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика'),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _data == null
                ? const Center(child: Text('Нет данных'))
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummary(_data!.summary),
                        const SizedBox(height: 16),
                        AnalyticsPeriodSelector(
                          selectedPeriod: _selectedPeriod,
                          onPeriodChanged: _onPeriodChanged,
                        ),
                        const SizedBox(height: 16),
                        if (_selectedPeriod != AnalyticsPeriod.day)
                          AnalyticsChart(
                            points: _data!.chartPoints,
                            onBarTapped: (index) {
                              if (index < _data!.periodTiles.length) {
                                _onTileTap(_data!.periodTiles[index]);
                              }
                            },
                          ),
                        const SizedBox(height: 16),
                        ..._data!.periodTiles.map((tile) => AnalyticsTile(
                              title: tile.title,
                              profit: tile.profit,
                              ordersCount: tile.ordersCount,
                              onTap: () => _onTileTap(tile),
                            )),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSummary(AnalyticsSummary summary) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        KpiCard(
          label: 'Заказы',
          value: summary.totalOrders.toString(),
          icon: Icons.shopping_bag,
        ),
        KpiCard(
          label: 'Расходы',
          value: '${summary.totalExpenses.toStringAsFixed(0)} ₽',
          icon: Icons.money_off,
          color: Colors.orange,
        ),
        KpiCard(
          label: 'Прибыль',
          value: '${summary.netProfit.toStringAsFixed(0)} ₽',
          icon: Icons.trending_up,
          color: Colors.green,
        ),
        KpiCard(
          label: 'Км',
          value: '${summary.totalDistance.toStringAsFixed(0)} км',
          icon: Icons.route,
          color: Colors.blue,
        ),
        KpiCard(
          label: 'Время',
          value: _formatDuration(summary.totalTime),
          icon: Icons.timer,
          color: Colors.purple,
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '$hours ч ${minutes} мин';
    } else {
      return '$minutes мин';
    }
  }
}