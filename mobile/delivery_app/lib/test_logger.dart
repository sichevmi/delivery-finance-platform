// lib/test_logger.dart
import 'dart:io';

class TestLogger {
  static final String logPath = '/data/user/0/com.example.delivery_app/app_flutter/gps_log_final.txt';
  
  static void log(String message) {
    try {
      final file = File(logPath);
      file.writeAsStringSync(
        '${DateTime.now().toIso8601String()} $message\n',
        mode: FileMode.append,
      );
      print('📝 ЛОГ ЗАПИСАН: $message');
    } catch (e) {
      print('❌ ОШИБКА ЗАПИСИ ЛОГА: $e');
    }
  }
}