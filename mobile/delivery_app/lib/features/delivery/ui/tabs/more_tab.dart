import 'package:flutter/material.dart';
import 'package:delivery_app/features/delivery/services/gps_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.file_download),
          title: const Text('Выгрузить логи GPS'),
          subtitle: const Text('Сохранить логи в файл и поделиться'),
          onTap: _exportLogs,
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('Настройки'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('О приложении'),
          onTap: () {},
        ),
      ],
    );
  }

  Future<void> _exportLogs(BuildContext context) async {
    try {
      // Проверяем разрешение на запись
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Необходимо разрешение на запись'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Получаем логи
      final gpsService = GpsService();
      final logPath = await gpsService.getLogPath();
      final logContent = await gpsService.getLog();

      if (logContent == null || logContent.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Логов пока нет'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Показываем диалог с содержимым и кнопкой поделиться
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Логи GPS',
            style: TextStyle(color: Colors.white),
          ),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: SingleChildScrollView(
              child: Text(
                logContent,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Закрыть',
                style: TextStyle(color: Color(0xFF888888)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final path = await gpsService.getLogPath();
                if (path != null) {
                  await Share.shareXFiles(
                    [XFile(path)],
                    text: 'GPS логи приложения',
                  );
                }
                Navigator.pop(context);
              },
              icon: const Icon(Icons.share),
              label: const Text('Поделиться'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}