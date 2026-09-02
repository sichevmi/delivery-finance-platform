import 'package:flutter/material.dart';
import 'package:delivery_app/logger.dart';
import 'order_route_screen.dart';

class OrderCreationScreen extends StatefulWidget {
  final String serviceName;

  const OrderCreationScreen({
    super.key,
    required this.serviceName,
  });

  @override
  State<OrderCreationScreen> createState() => _OrderCreationScreenState();
}

class _OrderCreationScreenState extends State<OrderCreationScreen> {
  double _selectedCoefficient = 1.0;
  bool _isCustomCoefficient = false;
  final TextEditingController _customCoefficientController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  final List<double> _coefficients = [1.0, 1.1, 1.2, 1.25, 1.5, 2.0, 2.5];

  @override
  void dispose() {
    _customCoefficientController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceName),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          TextButton(
            onPressed: _cancelOrder,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text(
              'Отменить',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Коэффициент нагрузки',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _coefficients.map((coef) {
                final isSelected = !_isCustomCoefficient && _selectedCoefficient == coef;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCoefficient = coef;
                      _isCustomCoefficient = false;
                      _customCoefficientController.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6C63FF)
                          : const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6C63FF)
                            : const Color(0xFF2C2C2C),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      coef.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : const Color(0xFF888888),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _isCustomCoefficient,
                  onChanged: (value) {
                    setState(() {
                      _isCustomCoefficient = value ?? false;
                      if (_isCustomCoefficient) {
                        _customCoefficientController.clear();
                      } else if (_customCoefficientController.text.isNotEmpty) {
                        _selectedCoefficient = double.tryParse(
                          _customCoefficientController.text,
                        ) ?? 1.0;
                      }
                    });
                  },
                  activeColor: const Color(0xFF6C63FF),
                  side: const BorderSide(color: Color(0xFF2C2C2C)),
                ),
                const Text(
                  'Ввести вручную',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
            if (_isCustomCoefficient)
              Padding(
                padding: const EdgeInsets.only(left: 40, top: 8),
                child: TextField(
                  controller: _customCoefficientController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Введите коэффициент (например, 1.3)',
                    hintStyle: const TextStyle(color: Color(0xFF666666)),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
                    ),
                    prefixIcon: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF888888),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final parsed = double.tryParse(value);
                      if (parsed != null) {
                        setState(() {
                          _selectedCoefficient = parsed;
                        });
                      }
                    }
                  },
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Комментарий',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Введите комментарий к заказу...',
                hintStyle: const TextStyle(color: Color(0xFF666666)),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _goToRoute,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'В магазин',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelOrder,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Отменить заказ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _goToRoute() {
    final coefficient = _isCustomCoefficient
        ? double.tryParse(_customCoefficientController.text) ?? 1.0
        : _selectedCoefficient;

    logMessage('🟢 OrderCreationScreen: переход с coefficient=$coefficient, segmentIndex=0');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderRouteScreen(
          serviceName: widget.serviceName,
          coefficient: coefficient,
          segmentIndex: 0,
        ),
      ),
    );
  }

  void _cancelOrder() {
    Navigator.pop(context);
  }
}