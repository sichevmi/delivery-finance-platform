// lib/logger.dart
import 'package:delivery_app/features/delivery/services/logger_service.dart';

final LoggerService _logger = LoggerService();

// Глобальная функция для логирования
void logMessage(dynamic message) {
  _logger.log(message);
}

// Получить экземпляр логгера
LoggerService get logger => _logger;

// Инициализация логгера
Future<void> initLogger() async {
  await _logger.init();
}