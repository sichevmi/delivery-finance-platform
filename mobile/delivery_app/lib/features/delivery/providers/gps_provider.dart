import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/features/delivery/services/gps_service.dart';
import 'package:delivery_app/features/delivery/providers/shift_provider.dart';

final gpsServiceProvider = Provider<GpsService>((ref) {
  logMessage('🟢 gpsServiceProvider: создаём GpsService', category: 'GPS');
  final gpsService = GpsService();
  
  // Настраиваем колбэк
  gpsService.setOnDistanceUpdate((deltaKm, isPaid) {
    final shiftState = ref.read(shiftProvider);
    final shiftNotifier = ref.read(shiftProvider.notifier);
    
    logMessage('📍 GPS колбэк: deltaKm=$deltaKm, isActive=${shiftState.isActive}, isOnOrder=${shiftState.isOnOrder}', category: 'GPS');
    
    // Если смена не активна — ничего не делаем
    if (!shiftState.isActive) {
      logMessage('⚠️ Смена не активна, пробег не добавлен', category: 'GPS');
      return;
    }
    
    // Если на заказе — НЕ добавляем платный пробег через GPS!
    // Платный пробег будет добавлен при завершении заказа через finishOrder.
    if (shiftState.isOnOrder) {
      // Только логируем, без добавления в БД
      logMessage('📍 GPS на заказе: deltaKm=$deltaKm (не добавляем, будет учтён при завершении)', category: 'GPS');
      return;
    }
    
    // Если не на заказе — холостой пробег
    shiftNotifier.addIdleDistance(deltaKm);
    logMessage('✅ Холостой пробег: $deltaKm км', category: 'GPS');
  });
  
  return gpsService;
});

// Провайдер для инициализации
final gpsInitProvider = Provider((ref) {
  logMessage('🟢 GPS провайдер инициализирован', category: 'GPS');
  return ref.watch(gpsServiceProvider);
});