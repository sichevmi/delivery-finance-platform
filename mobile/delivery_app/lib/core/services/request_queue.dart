import 'dart:async';
import 'package:dio/dio.dart';
import 'package:delivery_app/logger.dart';

class QueuedRequest {
  final Future<void> Function() send;
  final String id;

  QueuedRequest({required this.send, required this.id});
}

class RequestQueue {
  static final RequestQueue _instance = RequestQueue._();
  factory RequestQueue() => _instance;
  RequestQueue._();

  final List<QueuedRequest> _queue = [];
  Timer? _timer;
  bool _isProcessing = false;

  void add(QueuedRequest request) {
    _queue.add(request);
    logMessage('📦 Запрос добавлен в очередь: ${request.id}', category: 'QUEUE');
    _startProcessing();
  }

  void _startProcessing() {
    if (_isProcessing) return;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _process());
  }

  Future<void> _process() async {
    if (_queue.isEmpty) {
      _timer?.cancel();
      return;
    }

    if (!await _hasInternet()) {
      logMessage('📡 Нет интернета, очередь ждёт', category: 'QUEUE');
      return;
    }

    _isProcessing = true;
    while (_queue.isNotEmpty) {
      try {
        await _queue.first.send();
        logMessage('✅ Запрос отправлен: ${_queue.first.id}', category: 'QUEUE');
        _queue.removeAt(0);
      } catch (e) {
        logMessage('❌ Ошибка отправки запроса: ${_queue.first.id} — $e', category: 'QUEUE');
        break; // прерываем, попробуем позже
      }
    }
    _isProcessing = false;
    if (_queue.isEmpty) _timer?.cancel();
  }

  Future<bool> _hasInternet() async {
    try {
      await Dio().head('http://195.19.20.178:8001');
      return true;
    } catch (_) {
      return false;
    }
  }
}