import 'package:flutter/material.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/features/analytics/models/analytics_enums.dart';

class AnalyticsPeriodSelector extends StatelessWidget {
  final AnalyticsPeriod selectedPeriod;
  final ValueChanged<AnalyticsPeriod> onPeriodChanged;

  const AnalyticsPeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2C2C), width: 1),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildButton(AnalyticsPeriod.year, 'Год'),
          _buildButton(AnalyticsPeriod.month, 'Месяц'),
          _buildButton(AnalyticsPeriod.day, 'День'),
        ],
      ),
    );
  }

  Widget _buildButton(AnalyticsPeriod period, String label) {
    final isSelected = selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => onPeriodChanged(period),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF888888),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}