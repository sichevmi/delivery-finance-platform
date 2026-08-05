// lib/features/delivery/providers/logger_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/delivery/services/logger_service.dart';

final loggerServiceProvider = Provider<LoggerService>((ref) {
  return LoggerService();
});