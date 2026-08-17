import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/features/delivery/services/gps_service.dart';
import 'package:delivery_app/features/delivery/providers/shift_provider.dart';

final gpsServiceProvider = Provider<GpsService>((ref) {
  logMessage('🟢 gpsServiceProvider: создаём GpsService', category: 'GPS');
  final gpsService = GpsService();
  
  gpsService.setOnDistanceUpdate((deltaKm, isPaid) {
    final shiftState = ref.read(shiftProvider);
    final shiftNotifier = ref.read(shiftProvider.notifier);
    
    logMessage('📍 [GPS] Колбэк: deltaKm=$deltaKm, isPaid=$isPaid', category: 'GPS');
    logMessage('📍 [GPS] Состояние: isActive=${shiftState.isActive}, isOnOrder=${shiftState.isOnOrder}', category: 'GPS');
    logMessage('📍 [GPS] Текущий холостой пробег: ${shiftState.totalIdleDistance}', category: 'GPS');
    
    if (!shiftState.isActive) {
      logMessage('⚠️ [GPS] Смена не активна, пробег НЕ добавлен', category: 'GPS');
      return;
    }
    
    if (shiftState.isOnOrder) {
      logMessage('📍 [GPS] На заказе, холостой пробег НЕ добавляем', category: 'GPS');
      return;
    }
    
    // ===== ХОЛОСТОЙ ПРОБЕГ =====
    logMessage('✅ [GPS] Добавляем холостой пробег: +$deltaKm км', category: 'GPS');
    shiftNotifier.addIdleDistance(deltaKm);
    
    // Проверяем, что добавилось
    final newState = ref.read(shiftProvider);
    logMessage('📊 [GPS] Новый холостой пробег: ${newState.totalIdleDistance} км', category: 'GPS');
  });
  
  return gpsService;
});

final gpsInitProvider = Provider((ref) {
  logMessage('🟢 GPS провайдер инициализирован', category: 'GPS');
  return ref.watch(gpsServiceProvider);
});