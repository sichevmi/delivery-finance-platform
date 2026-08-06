import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/delivery/providers/x5_settings_provider.dart';
import 'package:delivery_app/logger.dart';

class X5Directory extends ConsumerStatefulWidget {
  const X5Directory({super.key});

  @override
  ConsumerState<X5Directory> createState() => _X5DirectoryState();
}

class _X5DirectoryState extends ConsumerState<X5Directory> {
  late TextEditingController _pickupPriceController;
  late TextEditingController _deliveryPriceController;
  late TextEditingController _perKmPriceController;
  late TextEditingController _perKgPriceController;

  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _pickupPriceController = TextEditingController();
    _deliveryPriceController = TextEditingController();
    _perKmPriceController = TextEditingController();
    _perKgPriceController = TextEditingController();
  }

  @override
  void dispose() {
    _pickupPriceController.dispose();
    _deliveryPriceController.dispose();
    _perKmPriceController.dispose();
    _perKgPriceController.dispose();
    super.dispose();
  }

  /// Обновляем контроллеры из состояния (без триггера onChanged)
  void _updateControllersFromState(X5SettingsState settings) {
    final pickupText = settings.pickupPrice.toStringAsFixed(0);
    if (_pickupPriceController.text != pickupText) {
      _pickupPriceController.text = pickupText;
    }

    final deliveryText = settings.deliveryPrice.toStringAsFixed(0);
    if (_deliveryPriceController.text != deliveryText) {
      _deliveryPriceController.text = deliveryText;
    }

    final perKmText = settings.perKmPrice.toStringAsFixed(0);
    if (_perKmPriceController.text != perKmText) {
      _perKmPriceController.text = perKmText;
    }

    final perKgText = settings.perKgPrice.toStringAsFixed(0);
    if (_perKgPriceController.text != perKgText) {
      _perKgPriceController.text = perKgText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(x5SettingsProvider);
    final notifier = ref.read(x5SettingsProvider.notifier);

    // Обновляем контроллеры при загрузке данных
    if (!_isInitialized) {
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateControllersFromState(settings);
      });
    }

    // Если данные изменились (например, после сохранения) — обновляем контроллеры
    _updateControllersFromState(settings);

    final parameters = [
      X5Parameter(
        id: 'pickup_price',
        icon: Icons.payment,
        label: 'Цена вывоза',
        controller: _pickupPriceController,
        unit: '₽',
        description: 'Стоимость вывоза заказа',
        iconColor: Colors.orange,
        value: settings.pickupPrice,
        onSaved: (value) async {
          final parsed = double.tryParse(value.replaceAll(',', '.'));
          if (parsed != null && parsed > 0) {
            notifier.updatePickupPrice(parsed);
            await notifier.saveSettings();
            return true;
          }
          return false;
        },
      ),
      X5Parameter(
        id: 'delivery_price',
        icon: Icons.shopping_bag,
        label: 'Цена выдачи',
        controller: _deliveryPriceController,
        unit: '₽',
        description: 'Стоимость выдачи заказа',
        iconColor: Colors.orange,
        value: settings.deliveryPrice,
        onSaved: (value) async {
          final parsed = double.tryParse(value.replaceAll(',', '.'));
          if (parsed != null && parsed > 0) {
            notifier.updateDeliveryPrice(parsed);
            await notifier.saveSettings();
            return true;
          }
          return false;
        },
      ),
      X5Parameter(
        id: 'per_km_price',
        icon: Icons.route,
        label: 'Цена за км',
        controller: _perKmPriceController,
        unit: '₽/км',
        description: 'Стоимость за 1 км пути',
        iconColor: Colors.orange,
        value: settings.perKmPrice,
        onSaved: (value) async {
          final parsed = double.tryParse(value.replaceAll(',', '.'));
          if (parsed != null && parsed > 0) {
            notifier.updatePerKmPrice(parsed);
            await notifier.saveSettings();
            return true;
          }
          return false;
        },
      ),
      X5Parameter(
        id: 'per_kg_price',
        icon: Icons.fitness_center,
        label: 'Цена за кг',
        controller: _perKgPriceController,
        unit: '₽/кг',
        description: 'Стоимость за 1 кг груза',
        iconColor: Colors.orange,
        value: settings.perKgPrice,
        onSaved: (value) async {
          final parsed = double.tryParse(value.replaceAll(',', '.'));
          if (parsed != null && parsed > 0) {
            notifier.updatePerKgPrice(parsed);
            await notifier.saveSettings();
            return true;
          }
          return false;
        },
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Тарификация X5',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (_isSaving)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF6C63FF),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.save, color: Color(0xFF6C63FF)),
                onPressed: () async {
                  setState(() => _isSaving = true);
                  await notifier.saveSettings();
                  setState(() => _isSaving = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ X5 настройки сохранены в БД'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...parameters.map((param) => _buildEditableField(param)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2C2C2C)),
            ),
            child: Row(
              children: [
                Icon(
                  settings.isSynced ? Icons.cloud_done : Icons.cloud_off,
                  color: settings.isSynced ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  settings.isSynced ? 'Синхронизировано' : 'Не синхронизировано',
                  style: TextStyle(
                    color: settings.isSynced ? Colors.green : Colors.orange,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: ${settings.id ?? '—'}',
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(X5Parameter param) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Row(
        children: [
          Icon(param.icon, color: param.iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  param.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  param.description,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: TextField(
              controller: param.controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                color: Color(0xFF6C63FF),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                suffixText: param.unit,
                suffixStyle: const TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 12,
                ),
              ),
              onSubmitted: (value) async {
                final success = await param.onSaved(value);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Сохранено в БД'),
                      duration: Duration(seconds: 1),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Color(0xFF6C63FF), size: 20),
            onPressed: () async {
              final success = await param.onSaved(param.controller.text);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Сохранено в БД'),
                    duration: Duration(seconds: 1),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class X5Parameter {
  final String id;
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final String unit;
  final String description;
  final Color iconColor;
  final double value;
  final Future<bool> Function(String) onSaved;

  X5Parameter({
    required this.id,
    required this.icon,
    required this.label,
    required this.controller,
    required this.unit,
    required this.description,
    required this.iconColor,
    required this.value,
    required this.onSaved,
  });
}