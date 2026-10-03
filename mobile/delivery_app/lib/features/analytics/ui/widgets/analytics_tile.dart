import 'package:flutter/material.dart';

class AnalyticsTile extends StatelessWidget {
  final String title;
  final double profit;
  final int ordersCount;
  final String? serviceName;
  final int? deliveriesCount;
  final VoidCallback onTap;

  const AnalyticsTile({
    super.key,
    required this.title,
    required this.profit,
    required this.ordersCount,
    required this.onTap,
    this.serviceName,
    this.deliveriesCount,
  });

  @override
  Widget build(BuildContext context) {
    final isOrder = serviceName != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2C2C2C)),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isOrder)
                    Text(
                      serviceName!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${profit.toStringAsFixed(0)} ₽',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6C63FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isOrder
                        ? '${deliveriesCount ?? 0} дост.'
                        : '$ordersCount зак.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right, color: Color(0xFF888888), size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}