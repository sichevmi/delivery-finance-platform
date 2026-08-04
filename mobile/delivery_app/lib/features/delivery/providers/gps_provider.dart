import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/delivery/services/gps_service.dart';
import 'package:delivery_app/features/delivery/providers/shift_provider.dart';

// Провайдер для инициализации GPS
final gpsInitProvider = Provider((ref) {
  print('🟢 gpsInitProvider: создаём/получаем GpsService');
  
  // Создаём/получаем синглтон
  final gpsService = GpsService();
  
  final shiftNotifier = ref.watch(shiftProvider.notifier);
  
  print('🟢 gpsInitProvider: настройка колбэка');
  
  gpsService.setOnDistanceUpdate((deltaKm, isPaid) {
    final shiftState = ref.read(shiftProvider);
    print('📍 GPS колбэк вызван: deltaKm=$deltaKm, isPaid=$isPaid, isActive=${shiftState.isActive}, isOnOrder=${shiftState.isOnOrder}');
    
    if (shiftState.isActive) {
      if (shiftState.isOnOrder) {
        shiftNotifier.updatePaidDistance(deltaKm);
        print('✅ Добавлено к платному пробегу: $deltaKm км');
      } else {
        shiftNotifier.addIdleDistance(deltaKm);
        print('✅ Добавлено к холостому пробегу: $deltaKm км');
      }
    } else {
      print('⚠️ Смена не активна, пробег не добавлен');
    }
  });
  
  return gpsService;
});

// Провайдер для получения экземпляра GpsService
final gpsServiceProvider = Provider<GpsService>((ref) {
  // Инициализируем GPS, если ещё не инициализирован
  ref.watch(gpsInitProvider);
  return GpsService();
});