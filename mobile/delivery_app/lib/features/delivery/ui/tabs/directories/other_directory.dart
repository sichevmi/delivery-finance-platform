import 'package:flutter/material.dart';

class OtherDirectory extends StatelessWidget {
  const OtherDirectory({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Дополнительные параметры',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildParameterCard(
            icon: Icons.attach_money,
            label: 'Минимальная сумма заказа',
            value: '500 ₽',
            description: 'Минимальная сумма для доставки',
          ),
          _buildParameterCard(
            icon: Icons.timer,
            label: 'Время доставки',
            value: '30 мин',
            description: 'Среднее время доставки',
          ),
          _buildParameterCard(
            icon: Icons.location_on,
            label: 'Радиус доставки',
            value: '5 км',
            description: 'Максимальный радиус доставки',
          ),
          _buildParameterCard(
            icon: Icons.people,
            label: 'Максимум заказов',
            value: '15',
            description: 'Максимальное число заказов за смену',
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