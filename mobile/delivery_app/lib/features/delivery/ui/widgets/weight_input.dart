import 'package:flutter/material.dart';

class WeightInput extends StatefulWidget {
  final double initialWeight;
  final ValueChanged<double> onWeightChanged;

  const WeightInput({
    super.key,
    required this.initialWeight,
    required this.onWeightChanged,
  });

  @override
  State<WeightInput> createState() => _WeightInputState();
}

class _WeightInputState extends State<WeightInput> {
  late TextEditingController _controller;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Не устанавливаем значение по умолчанию — оставляем пустым
    _controller = TextEditingController(text: '');
  }

  @override
  void didUpdateWidget(WeightInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Обновляем только если не в процессе ввода
    if (!_isTyping && widget.initialWeight > 0) {
      final newText = widget.initialWeight.toString();
      if (_controller.text != newText) {
        _controller.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Введите вес бандероли', style: TextStyle(fontSize: 14, color: Colors.white)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _controller.text.isNotEmpty ? const Color(0xFF6C63FF) : const Color(0xFF2C2C2C),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fitness_center, size: 18, color: Color(0xFF6C63FF)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Вес', style: TextStyle(fontSize: 11, color: Color(0xFF888888))),
                          TextField(
                            controller: _controller,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              hintText: '0.0',
                              hintStyle: TextStyle(color: Color(0xFF666666)),
                            ),
                            onChanged: (value) {
                              _isTyping = true;
                              final parsed = double.tryParse(value.replaceAll(',', '.'));
                              if (parsed != null && parsed > 0) {
                                widget.onWeightChanged(parsed);
                              }
                              Future.delayed(const Duration(milliseconds: 500), () {
                                _isTyping = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    if (_controller.text.isNotEmpty)
                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}