import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/analytics/models/analytics_enums.dart';
import 'package:delivery_app/features/analytics/models/analytics_models.dart';
import 'package:delivery_app/features/analytics/providers/analytics_provider.dart';
import 'package:delivery_app/features/analytics/ui/widgets/kpi_summary.dart';
import 'package:delivery_app/features/analytics/ui/widgets/analytics_chart.dart';
import 'package:delivery_app/features/analytics/ui/widgets/analytics_period_selector.dart';
import 'package:delivery_app/features/analytics/ui/widgets/analytics_tile.dart';
import 'package:delivery_app/features/analytics/ui/screens/order_details_screen.dart';

class AnalyticsTab extends ConsumerStatefulWidget {
  const AnalyticsTab({super.key});

  @override
  ConsumerState<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends ConsumerState<AnalyticsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider.notifier).load();
    });
  }

  void _onPeriodChanged(AnalyticsPeriod period) {
    ref.read(analyticsProvider.notifier).load(period: period);
  }

  void _onTileTap(AnalyticsPeriodTile tile, AnalyticsPeriod currentPeriod) {
    if (currentPeriod == AnalyticsPeriod.year && tile.startDate != null) {
      ref.read(analyticsProvider.notifier).load(
            period: AnalyticsPeriod.month,
            month: tile.startDate!.month,
          );
    } else if (currentPeriod == AnalyticsPeriod.month && tile.startDate != null) {
      ref.read(analyticsProvider.notifier).load(
            period: AnalyticsPeriod.day,
            month: tile.startDate!.month,
            day: tile.startDate!.day,
          );
    } else if (currentPeriod == AnalyticsPeriod.day && tile.orderId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(orderId: tile.orderId!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика'),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(analyticsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Ошибка: ${state.error}',
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(analyticsProvider.notifier)
                              .refresh(),
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  )
                : state.data == null
                    ? const Center(child: Text('Нет данных'))
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            KpiSummary(summary: state.data!.summary),
                            const SizedBox(height: 12),
                            AnalyticsPeriodSelector(
                              selectedPeriod: state.period,
                              onPeriodChanged: _onPeriodChanged,
                            ),
                            const SizedBox(height: 16),
                            // График показываем только для year/month
                            if (state.period != AnalyticsPeriod.day)
                              AnalyticsChart(
                                points: state.data!.chartPoints,
                                onBarTapped: (index) {
                                  if (index < state.data!.periodTiles.length) {
                                    _onTileTap(
                                      state.data!.periodTiles[index],
                                      state.period,
                                    );
                                  }
                                },
                              ),
                            if (state.period != AnalyticsPeriod.day)
                              const SizedBox(height: 16),
                            ...state.data!.periodTiles.map((tile) => AnalyticsTile(
                                  title: tile.title,
                                  profit: tile.profit,
                                  ordersCount: tile.ordersCount,
                                  serviceName: tile.serviceName,
                                  deliveriesCount: tile.deliveriesCount,
                                  onTap: () => _onTileTap(tile, state.period),
                                )),
                          ],
                        ),
                      ),
      ),
    );
  }
}