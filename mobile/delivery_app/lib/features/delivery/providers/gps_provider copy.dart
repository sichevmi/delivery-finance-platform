import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';  // <-- ИСПРАВЛЕННЫЙ ИМПОРТ
import 'package:delivery_app/features/delivery/services/gps_service.dart';
import 'package:delivery_app/features/delivery/providers/shift_provider.dart';

final gpsServiceProvider = Provider<GpsService>((ref) {
  logMessage('🟢 gpsServiceProvider: создаём GpsService');
  final gpsService = GpsService();
  
  // Настраиваем колбэк
  gpsService.setOnDistanceUpdate((deltaKm, isPaid) {
    final shiftState = ref.read(shiftProvider);
    logMessage('📍 GPS колбэк: deltaKm=$deltaKm, isActive=${shiftState.isActive}, isOnOrder=${shiftState.isOnOrder}');
    
    if (!shiftState.isActive) {
      logMessage('⚠️ Смена не активна, пробег не добавлен');
      return;
    }
    
    final shiftNotifier = ref.read(shiftProvider.notifier);
    
    if (shiftState.isOnOrder) {
      shiftNotifier.updatePaidDistance(deltaKm);
      logMessage('✅ Платный пробег: $deltaKm км');
    } else {
      shiftNotifier.addIdleDistance(deltaKm);
      logMessage('✅ Холостой пробег: $deltaKm км');
    }
  });
  
  return gpsService;
});

// Провайдер для инициализации
final gpsInitProvider = Provider((ref) {
  return ref.watch(gpsServiceProvider);
});