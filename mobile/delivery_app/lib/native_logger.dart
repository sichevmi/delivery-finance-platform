// lib/native_logger.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class NativeLogger {
  static File? _logFile;
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      final fileName = 'app_log_${DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19)}.txt';
      _logFile = File('${logDir.path}/$fileName');
      _isInitialized = true;
      
      // ПИШЕМ В КОНСОЛЬ И В ЛОГКАТ
      print('📁 LOG FILE: ${_logFile!.path}');
      
      // Записываем заголовок
      _write('=' * 80);
      _write('📱 Логи приложения FinFlow Delivery');
      _write('🕐 Время старта: ${DateTime.now()}');
      _write('=' * 80);
      _write('');
      
    } catch (e) {
      print('❌ LOGGER ERROR: $e');
    }
  }

  static void _write(String message) {
    if (!_isInitialized || _logFile == null) return;
    try {
      _logFile!.writeAsStringSync(
        '[$timestamp] $message\n',
        mode: FileMode.append,
      );
    } catch (e) {
      // Игнорируем
    }
  }

  static String get timestamp => DateTime.now().toIso8601String();

  static void log(String message) {
    // Всегда выводим в консоль
    print('[$timestamp] $message');
    
    // Пишем в файл
    if (_isInitialized && _logFile != null) {
      try {
        _logFile!.writeAsStringSync(
          '[$timestamp] $message\n',
          mode: FileMode.append,
        );
      } catch (e) {
        // Игнорируем ошибки записи
      }
    }
  }

  static Future<String?> getLogFilePath() async {
    return _logFile?.path;
  }

  static Future<String> readLogs() async {
    if (_logFile == null || !await _logFile!.exists()) {
      return 'Файл логов не найден';
    }
    try {
      return await _logFile!.readAsString();
    } catch (e) {
      return 'Ошибка чтения логов: $e';
    }
  }
}