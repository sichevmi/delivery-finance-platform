import 'package:flutter/material.dart';

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 64,
              color: Color(0xFF2C2C2C),
            ),
            SizedBox(height: 16),
            Text(
              'Аналитика в разработке',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF888888),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Здесь будут графики и таблицы\nс показателями заказов',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }
}