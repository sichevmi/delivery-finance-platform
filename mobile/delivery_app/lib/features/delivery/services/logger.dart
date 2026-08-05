// lib/features/delivery/services/logger.dart
import 'package:delivery_app/features/delivery/services/logger_service.dart';

// Глобальный экземпляр логгера
final LoggerService _logger = LoggerService();

// Функция для логирования (заменяет print)
void logMessage(dynamic message) {
  _logger.log(message);
}

// Функция для инициализации логгера
Future<void> initLogger() async {
  await _logger.init();
}

// Получить экземпляр логгера
LoggerService get logger => _logger;