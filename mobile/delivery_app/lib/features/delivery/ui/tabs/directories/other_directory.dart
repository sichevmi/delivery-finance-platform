import 'package:flutter/material.dart';
import '../../../../models/parameter_model.dart';
import '../../../../widgets/editable_parameter_card.dart';

class OtherDirectory extends StatefulWidget {
  const OtherDirectory({super.key});

  @override
  State<OtherDirectory> createState() => _OtherDirectoryState();
}

class _OtherDirectoryState extends State<OtherDirectory> {
  late List<Parameter> _parameters;

  @override
  void initState() {
    super.initState();
    _parameters = [
      Parameter(
        id: 'min_order_sum',
        icon: Icons.attach_money,
        label: 'Минимальная сумма заказа',
        value: '500',
        unit: '₽',
        description: 'Минимальная сумма для доставки',
      ),
      Parameter(
        id: 'delivery_time',
        icon: Icons.timer,
        label: 'Время доставки',
        value: '30',
        unit: 'мин',
        description: 'Среднее время доставки',
      ),
      Parameter(
        id: 'delivery_radius',
        icon: Icons.location_on,
        label: 'Радиус доставки',
        value: '5',
        unit: 'км',
        description: 'Максимальный радиус доставки',
      ),
      Parameter(
        id: 'max_orders',
        icon: Icons.people,
        label: 'Максимум заказов',
        value: '15',
        unit: '',
        description: 'Максимальное число заказов за смену',
      ),
    ];
  }

  void _updateParameterValue(int index, String newValue) {
    setState(() {
      _parameters[index] = _parameters[index].copyWith(value: newValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Дополнительные параметры',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ..._parameters.asMap().entries.map((entry) {
            final idx = entry.key;
            final param = entry.value;
            return EditableParameterCard(
              parameter: param,
              onValueUpdated: (newValue) => _updateParameterValue(idx, newValue),
            );
          }).toList(),
        ],
      ),
    );
  }
}