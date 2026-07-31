import 'package:flutter/material.dart';
import 'package:delivery_app/models/parameter_model.dart';

class EditParameterDialog extends StatefulWidget {
  final Parameter parameter;
  final ValueChanged<String> onSave;
  final VoidCallback onCancel;

  const EditParameterDialog({
    super.key,
    required this.parameter,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<EditParameterDialog> createState() => _EditParameterDialogState();
}

class _EditParameterDialogState extends State<EditParameterDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.parameter.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Редактировать ${widget.parameter.label}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _controller,
              enabled: !_isSaving,
              decoration: InputDecoration(
                labelText: 'Значение (${widget.parameter.unit})',
                hintText: 'Введите число',
                errorText: _errorText,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Поле обязательно';
                }
                final parsed = double.tryParse(value);
                if (parsed == null || parsed <= 0) {
                  return 'Введите положительное число';
                }
                return null;
              },
            ),
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : widget.onCancel,
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Сохранить'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 1500));
      // Для теста ошибки раскомментируйте:
      // if (DateTime.now().millisecond % 3 == 0) throw Exception('Ошибка сервера');
      widget.onSave(_controller.text.trim());
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorText = 'Не удалось сохранить. Попробуйте позже.';
      });
    }
  }
}