import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  bool _isRecording = false;
  String _logBuffer = '';
  String? _logFilePath;
  Timer? _flushTimer;
  static const int _flushInterval = 5; // секунд

  bool get isRecording => _isRecording;

  Future<void> startRecording() async {
    if (_isRecording) return;
    _isRecording = true;
    _logBuffer = '';

    // Создаём файл с меткой времени
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final dir = await getApplicationDocumentsDirectory();
    _logFilePath = '${dir.path}/gps_log_$timestamp.txt';

    // Записываем заголовок
    _writeToBuffer('=== GPS LOG STARTED at ${DateTime.now()} ===\n');
    _writeToBuffer('Device: ${Platform.operatingSystem} ${Platform.version}\n');
    _writeToBuffer('========================================\n\n');

    // Запускаем таймер для периодической записи на диск
    _flushTimer = Timer.periodic(
      Duration(seconds: _flushInterval),
      (timer) => _flushBuffer(),
    );

    print('🟢 LogService: recording started, file: $_logFilePath');
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;
    _isRecording = false;
    _flushTimer?.cancel();
    _flushTimer = null;
    await _flushBuffer();
    print('🟢 LogService: recording stopped, file: $_logFilePath');
  }

  void log(String message) {
    if (!_isRecording) return;
    final timestamp = DateTime.now().toIso8601String();
    _writeToBuffer('[$timestamp] $message\n');
  }

  void _writeToBuffer(String text) {
    _logBuffer += text;
  }

  Future<void> _flushBuffer() async {
    if (_logBuffer.isEmpty || _logFilePath == null) return;
    try {
      final file = File(_logFilePath!);
      await file.writeAsString(_logBuffer, mode: FileMode.append);
      _logBuffer = '';
    } catch (e) {
      print('⚠️ LogService: error flushing buffer: $e');
    }
  }

  Future<String?> getLogFilePath() async {
    if (_logFilePath == null) return null;
    final file = File(_logFilePath!);
    if (await file.exists()) {
      return _logFilePath;
    }
    return null;
  }

  Future<void> shareLogFile() async {
    final path = await getLogFilePath();
    if (path == null) return;
    await Share.shareXFiles([XFile(path)], text: 'GPS Log file');
  }

  Future<void> clearLogFile() async {
    if (_logFilePath == null) return;
    try {
      final file = File(_logFilePath!);
      if (await file.exists()) {
        await file.delete();
      }
      _logBuffer = '';
      _logFilePath = null;
    } catch (e) {
      print('⚠️ LogService: error clearing log file: $e');
    }
  }
}