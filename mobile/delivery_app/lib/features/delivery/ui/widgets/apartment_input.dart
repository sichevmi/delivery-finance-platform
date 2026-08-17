import 'package:flutter/material.dart';

class ApartmentInput extends StatefulWidget {
  final String initialApartment;
  final bool initialIsPrivateHouse;
  final ValueChanged<String> onApartmentChanged;
  final ValueChanged<bool> onPrivateHouseChanged;

  const ApartmentInput({
    super.key,
    required this.initialApartment,
    required this.initialIsPrivateHouse,
    required this.onApartmentChanged,
    required this.onPrivateHouseChanged,
  });

  @override
  State<ApartmentInput> createState() => _ApartmentInputState();
}

class _ApartmentInputState extends State<ApartmentInput> {
  late TextEditingController _controller;
  late bool _isPrivateHouse;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialApartment);
    _isPrivateHouse = widget.initialIsPrivateHouse;
  }

  @override
  void didUpdateWidget(ApartmentInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialApartment != widget.initialApartment) {
      _controller.text = widget.initialApartment;
    }
    if (oldWidget.initialIsPrivateHouse != widget.initialIsPrivateHouse) {
      _isPrivateHouse = widget.initialIsPrivateHouse;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isApartmentValid = _controller.text.trim().isNotEmpty || _isPrivateHouse;

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
                    color: isApartmentValid || _isPrivateHouse
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
                            controller: _controller,
                            enabled: !_isPrivateHouse,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              hintText: _isPrivateHouse ? 'Частный дом' : 'Введите номер',
                              hintStyle: TextStyle(
                                color: _isPrivateHouse ? const Color(0xFF888888) : const Color(0xFF666666),
                                fontSize: 14,
                              ),
                            ),
                            onChanged: (value) {
                              widget.onApartmentChanged(value);
                            },
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: _isPrivateHouse,
                          onChanged: (val) {
                            setState(() {
                              _isPrivateHouse = val ?? false;
                              if (_isPrivateHouse) {
                                _controller.text = '';
                                widget.onApartmentChanged('');
                              } else {
                                widget.onApartmentChanged(_controller.text);
                              }
                              widget.onPrivateHouseChanged(_isPrivateHouse);
                            });
                          },
                          activeColor: const Color(0xFF6C63FF),
                          side: BorderSide(
                            color: _isPrivateHouse ? const Color(0xFF6C63FF) : const Color(0xFF666666),
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