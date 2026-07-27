import 'package:flutter/material.dart';

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.more_horiz,
              size: 64,
              color: Color(0xFF2C2C2C),
            ),
            SizedBox(height: 16),
            Text(
              'Дополнительно',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF888888),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Настройки, профиль,\nинформация о приложении',
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