// lib/simple_logger.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SimpleLogger {
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
      print('📁 SIMPLE LOGGER: ${_logFile!.path}');
    } catch (e) {
      print('❌ SIMPLE LOGGER ERROR: $e');
    }
  }

  static void log(String message) {
    if (!_isInitialized || _logFile == null) {
      print('⚠️ LOGGER NOT INITIALIZED: $message');
      return;
    }
    try {
      _logFile!.writeAsStringSync(
        '[${DateTime.now().toIso8601String()}] $message\n',
        mode: FileMode.append,
      );
    } catch (e) {
      print('❌ LOG ERROR: $e');
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