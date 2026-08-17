import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/core/services/api_service.dart';
import 'package:delivery_app/logger.dart';

class X5Directory extends ConsumerStatefulWidget {
  const X5Directory({super.key});

  @override
  ConsumerState<X5Directory> createState() => _X5DirectoryState();
}

class _X5DirectoryState extends ConsumerState<X5Directory> {
  final ApiService _apiService = ApiService();

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

  void _updateControllersFromCache() {
    final x5 = _apiService.cache.x5Settings;
    
    final pickupText = x5.pickupPrice.toStringAsFixed(2);
    if (_pickupPriceController.text != pickupText) {
      _pickupPriceController.text = pickupText;
    }

    final deliveryText = x5.deliveryPrice.toStringAsFixed(2);
    if (_deliveryPriceController.text != deliveryText) {
      _deliveryPriceController.text = deliveryText;
    }

    final perKmText = x5.perKmPrice.toStringAsFixed(2);
    if (_perKmPriceController.text != perKmText) {
      _perKmPriceController.text = perKmText;
    }

    final perKgText = x5.perKgPrice.toStringAsFixed(2);
    if (_perKgPriceController.text != perKgText) {
      _perKgPriceController.text = perKgText;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Обновляем контроллеры при загрузке данных
    if (!_isInitialized) {
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateControllersFromCache();
      });
    }

    _updateControllersFromCache();

    final x5 = _apiService.cache.x5Settings;

    final parameters = [
      X5Parameter(
        id: 'pickup_price',
        icon: Icons.payment,
        label: 'Цена вывоза',
        controller: _pickupPriceController,
        unit: '₽',
        description: 'Стоимость вывоза заказа',
        iconColor: Colors.orange,
        value: x5.pickupPrice,
        onSaved: (value) async {
          final parsed = double.tryParse(value.replaceAll(',', '.'));
          if (parsed != null && parsed > 0) {
            final apiService = ApiService();
            try {
              await apiService.apiClient.updateX5Settings({
                'pickupPrice': parsed,
                'deliveryPrice': x5.deliveryPrice,
                'perKmPrice': x5.perKmPrice,
                'perKgPrice': x5.perKgPrice,
              });
              await apiService.loadAllData();
              return true;
            } catch (e) {
              logMessage('Ошибка сохранения X5: $e', level: LogLevel.error);
              return false;
            }
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
        value: x5.deliveryPrice,
        onSaved: (value) async {
          final parsed = double.tryParse(value.replaceAll(',', '.'));
          if (parsed != null && parsed > 0) {
            final apiService = ApiService();
            try {
              await apiService.apiClient.updateX5Settings({
                'pickupPrice': x5.pickupPrice,
                'deliveryPrice': parsed,
                'perKmPrice': x5.perKmPrice,
                'perKgPrice': x5.perKgPrice,
              });
              await apiService.loadAllData();
              return true;
            } catch (e) {
              logMessage('Ошибка сохранения X5: $e', level: LogLevel.error);
              return false;
            }
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
        value: x5.perKmPrice,
        onSaved: (value) async {
          final parsed = double.tryParse(value.replaceAll(',', '.'));
          if (parsed != null && parsed > 0) {
            final apiService = ApiService();
            try {
              await apiService.apiClient.updateX5Settings({
                'pickupPrice': x5.pickupPrice,
                'deliveryPrice': x5.deliveryPrice,
                'perKmPrice': parsed,
                'perKgPrice': x5.perKgPrice,
              });
              await apiService.loadAllData();
              return true;
            } catch (e) {
              logMessage('Ошибка сохранения X5: $e', level: LogLevel.error);
              return false;
            }
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
        value: x5.perKgPrice,
        onSaved: (value) async {
          final parsed = double.tryParse(value.replaceAll(',', '.'));
          if (parsed != null && parsed > 0) {
            final apiService = ApiService();
            try {
              await apiService.apiClient.updateX5Settings({
                'pickupPrice': x5.pickupPrice,
                'deliveryPrice': x5.deliveryPrice,
                'perKmPrice': x5.perKmPrice,
                'perKgPrice': parsed,
              });
              await apiService.loadAllData();
              return true;
            } catch (e) {
              logMessage('Ошибка сохранения X5: $e', level: LogLevel.error);
              return false;
            }
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
                  
                  // Сохраняем все параметры
                  final pickup = double.tryParse(_pickupPriceController.text.replaceAll(',', '.')) ?? 0;
                  final delivery = double.tryParse(_deliveryPriceController.text.replaceAll(',', '.')) ?? 0;
                  final perKm = double.tryParse(_perKmPriceController.text.replaceAll(',', '.')) ?? 0;
                  final perKg = double.tryParse(_perKgPriceController.text.replaceAll(',', '.')) ?? 0;

                  try {
                    await _apiService.apiClient.updateX5Settings({
                      'pickupPrice': pickup,
                      'deliveryPrice': delivery,
                      'perKmPrice': perKm,
                      'perKgPrice': perKg,
                    });
                    await _apiService.loadAllData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ X5 настройки сохранены на сервере'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Ошибка: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    logMessage('Ошибка сохранения X5: $e', level: LogLevel.error);
                  }
                  
                  setState(() => _isSaving = false);
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
                const Icon(
                  Icons.cloud_done,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Синхронизировано',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Text(
                  'Версия: ${x5.version}',
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
                      content: Text('✅ Сохранено на сервере'),
                      duration: Duration(seconds: 1),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _updateControllersFromCache();
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Color(0xFF6C63FF), size: 20),
            onPressed: () async {
              setState(() => _isSaving = true);
              final success = await param.onSaved(param.controller.text);
              setState(() => _isSaving = false);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Сохранено на сервере'),
                    duration: Duration(seconds: 1),
                    backgroundColor: Colors.green,
                  ),
                );
                _updateControllersFromCache();
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