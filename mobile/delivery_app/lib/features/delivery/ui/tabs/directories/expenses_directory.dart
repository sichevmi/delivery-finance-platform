import 'package:flutter/material.dart';
import 'package:delivery_app/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/features/delivery/providers/settings_provider.dart';

class ExpensesDirectory extends ConsumerStatefulWidget {
  const ExpensesDirectory({super.key});

  @override
  ConsumerState<ExpensesDirectory> createState() => _ExpensesDirectoryState();
}

class _ExpensesDirectoryState extends ConsumerState<ExpensesDirectory> {
  late TextEditingController _fuelPriceController;
  late TextEditingController _fuelConsumptionController;
  late TextEditingController _repairCostController;
  
  late FocusNode _fuelPriceFocusNode;
  late FocusNode _fuelConsumptionFocusNode;
  late FocusNode _repairCostFocusNode;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fuelPriceController = TextEditingController();
    _fuelConsumptionController = TextEditingController();
    _repairCostController = TextEditingController();
    
    _fuelPriceFocusNode = FocusNode();
    _fuelConsumptionFocusNode = FocusNode();
    _repairCostFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _fuelPriceController.dispose();
    _fuelConsumptionController.dispose();
    _repairCostController.dispose();
    _fuelPriceFocusNode.dispose();
    _fuelConsumptionFocusNode.dispose();
    _repairCostFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    // Обновляем текст только если контроллер не в фокусе
    if (!_fuelPriceFocusNode.hasFocus) {
      final newText = settings.fuelPrice.toStringAsFixed(2);
      if (_fuelPriceController.text != newText) {
        _fuelPriceController.text = newText;
      }
    }
    if (!_fuelConsumptionFocusNode.hasFocus) {
      final newText = settings.fuelConsumption.toStringAsFixed(1);
      if (_fuelConsumptionController.text != newText) {
        _fuelConsumptionController.text = newText;
      }
    }
    if (!_repairCostFocusNode.hasFocus) {
      final newText = settings.repairCost.toStringAsFixed(2);
      if (_repairCostController.text != newText) {
        _repairCostController.text = newText;
      }
    }

    // Вычисляемые значения
    final consumptionPerKm = settings.fuelConsumption / 100;
    final fuelCostPerKm = consumptionPerKm * settings.fuelPrice;

    final parameters = [
      ExpenseParameter(
        id: 'fuelPrice',
        name: 'Цена за литр бензина',
        description: 'Стоимость 1 литра бензина',
        controller: _fuelPriceController,
        focusNode: _fuelPriceFocusNode,
        unit: 'руб',
        value: settings.fuelPrice,
        onSaved: (value) async {
          final parsed = double.tryParse(value.replaceAll(',', '.'));
          if (parsed != null && parsed > 0) {
            await notifier.saveFuelPrice(parsed);
            return true;
          }
          return false;
        },
      ),
      ExpenseParameter(
        id: 'fuelConsumption',
        name: 'Расход на 100 км',
        description: 'Средний расход топлива на 100 км',
        controller: _fuelConsumptionController,
        focusNode: _fuelConsumptionFocusNode,
        unit: 'л',
        value: settings.fuelConsumption,
        onSaved: (value) async {
          final parsed = double.tryParse(value.replaceAll(',', '.'));
          if (parsed != null && parsed > 0) {
            await notifier.saveFuelConsumption(parsed);
            return true;
          }
          return false;
        },
      ),
      ExpenseParameter(
        id: 'repairCost',
        name: 'Стоимость ремонта',
        description: 'Стоимость ремонта на 1 км пробега',
        controller: _repairCostController,
        focusNode: _repairCostFocusNode,
        unit: 'руб/км',
        value: settings.repairCost,
        onSaved: (value) async {
          final parsed = double.tryParse(value.replaceAll(',', '.'));
          if (parsed != null && parsed > 0) {
            await notifier.saveRepairCost(parsed);
            return true;
          }
          return false;
        },
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Расходы'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF6C63FF),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...parameters.map((param) => _buildEditableField(param, notifier)),
          
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF2C2C2C)),
          const SizedBox(height: 16),
          
          _buildReadOnlyField(
            label: 'Расход на 1 км',
            value: consumptionPerKm.toStringAsFixed(4),
            unit: 'л',
          ),
          const SizedBox(height: 8),
          _buildReadOnlyField(
            label: 'Стоимость бензина на 1 км',
            value: fuelCostPerKm.toStringAsFixed(4),
            unit: 'руб',
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(ExpenseParameter param, SettingsNotifier notifier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                param.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Кнопка сохранения
              IconButton(
                icon: const Icon(
                  Icons.save,
                  color: Color(0xFF6C63FF),
                  size: 20,
                ),
                onPressed: () async {
                  setState(() => _isSaving = true);
                  final success = await param.onSaved(param.controller.text);
                  setState(() => _isSaving = false);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Сохранено'),
                        duration: Duration(seconds: 1),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                tooltip: 'Сохранить',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: param.controller,
                  focusNode: param.focusNode,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    color: Color(0xFF6C63FF),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (value) async {
                    final success = await param.onSaved(value);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Сохранено'),
                          duration: Duration(seconds: 1),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  param.unit,
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            param.description,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
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
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.lock_outline,
            color: Color(0xFF666666),
            size: 18,
          ),
        ],
      ),
    );
  }
}

class ExpenseParameter {
  final String id;
  final String name;
  final String description;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String unit;
  final double value;
  final Future<bool> Function(String) onSaved;

  ExpenseParameter({
    required this.id,
    required this.name,
    required this.description,
    required this.controller,
    required this.focusNode,
    required this.unit,
    required this.value,
    required this.onSaved,
  });
}