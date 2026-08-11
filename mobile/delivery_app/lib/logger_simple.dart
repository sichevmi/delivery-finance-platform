// lib/logger_simple.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AppLogger {
  static File? _logFile;
  static bool _isReady = false;

  static Future<void> init() async {
    if (_isReady) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${dir.path}/logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      final name = 'app_log_${DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19)}.txt';
      _logFile = File('${logDir.path}/$name');
      _isReady = true;
      
      // Пишем заголовок
      _write('=' * 80);
      _write('📱 FinFlow Delivery Logs');
      _write('🕐 Started: ${DateTime.now()}');
      _write('=' * 80);
      _write('');
      
      print('📁 LOG FILE: ${_logFile!.path}');
    } catch (e) {
      print('❌ AppLogger init error: $e');
    }
  }

  static void _write(String msg) {
    if (!_isReady || _logFile == null) return;
    try {
      _logFile!.writeAsStringSync(
        '$msg\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }

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