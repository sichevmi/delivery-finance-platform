import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:delivery_app/lib/features/delivery/providers/gps_provider.dart';
import 'package:delivery_app/lib/features/delivery/services/gps_service.dart';

class MoreTab extends ConsumerStatefulWidget {
  const MoreTab({super.key});

  @override
  ConsumerState<MoreTab> createState() => _MoreTabState();
}

class _MoreTabState extends ConsumerState<MoreTab> {
  bool _isLogging = false;
  String _logStatus = 'Логирование выключено';

  @override
  Widget build(BuildContext context) {
    final gpsService = ref.read(gpsServiceProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Настройки',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          Card(
            color: const Color(0xFF1E1E1E),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GPS логирование',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _logStatus,
                    style: TextStyle(
                      fontSize: 14,
                      color: _isLogging ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLogging ? null : () => _startLogging(gpsService),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isLogging
                                ? Colors.grey.shade700
                                : Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Начать логирование'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLogging ? () => _stopLogging(gpsService) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isLogging
                                ? Colors.red
                                : Colors.grey.shade700,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Остановить'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _shareLog(gpsService),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6C63FF),
                        side: const BorderSide(color: Color(0xFF6C63FF)),
                      ),
                      child: const Text('📤 Отправить лог'),
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

  Future<void> _startLogging(GpsService gpsService) async {
    setState(() {
      _isLogging = true;
      _logStatus = 'Логирование активно...';
    });
    await gpsService.startLogging();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Логирование запущено'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _stopLogging(GpsService gpsService) async {
    await gpsService.stopLogging();
    setState(() {
      _isLogging = false;
      _logStatus = 'Логирование остановлено';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Логирование остановлено. Файл сохранён.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _shareLog(GpsService gpsService) async {
    try {
      final path = await gpsService.getLogFilePath();
      if (path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Лог-файл не найден. Сначала запустите логирование.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final file = File(path);
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Файл лога не существует.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Открываем системный диалог шаринга
      await Share.shareXFiles(
        [XFile(path)],
        text: 'GPS лог от ${DateTime.now().toLocal().toString().substring(0, 19)}',
        subject: 'GPS лог',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Файл отправлен!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка отправки: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}