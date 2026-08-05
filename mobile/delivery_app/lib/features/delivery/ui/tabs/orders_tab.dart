import 'package:flutter/material.dart';
import 'package:delivery_app/logger.dart';
import '../screens/order_creation_screen.dart';

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  final List<Order> _orders = const [
    Order(
      id: '№ 1',
      group: 'Группа Х5',
      status: OrderStatus.completed,
      dateTime: '01.01.2001 19:35',
    ),
    Order(
      id: '№ 2',
      group: 'Вайлдберриз',
      status: OrderStatus.inProgress,
      dateTime: '01.01.2001 18:20',
    ),
    Order(
      id: '№ 3',
      group: 'Яндекс',
      status: OrderStatus.pending,
      dateTime: '01.01.2001 17:45',
    ),
    Order(
      id: '№ 4',
      group: 'Другое',
      status: OrderStatus.cancelled,
      dateTime: '01.01.2001 16:10',
    ),
    Order(
      id: '№ 5',
      group: 'Группа Х5',
      status: OrderStatus.completed,
      dateTime: '01.01.2001 15:30',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Создать заказ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.8,
            children: [
              _buildServiceButton(
                context: context,
                icon: Icons.storefront,
                label: 'Группа Х5',
                color: Colors.orange,
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                ),
              ),
              _buildServiceButton(
                context: context,
                icon: Icons.shopping_bag,
                label: 'Вайлдберриз',
                color: Colors.deepPurple,
                gradient: const LinearGradient(
                  colors: [Colors.deepPurple, Colors.purple],
                ),
              ),
              _buildServiceButton(
                context: context,
                icon: Icons.local_taxi,
                label: 'Яндекс',
                color: Colors.blue.shade700,
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.lightBlue],
                ),
              ),
              _buildServiceButton(
                context: context,
                icon: Icons.more_horiz,
                label: 'Другое',
                color: Colors.grey.shade600,
                gradient: const LinearGradient(
                  colors: [Colors.grey, Colors.blueGrey],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'История заказов',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _buildOrderCard(
                context: context,
                order: _orders[index],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required Gradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        // В orders_tab.dart, внутри _buildServiceButton:
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderCreationScreen(
                serviceName: label,
              ),
            ),
          );
        },
        icon: Icon(
          icon,
          size: 22,
          color: Colors.white,
        ),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildOrderCard({
    required BuildContext context,
    required Order order,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2C2C2C),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Открыт заказ ${order.id}'),
                backgroundColor: const Color(0xFF6C63FF),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      order.id.replaceAll('№ ', ''),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(order.status),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            order.id,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.status).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              order.statusLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: _getStatusColor(order.status),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.group,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  order.dateTime,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF888888),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Color(0xFF444444),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.inProgress:
        return Colors.orange;
      case OrderStatus.pending:
        return Colors.grey;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}

enum OrderStatus {
  completed,
  inProgress,
  pending,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.completed:
        return 'Завершен';
      case OrderStatus.inProgress:
        return 'В пути';
      case OrderStatus.pending:
        return 'Ожидает';
      case OrderStatus.cancelled:
        return 'Отменен';
    }
  }
}

class Order {
  final String id;
  final String group;
  final OrderStatus status;
  final String dateTime;

  const Order({
    required this.id,
    required this.group,
    required this.status,
    required this.dateTime,
  });

  String get statusLabel => status.label;
}