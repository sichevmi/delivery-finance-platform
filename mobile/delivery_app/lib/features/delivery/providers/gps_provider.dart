import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/features/delivery/services/gps_service.dart';

final gpsServiceProvider = Provider<GpsService>((ref) {
  logMessage('🟢 gpsServiceProvider: создаём GpsService', category: 'GPS');
  final gpsService = GpsService();
  
  // Колбэк больше не используется, так как пробег добавляется только на сервере
  // Можно оставить пустую заглушку или вообще не устанавливать
  gpsService.setOnDistanceUpdate((deltaKm, isPaid) {
    logMessage('📍 GPS колбэк: deltaKm=$deltaKm, isPaid=$isPaid (игнорируем)', category: 'GPS');
  });
  
  return gpsService;
});

// Провайдер для инициализации
final gpsInitProvider = Provider((ref) {
  logMessage('🟢 GPS провайдер инициализирован', category: 'GPS');
  return ref.watch(gpsServiceProvider);
});