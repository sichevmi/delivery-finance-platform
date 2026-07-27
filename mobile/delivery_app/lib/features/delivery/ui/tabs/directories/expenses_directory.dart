import 'package:flutter/material.dart';

class ExpensesDirectory extends StatelessWidget {
  const ExpensesDirectory({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Расходы на автомобиль',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildParameterCard(
            icon: Icons.local_gas_station,
            label: 'Стоимость л/км',
            value: '12.5 ₽',
            description: 'Стоимость топлива на 1 км',
          ),
          _buildParameterCard(
            icon: Icons.build,
            label: 'Ремонт на км',
            value: '3.2 ₽',
            description: 'Средняя стоимость ремонта на 1 км',
          ),
          _buildParameterCard(
            icon: Icons.trending_down,
            label: 'Амортизация на км',
            value: '5.8 ₽',
            description: 'Амортизация автомобиля на 1 км',
          ),
          _buildParameterCard(
            icon: Icons.speed,
            label: 'Расход л/км',
            value: '0.12 л',
            description: 'Средний расход топлива',
          ),
        ],
      ),
    );
  }

  Widget _buildParameterCard({
    required IconData icon,
    required String label,
    required String value,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2C2C2C),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 22,
              color: const Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888888),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              size: 20,
              color: Color(0xFF888888),
            ),
            onPressed: () {
              // TODO: редактирование параметра
            },
          ),
        ],
      ),
    );
  }
}