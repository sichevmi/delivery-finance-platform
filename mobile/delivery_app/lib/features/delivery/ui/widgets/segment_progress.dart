import 'package:flutter/material.dart';

class SegmentProgress extends StatelessWidget {
  final int currentSegment;
  final List<String> segments = const ['В магазин', 'Получение', 'К клиенту', 'Выдача'];

  const SegmentProgress({super.key, required this.currentSegment});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(segments.length, (index) {
        final isActive = index == currentSegment;
        final isCompleted = index < currentSegment;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: isCompleted || isActive ? const Color(0xFF6C63FF) : const Color(0xFF2C2C2C),
                      ),
                    ),
                  ),
                  if (index < segments.length - 1) const SizedBox(width: 2),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF6C63FF)
                          : isCompleted
                              ? const Color(0xFF6C63FF).withOpacity(0.3)
                              : const Color(0xFF2C2C2C),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive || isCompleted ? Colors.white : const Color(0xFF888888),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    segments[index],
                    style: TextStyle(
                      fontSize: 10,
                      color: isActive || isCompleted ? Colors.white : const Color(0xFF888888),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}