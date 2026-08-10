// lib/core/services/logger_service.dart
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
  final List<String> _buffer = [];
  static const int _maxBufferSize = 100;

  final List<String> _webLogs = [];
  static const int _maxWebLogs = 5000;

  final List<LogEntry> _recentLogs = [];
  static const int _maxRecentLogs = 200;

  Future<void> init() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      _isInitialized = true;
      _webLogs.add('=' * 80);
      _webLogs.add('📱 Логи приложения FinFlow Delivery (Web)');
      _webLogs.add('🕐 Время старта: ${DateTime.now()}');
      _webLogs.add('=' * 80);
      print('📁 Логи хранятся в памяти (веб-версия)');
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      print('🔴 Documents directory: ${directory.path}');
      
      final logDir = Directory('${directory.path}/logs');
      
      // ПРИНУДИТЕЛЬНО СОЗДАЁМ ПАПКУ
      if (!await logDir.exists()) {
        print('🔴 Создаём папку logs...');
        await logDir.create(recursive: true);
        print('🔴 Папка logs создана');
      }

      final fileName = 'app_log_${DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19)}.txt';
      _logFile = File('${logDir.path}/$fileName');
      
      // ПРИНУДИТЕЛЬНО СОЗДАЁМ ФАЙЛ
      if (!await _logFile!.exists()) {
        await _logFile!.create(recursive: true);
      }
      
      _sink = _logFile!.openWrite(mode: FileMode.append);
      _isInitialized = true;

      _writeToFile('=' * 80);
      _writeToFile('📱 Логи приложения FinFlow Delivery');
      _writeToFile('🕐 Время старта: ${DateTime.now()}');
      _writeToFile('=' * 80);
      _writeToFile('');

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

    _recentLogs.add(entry);
    if (_recentLogs.length > _maxRecentLogs) {
      _recentLogs.removeAt(0);
    }

    if (kIsWeb) {
      _webLogs.add(entry.format());
      if (_webLogs.length > _maxWebLogs) {
        _webLogs.removeAt(0);
      }
    } else {
      _writeToFile(entry.format());
    }
  }

  void _writeToFile(String message) {
    if (!_isInitialized || _sink == null) {
      _buffer.add(message);
      if (_buffer.length > _maxBufferSize) {
        _buffer.removeAt(0);
      }
      return;
    }

    try {
      _sink!.writeln(message);
      _sink!.flush();
    } catch (e) {
      // Игнорируем ошибки записи
    }
  }

  void _flushBuffer() {
    if (_buffer.isEmpty) return;
    for (final msg in _buffer) {
      _writeToFile(msg);
    }
    _buffer.clear();
  }

  Future<String> readLogs() async {
    if (kIsWeb) {
      return _webLogs.join('\n');
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
      
      final List<File> files = [];
      await for (final entity in logDir.list()) {
        if (entity is File) {
          files.add(entity);
        }
      }
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return files;
    } catch (e) {
      return [];
    }
  }

  Future<void> shareLogs() async {
    try {
      final content = await readLogs();
      if (content.isEmpty || content == 'Файл логов не найден') {
        throw Exception('Нет данных для отправки');
      }
      await Share.share(
        '📱 Логи FinFlow Delivery\n\n$content',
        subject: 'Логи приложения',
      );
    } catch (e) {
      log('Ошибка отправки логов: $e', level: LogLevel.error, category: 'LOGGER');
      rethrow;
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

// Глобальная функция для удобства
void logMessage(
  dynamic message, {
  LogLevel level = LogLevel.info,
  String? category,
}) {
  LoggerService().log(message, level: level, category: category);
}