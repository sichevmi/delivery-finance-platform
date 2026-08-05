import 'package:flutter/material.dart';
import 'package:delivery_app/features/delivery/services/logger.dart';

class Parameter {
  final String id;            // уникальный ключ (для будущей работы с БД)
  final IconData icon;
  final String label;
  final String value;         // значение без единицы измерения
  final String unit;          // единица измерения (отображается отдельно)
  final String description;
  final Color iconColor;

  Parameter({
    required this.id,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.description,
    this.iconColor = const Color(0xFF6C63FF),
  });

  // Копирование с новым значением
  Parameter copyWith({String? value}) {
    return Parameter(
      id: id,
      icon: icon,
      label: label,
      value: value ?? this.value,
      unit: unit,
      description: description,
      iconColor: iconColor,
    );
  }
}