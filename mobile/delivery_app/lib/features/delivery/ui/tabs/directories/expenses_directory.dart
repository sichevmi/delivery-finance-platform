import 'package:flutter/material.dart';
import 'package:delivery_app/models/parameter_model.dart';
import 'package:delivery_app/widgets/editable_parameter_card.dart';

class ExpensesDirectory extends StatefulWidget {
  const ExpensesDirectory({super.key});

  @override
  State<ExpensesDirectory> createState() => _ExpensesDirectoryState();
}

class _ExpensesDirectoryState extends State<ExpensesDirectory> {
  late List<Parameter> _parameters;

  @override
  void initState() {
    super.initState();
    _parameters = [
      Parameter(
        id: 'fuel_cost',
        icon: Icons.local_gas_station,
        label: 'Стоимость л/км',
        value: '12.5',
        unit: '₽',
        description: 'Стоимость топлива на 1 км',
      ),
      Parameter(
        id: 'repair_cost',
        icon: Icons.build,
        label: 'Ремонт на км',
        value: '3.2',
        unit: '₽',
        description: 'Средняя стоимость ремонта на 1 км',
      ),
      Parameter(
        id: 'depreciation_cost',
        icon: Icons.trending_down,
        label: 'Амортизация на км',
        value: '5.8',
        unit: '₽',
        description: 'Амортизация автомобиля на 1 км',
      ),
      Parameter(
        id: 'fuel_consumption',
        icon: Icons.speed,
        label: 'Расход л/км',
        value: '0.12',
        unit: 'л',
        description: 'Средний расход топлива',
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
            'Расходы на автомобиль',
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