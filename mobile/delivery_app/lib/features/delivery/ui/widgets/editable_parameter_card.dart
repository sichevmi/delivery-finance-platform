import 'package:flutter/material.dart';
import 'package:delivery_app/features/delivery/services/logger.dart';
import 'package:delivery_app/features/delivery/models/parameter_model.dart';
import 'package:delivery_app/features/delivery/ui/widgets/edit_parameter_dialog.dart';

class EditableParameterCard extends StatelessWidget {
  final Parameter parameter;
  final ValueChanged<String> onValueUpdated; // вызывается при успешном сохранении

  const EditableParameterCard({
    super.key,
    required this.parameter,
    required this.onValueUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2C2C), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: parameter.iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(parameter.icon, size: 22, color: parameter.iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parameter.label,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF888888)),
                ),
                Text(
                  '${parameter.value} ${parameter.unit}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  parameter.description,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF888888)),
            onPressed: () => _showEditDialog(context),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditParameterDialog(
        parameter: parameter,
        onSave: (newValue) {
          onValueUpdated(newValue);
          Navigator.of(context).pop();
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}