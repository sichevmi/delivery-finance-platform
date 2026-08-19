import 'package:flutter/material.dart';
import 'package:delivery_app/features/delivery/ui/widgets/weight_input.dart';
import 'package:delivery_app/features/delivery/ui/widgets/apartment_input.dart';

class SegmentContent extends StatelessWidget {
  final int currentSegment;
  final double? weight;
  final bool isWeightValid;
  final String? apartment;
  final bool isApartmentValid;
  final bool isPrivateHouse;
  final String? shopAddress;
  final bool showManualShopInput;
  final bool isShopAddressManual;
  final String? manualShopAddress;
  final String? clientAddress;
  final bool showManualClientInput;
  final bool isClientAddressManual;
  final String? manualClientAddress;
  final double tip; // <-- ДОБАВЛЯЕМ
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<String> onApartmentChanged;
  final ValueChanged<bool> onPrivateHouseChanged;
  final VoidCallback onRetryGeocode;
  final ValueChanged<String> onManualShopAddressChanged;
  final VoidCallback onManualShopAddressConfirm;
  final VoidCallback onRetryClientGeocode;
  final ValueChanged<String> onManualClientAddressChanged;
  final VoidCallback onManualClientAddressConfirm;
  final ValueChanged<double> onTipChanged; // <-- ДОБАВЛЯЕМ

  const SegmentContent({
    super.key,
    required this.currentSegment,
    this.weight,
    required this.isWeightValid,
    this.apartment,
    required this.isApartmentValid,
    required this.isPrivateHouse,
    this.shopAddress,
    required this.showManualShopInput,
    required this.isShopAddressManual,
    this.manualShopAddress,
    this.clientAddress,
    required this.showManualClientInput,
    required this.isClientAddressManual,
    this.manualClientAddress,
    required this.tip,
    required this.onWeightChanged,
    required this.onApartmentChanged,
    required this.onPrivateHouseChanged,
    required this.onRetryGeocode,
    required this.onManualShopAddressChanged,
    required this.onManualShopAddressConfirm,
    required this.onRetryClientGeocode,
    required this.onManualClientAddressChanged,
    required this.onManualClientAddressConfirm,
    required this.onTipChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (currentSegment) {
      case 0:
        if (showManualShopInput) {
          return _AddressInput(
            title: 'Адрес магазина не определён. Введите адрес вручную:',
            hintText: 'Введите полный адрес магазина',
            manualAddress: manualShopAddress,
            onChanged: onManualShopAddressChanged,
            onRetry: onRetryGeocode,
            onConfirm: onManualShopAddressConfirm,
          );
        }
        if (shopAddress != null && shopAddress != 'Адрес не определён') {
          return _AddressSuccess(
            label: 'Пробег до магазина (бесплатный)',
            address: shopAddress!,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Пробег до магазина (бесплатный)',
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2C2C2C)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.gps_not_fixed, color: Color(0xFF888888), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Нажмите "Получить бандероль", чтобы определить адрес',
                      style: TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case 1:
        return WeightInput(
          initialWeight: weight ?? 0.0,
          onWeightChanged: onWeightChanged,
        );

      case 2:
        if (showManualClientInput) {
          return _AddressInput(
            title: 'Адрес клиента не определён. Введите адрес вручную:',
            hintText: 'Введите полный адрес клиента',
            manualAddress: manualClientAddress,
            onChanged: onManualClientAddressChanged,
            onRetry: onRetryClientGeocode,
            onConfirm: onManualClientAddressConfirm,
          );
        }
        if (clientAddress != null && clientAddress != 'Адрес не определён') {
          return _AddressSuccess(
            label: 'Пробег до клиента (платный)',
            address: clientAddress!,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Пробег до клиента (платный)',
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2C2C2C)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.gps_not_fixed, color: Color(0xFF888888), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Нажмите "Выдать бандероль", чтобы определить адрес клиента',
                      style: TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case 3:
        return Column(
          children: [
            ApartmentInput(
              initialApartment: apartment ?? '',
              initialIsPrivateHouse: isPrivateHouse,
              onApartmentChanged: onApartmentChanged,
              onPrivateHouseChanged: onPrivateHouseChanged,
            ),
            const SizedBox(height: 12),
            _TipInput(
              tip: tip,
              onTipChanged: onTipChanged,
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

// ============================================================
// ВИДЖЕТ ДЛЯ ВВОДА ЧАЕВЫХ
// ============================================================
class _TipInput extends StatelessWidget {
  final double tip;
  final ValueChanged<double> onTipChanged;

  const _TipInput({
    required this.tip,
    required this.onTipChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: tip == 0 ? '' : tip.toString());
    controller.addListener(() {
      final value = double.tryParse(controller.text.replaceAll(',', '.'));
      if (value != null && value >= 0) {
        onTipChanged(value);
      }
    });

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
          const Row(
            children: [
              Icon(Icons.attach_money, size: 18, color: Color(0xFF6C63FF)),
              SizedBox(width: 8),
              Text(
                'Чаевые',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTipChip('0', 0, tip, onTipChanged),
              const SizedBox(width: 8),
              _buildTipChip('50₽', 50, tip, onTipChanged),
              const SizedBox(width: 8),
              _buildTipChip('100₽', 100, tip, onTipChanged),
              const SizedBox(width: 8),
              _buildTipChip('200₽', 200, tip, onTipChanged),
              const SizedBox(width: 8),
              _buildTipChip('500₽', 500, tip, onTipChanged),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Сумма: ',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C63FF),
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ),
              const Text(
                ' ₽',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipChip(String label, double value, double currentTip, ValueChanged<double> onTipChanged) {
    final isSelected = currentTip == value;
    return GestureDetector(
      onTap: () => onTipChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6C63FF)
              : const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6C63FF)
                : const Color(0xFF3C3C3C),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : const Color(0xFF888888),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ВИДЖЕТЫ ДЛЯ РУЧНОГО ВВОДА АДРЕСА
// ============================================================
class _AddressInput extends StatelessWidget {
  final String title;
  final String hintText;
  final String? manualAddress;
  final ValueChanged<String> onChanged;
  final VoidCallback onRetry;
  final VoidCallback onConfirm;

  const _AddressInput({
    required this.title,
    required this.hintText,
    required this.manualAddress,
    required this.onChanged,
    required this.onRetry,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: manualAddress);
    controller.addListener(() {
      onChanged(controller.text);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: 2,
          decoration: InputDecoration(
            hintText: hintText,
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
            prefixIcon: const Icon(Icons.location_on, color: Color(0xFF6C63FF)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6C63FF),
                  side: const BorderSide(color: Color(0xFF6C63FF)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.gps_fixed, size: 16),
                    SizedBox(width: 6),
                    Text('Повторить'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (controller.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Пожалуйста, введите адрес'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  onConfirm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Подтвердить',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AddressSuccess extends StatelessWidget {
  final String label;
  final String address;

  const _AddressSuccess({
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF6C63FF)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}