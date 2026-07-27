import 'package:flutter/material.dart';

class X5Directory extends StatelessWidget {
  const X5Directory({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Тарификация X5',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildParameterCard(
            icon: Icons.payment,
            label: 'Цена вывоза',
            value: '250 ₽',
            description: 'Стоимость вывоза заказа',
            color: Colors.orange,
          ),
          _buildParameterCard(
            icon: Icons.shopping_bag,
            label: 'Цена выдачи',
            value: '150 ₽',
            description: 'Стоимость выдачи заказа',
            color: Colors.orange,
          ),
          _buildParameterCard(
            icon: Icons.route,
            label: 'Цена за км',
            value: '25 ₽/км',
            description: 'Стоимость за 1 км пути',
            color: Colors.orange,
          ),
          _buildParameterCard(
            icon: Icons.fitness_center,
            label: 'Цена за кг',
            value: '10 ₽/кг',
            description: 'Стоимость за 1 кг груза',
            color: Colors.orange,
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
    Color color = Colors.orange,
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
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 22,
              color: color,
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