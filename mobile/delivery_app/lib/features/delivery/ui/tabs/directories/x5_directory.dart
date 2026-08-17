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

  @override
  void initState() {
    super.initState();
    _pickupPriceController = TextEditingController();
    _deliveryPriceController = TextEditingController();
    _perKmPriceController = TextEditingController();
    _perKgPriceController = TextEditingController();
    _updateControllers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateControllers();
  }

  void _updateControllers() {
    final x5 = _apiService.cache.x5Settings;
    _pickupPriceController.text = x5.pickupPrice.toStringAsFixed(2);
    _deliveryPriceController.text = x5.deliveryPrice.toStringAsFixed(2);
    _perKmPriceController.text = x5.perKmPrice.toStringAsFixed(2);
    _perKgPriceController.text = x5.perKgPrice.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _pickupPriceController.dispose();
    _deliveryPriceController.dispose();
    _perKmPriceController.dispose();
    _perKgPriceController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final pickup = double.tryParse(_pickupPriceController.text.replaceAll(',', '.')) ?? 0;
      final delivery = double.tryParse(_deliveryPriceController.text.replaceAll(',', '.')) ?? 0;
      final perKm = double.tryParse(_perKmPriceController.text.replaceAll(',', '.')) ?? 0;
      final perKg = double.tryParse(_perKgPriceController.text.replaceAll(',', '.')) ?? 0;

      await _apiService.apiClient.updateX5Settings({
        'pickupPrice': pickup,
        'deliveryPrice': delivery,
        'perKmPrice': perKm,
        'perKgPrice': perKg,
      });
      // Обновляем кэш
      await _apiService.loadAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ X5 настройки сохранены'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      logMessage('Ошибка сохранения X5: $e', level: LogLevel.error);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final x5 = _apiService.cache.x5Settings;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('X5 Настройки'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C63FF)),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildField('Цена забора', _pickupPriceController, 'руб'),
          const SizedBox(height: 12),
          _buildField('Цена доставки', _deliveryPriceController, 'руб'),
          const SizedBox(height: 12),
          _buildField('Цена за км', _perKmPriceController, 'руб/км'),
          const SizedBox(height: 12),
          _buildField('Цена за кг', _perKgPriceController, 'руб/кг'),
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
                const Icon(Icons.info_outline, color: Color(0xFF888888), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Версия: ${x5.version}',
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String unit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 18),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Text(unit, style: const TextStyle(color: Color(0xFF888888))),
            ],
          ),
        ],
      ),
    );
  }
}