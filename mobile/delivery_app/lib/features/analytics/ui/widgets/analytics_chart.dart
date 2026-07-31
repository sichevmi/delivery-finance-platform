import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:delivery_app/feature/analytics/models/analytics_models.dart';

class AnalyticsChart extends StatelessWidget {
  final List<AnalyticsChartPoint> points;
  final void Function(int index)? onBarTapped;

  const AnalyticsChart({
    super.key,
    required this.points,
    this.onBarTapped,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text('Нет данных для графика')),
      );
    }

    final maxValue = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue > 0 ? (maxValue * 1.2).toDouble() : 100.0;

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: safeMax,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final point = points[groupIndex];
                return BarTooltipItem(
                  '${point.label}\n${point.value.toStringAsFixed(0)} ₽\nЗаказов: ${point.ordersCount}',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) return const Text('');
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      points[index].label,
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: points.asMap().entries.map((entry) {
            final index = entry.key;
            final point = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: point.value,
                  color: const Color(0xFF6C63FF),
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
              showingTooltipIndicators: [],
            );
          }).toList(),
        ),
        swapAnimationDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}