import 'package:flutter/material.dart';

class GpsControl extends StatefulWidget {
  final bool useGps;
  final double distance;
  final double gpsDistance; // <-- НОВОЕ: расстояние от GPS
  final bool isPaused;
  final VoidCallback onToggleGpsMode;
  final ValueChanged<double> onManualDistanceChanged;
  final VoidCallback onTogglePause;

  const GpsControl({
    super.key,
    required this.useGps,
    required this.distance,
    required this.gpsDistance,
    required this.isPaused,
    required this.onToggleGpsMode,
    required this.onManualDistanceChanged,
    required this.onTogglePause,
  });

  @override
  State<GpsControl> createState() => _GpsControlState();
}

class _GpsControlState extends State<GpsControl> {
  final TextEditingController _manualController = TextEditingController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _manualController.text = '';
  }

  @override
  void didUpdateWidget(GpsControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Если переключились с GPS на ручной — очищаем поле
    if (!widget.useGps && oldWidget.useGps) {
      _manualController.text = '';
      _isTyping = false;
      return;
    }
    
    // Если переключились с ручного на GPS — очищаем ручное поле
    if (widget.useGps && !oldWidget.useGps) {
      _manualController.text = '';
      _isTyping = false;
      return;
    }
    
    // Обновляем только если не в процессе ввода и в ручном режиме
    if (!_isTyping && !widget.useGps && widget.distance > 0) {
      final newText = widget.distance.toStringAsFixed(2);
      if (_manualController.text != newText) {
        _manualController.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Показываем расстояние в зависимости от режима
    final displayDistance = widget.useGps ? widget.gpsDistance : widget.distance;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2C2C2C), width: 1),
      ),
      child: Row(
        children: [
          _buildToggleButton('GPS', widget.useGps, () {
            widget.onToggleGpsMode();
            // При переключении на GPS очищаем ручное поле
            if (!widget.useGps) {
              _manualController.text = '';
              _isTyping = false;
            }
          }),
          const SizedBox(width: 6),
          _buildToggleButton('Вручную', !widget.useGps, () {
            widget.onToggleGpsMode();
            // При переключении на ручной ввод очищаем поле
            if (widget.useGps) {
              _manualController.text = '';
              _isTyping = false;
            }
          }),
          const Spacer(),
          if (widget.useGps)
            Row(
              children: [
                const Icon(Icons.straighten, size: 16, color: Color(0xFF6C63FF)),
                const SizedBox(width: 4),
                Text(
                  '${displayDistance.toStringAsFixed(2)} км',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: 60,
              child: TextField(
                controller: _manualController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: '0.0',
                  hintStyle: TextStyle(color: Color(0xFF666666)),
                ),
                onChanged: (value) {
                  _isTyping = true;
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed != null && parsed >= 0) {
                    widget.onManualDistanceChanged(parsed);
                  }
                  Future.delayed(const Duration(milliseconds: 500), () {
                    _isTyping = false;
                  });
                },
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onTogglePause,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.isPaused
                    ? Colors.green.withOpacity(0.15)
                    : Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: widget.isPaused
                      ? Colors.green.withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isPaused ? Icons.play_arrow : Icons.pause,
                    size: 14,
                    color: widget.isPaused ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    widget.isPaused ? 'Старт' : 'Пауза',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: widget.isPaused ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF2C2C2C),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : const Color(0xFF888888),
          ),
        ),
      ),
    );
  }
}