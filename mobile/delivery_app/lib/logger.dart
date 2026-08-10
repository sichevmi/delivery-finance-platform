// lib/logger.dart
export 'features/delivery/services/logger_service.dart';

// Импортируем сервис для работы внутри файла
import 'features/delivery/services/logger_service.dart';

final LoggerService _logger = LoggerService();

// Глобальная функция для логирования
void logMessage(
  dynamic message, {
  LogLevel level = LogLevel.info,
  String? category,
}) {
  _logger.log(message, level: level, category: category);
}

// Получить экземпляр логгера
LoggerService get logger => _logger;

// Инициализация логгера
Future<void> initLogger() async {
  await _logger.init();
}