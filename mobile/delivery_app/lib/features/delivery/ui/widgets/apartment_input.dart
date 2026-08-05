import 'package:flutter/material.dart';
import 'package:delivery_app/features/delivery/services/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/delivery/services/logger.dart';
import 'package:delivery_app/features/delivery/providers/order_route_provider.dart';

class ApartmentInput extends ConsumerWidget {
  final OrderRouteState state;
  final OrderRouteNotifier notifier;

  const ApartmentInput({super.key, required this.state, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Введите номер квартиры', style: TextStyle(fontSize: 14, color: Colors.white)),
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
                    color: state.isApartmentValid || state.isPrivateHouse
                        ? const Color(0xFF6C63FF)
                        : const Color(0xFF2C2C2C),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.home, size: 18, color: Color(0xFF6C63FF)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Квартира', style: TextStyle(fontSize: 11, color: Color(0xFF888888))),
                          TextField(
                            enabled: !state.isPrivateHouse,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              hintText: state.isPrivateHouse ? 'Частный дом' : 'Введите номер',
                              hintStyle: TextStyle(
                                color: state.isPrivateHouse ? Color(0xFF888888) : Color(0xFF666666),
                                fontSize: 14,
                              ),
                            ),
                            onChanged: (value) {
                              notifier.state = notifier.state.copyWith(
                                apartment: value,
                                isApartmentValid: value.trim().isNotEmpty,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: state.isPrivateHouse,
                          onChanged: (val) {
                            notifier.state = notifier.state.copyWith(
                              isPrivateHouse: val ?? false,
                              apartment: (val ?? false) ? '1' : '',
                              isApartmentValid: (val ?? false) ? true : false,
                            );
                          },
                          activeColor: const Color(0xFF6C63FF),
                          side: BorderSide(
                            color: state.isPrivateHouse ? const Color(0xFF6C63FF) : const Color(0xFF666666),
                          ),
                        ),
                        const Text('Частный дом', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
                      ],
                    ),
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