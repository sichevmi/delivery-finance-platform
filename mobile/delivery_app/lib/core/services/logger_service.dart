import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? category;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.category,
    this.stackTrace,
  });

  String format() {
    final levelStr = level.name.toUpperCase().padLeft(5);
    final categoryStr = category != null ? '[$category] ' : '';
    return '[$timestamp] $levelStr $categoryStr$message';
  }
}

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  bool _isInitialized = false;
  File? _logFile;
  IOSink? _sink;
  final List<LogEntry> _buffer = [];
  static const int _maxBufferSize = 100;
  static const int _maxLogFiles = 20;

  final List<LogEntry> _webLogs = [];
  static const int _maxWebLogs = 1000;

  final List<void Function(LogEntry)> _listeners = [];

  Future<void> init() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      _isInitialized = true;
      _log(LogLevel.info, '📱 Логи приложения FinFlow Delivery (Web)', category: 'SYSTEM');
      _log(LogLevel.info, '🕐 Время старта: ${DateTime.now()}', category: 'SYSTEM');
      _log(LogLevel.info, '=' * 80, category: 'SYSTEM');
      print('📁 Логи хранятся в памяти (веб-версия)');
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final fileName = 'app_log_${DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19)}.txt';
      _logFile = File('${logDir.path}/$fileName');
      _sink = _logFile!.openWrite(mode: FileMode.append);
      _isInitialized = true;

      _log(LogLevel.info, '=' * 80, category: 'SYSTEM');
      _log(LogLevel.info, '📱 Логи приложения FinFlow Delivery', category: 'SYSTEM');
      _log(LogLevel.info, '🕐 Время старта: ${DateTime.now()}', category: 'SYSTEM');
      _log(LogLevel.info, '=' * 80, category: 'SYSTEM');

      print('📁 Логи будут сохранены в: ${_logFile!.path}');

      _flushBuffer();
    } catch (e) {
      print('❌ Ошибка инициализации логгера: $e');
      _isInitialized = true;
    }
  }

  void log(
    dynamic message, {
    LogLevel level = LogLevel.info,
    String? category,
    StackTrace? stackTrace,
  }) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message.toString(),
      category: category,
      stackTrace: stackTrace,
    );

    print(entry.format());

    if (kIsWeb) {
      _webLogs.add(entry);
      if (_webLogs.length > _maxWebLogs) {
        _webLogs.removeAt(0);
      }
    } else {
      _writeToFile(entry);
    }

    for (final listener in _listeners) {
      listener(entry);
    }
  }

  void _log(LogLevel level, dynamic message, {String? category}) {
    log(message, level: level, category: category);
  }

  void _writeToFile(LogEntry entry) {
    if (!_isInitialized || _sink == null) {
      _buffer.add(entry);
      if (_buffer.length > _maxBufferSize) {
        _buffer.removeAt(0);
      }
      return;
    }

    try {
      _sink!.writeln(entry.format());
      _sink!.flush();
    } catch (e) {
      // Игнорируем ошибки записи
    }
  }

  void _flushBuffer() {
    if (_buffer.isEmpty) return;
    for (final entry in _buffer) {
      _writeToFile(entry);
    }
    _buffer.clear();
  }

  void addListener(void Function(LogEntry) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(LogEntry) listener) {
    _listeners.remove(listener);
  }

  Future<String> readLogs() async {
    if (kIsWeb) {
      return _webLogs.map((e) => e.format()).join('\n');
    }
    if (_logFile == null || !await _logFile!.exists()) {
      return 'Файл логов не найден';
    }
    try {
      return await _logFile!.readAsString();
    } catch (e) {
      return 'Ошибка чтения логов: $e';
    }
  }

  Future<String?> getLogFilePath() async {
    if (kIsWeb) return null;
    return _logFile?.path;
  }

  Future<List<File>> getLogFiles() async {
    if (kIsWeb) return [];
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      if (!await logDir.exists()) return [];
      final files = await logDir.list().map((e) => e as File).toList();
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return files;
    } catch (e) {
      return [];
    }
  }

  Future<void> shareLogs() async {
    try {
      final content = await readLogs();
      await Share.share(
        '📱 Логи FinFlow Delivery\n\n$content',
        subject: 'Логи приложения',
      );
    } catch (e) {
      log('Ошибка отправки логов: $e', level: LogLevel.error, category: 'LOGGER');
    }
  }

  Future<void> cleanOldLogs({int keepCount = 10}) async {
    if (kIsWeb) return;
    try {
      final files = await getLogFiles();
      if (files.length <= keepCount) return;
      for (int i = keepCount; i < files.length; i++) {
        await files[i].delete();
      }
      log('🧹 Удалено старых логов: ${files.length - keepCount}', category: 'LOGGER');
    } catch (e) {
      log('Ошибка очистки логов: $e', level: LogLevel.error, category: 'LOGGER');
    }
  }

  Future<void> dispose() async {
    if (_sink != null) {
      await _sink!.flush();
      await _sink!.close();
      _sink = null;
    }
    _isInitialized = false;
  }
}

void logMessage(
  dynamic message, {
  LogLevel level = LogLevel.info,
  String? category,
}) {
  LoggerService().log(message, level: level, category: category);
}