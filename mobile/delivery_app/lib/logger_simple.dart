// lib/logger_simple.dart
import 'dart:io';

class AppLogger {
  static File? _logFile;
  static bool _isReady = false;

  // Публичные поля для доступа из main.dart
  static set _logFile(File? file) => _logFile = file;
  static set _isReady(bool ready) => _isReady = ready;

  static void log(String msg) {
    final ts = DateTime.now().toIso8601String();
    final line = '[$ts] $msg';
    print(line);
    if (_isReady && _logFile != null) {
      try {
        _logFile!.writeAsStringSync(
          '$line\n',
          mode: FileMode.append,
        );
      } catch (_) {}
    }
  }

  static Future<String?> getPath() async => _logFile?.path;
  static Future<String> read() async {
    if (_logFile == null || !await _logFile!.exists()) return 'Файл не найден';
    return await _logFile!.readAsString();
  }
}