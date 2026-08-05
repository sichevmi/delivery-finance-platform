// lib/features/delivery/services/logger_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  File? _logFile;
  IOSink? _sink;
  bool _isInitialized = false;
  final List<String> _buffer = [];
  static const int _maxBufferSize = 100;
  
  // Для веба - храним логи в памяти
  final List<String> _webLogs = [];

  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      if (kIsWeb) {
        _isInitialized = true;
        _webLogs.add('=' * 80);
        _webLogs.add('📱 Логи приложения FinFlow Delivery (Web)');
        _webLogs.add('🕐 Время старта: ${DateTime.now()}');
        _webLogs.add('=' * 80);
        _webLogs.add('');
        print('📁 Логи хранятся в памяти (веб-версия)');
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      
      final fileName = 'app_log_${DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19)}.txt';
      _logFile = File('${logDir.path}/$fileName');
      
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

  // Метод для логирования
  void log(dynamic message) {
    // Выводим в консоль
    print(message);
    
    // Сохраняем
    if (kIsWeb) {
      _webLogs.add('[${DateTime.now().toIso8601String()}] $message');
      if (_webLogs.length > 10000) {
        _webLogs.removeAt(0);
      }
    } else {
      _writeToFile('$message');
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
      final timestamp = DateTime.now().toIso8601String();
      _sink!.writeln('[$timestamp] $message');
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

  Future<String?> getLogFilePath() async {
    if (kIsWeb) return null;
    if (_logFile == null) return null;
    return _logFile!.path;
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

  Future<List<File>> getLogFiles() async {
    if (kIsWeb) return [];
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      if (!await logDir.exists()) {
        return [];
      }
      final files = await logDir.list().where((entity) => entity is File).cast<File>().toList();
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return files;
    } catch (e) {
      return [];
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
      print('🧹 Удалено старых логов: ${files.length - keepCount}');
    } catch (e) {
      print('❌ Ошибка очистки логов: $e');
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