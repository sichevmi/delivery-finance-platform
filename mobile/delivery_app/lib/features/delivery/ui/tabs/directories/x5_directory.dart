import 'package:flutter/material.dart';
import 'package:delivery_app/models/parameter_model.dart';
import 'package:delivery_app/widgets/editable_parameter_card.dart';

class X5Directory extends StatefulWidget {
  const X5Directory({super.key});

  @override
  State<X5Directory> createState() => _X5DirectoryState();
}

class _X5DirectoryState extends State<X5Directory> {
  late List<Parameter> _parameters;

  @override
  void initState() {
    super.initState();
    _parameters = [
      Parameter(
        id: 'pickup_price',
        icon: Icons.payment,
        label: 'Цена вывоза',
        value: '250',
        unit: '₽',
        description: 'Стоимость вывоза заказа',
        iconColor: Colors.orange,
      ),
      Parameter(
        id: 'delivery_price',
        icon: Icons.shopping_bag,
        label: 'Цена выдачи',
        value: '150',
        unit: '₽',
        description: 'Стоимость выдачи заказа',
        iconColor: Colors.orange,
      ),
      Parameter(
        id: 'per_km_price',
        icon: Icons.route,
        label: 'Цена за км',
        value: '25',
        unit: '₽/км',
        description: 'Стоимость за 1 км пути',
        iconColor: Colors.orange,
      ),
      Parameter(
        id: 'per_kg_price',
        icon: Icons.fitness_center,
        label: 'Цена за кг',
        value: '10',
        unit: '₽/кг',
        description: 'Стоимость за 1 кг груза',
        iconColor: Colors.orange,
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
            'Тарификация X5',
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