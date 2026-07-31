import 'package:flutter/material.dart';

class AnalyticsTile extends StatelessWidget {
  final String title;
  final double profit;
  final int ordersCount;
  final VoidCallback onTap;

  const AnalyticsTile({
    super.key,
    required this.title,
    required this.profit,
    required this.ordersCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2C2C2C), width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Прибыль: ${profit.toStringAsFixed(0)} ₽',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$ordersCount зак.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6C63FF),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF888888)),
          ],
        ),
      ),
    );
  }
}