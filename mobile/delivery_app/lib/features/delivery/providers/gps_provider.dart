import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/delivery/services/gps_service.dart';
import 'package:delivery_app/features/delivery/providers/shift_provider.dart';

final gpsServiceProvider = Provider<GpsService>((ref) {
  return GpsService();
});

// Провайдер для инициализации GPS – настраивает колбэк один раз
final gpsInitProvider = Provider((ref) {
  final gpsService = ref.watch(gpsServiceProvider);
  final shiftNotifier = ref.watch(shiftProvider.notifier);
  
  // Настраиваем колбэк один раз при инициализации
  gpsService.setOnDistanceUpdate((deltaKm, isPaid) {
    final shiftState = ref.read(shiftProvider);
    
    // Добавляем расстояние только если смена активна
    if (shiftState.isActive) {
      if (shiftState.isOnOrder) {
        // Если на заказе - платный пробег
        shiftNotifier.updatePaidDistance(deltaKm);
      } else {
        // Если не на заказе - холостой
        shiftNotifier.addIdleDistance(deltaKm);
      }
    }
  });
  
  // Возвращаем сервис для использования в других местах
  return gpsService;
});