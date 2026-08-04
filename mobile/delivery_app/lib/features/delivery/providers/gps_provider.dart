import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/delivery/services/gps_service.dart';
import 'package:delivery_app/features/delivery/providers/shift_provider.dart';

final gpsInitProvider = Provider((ref) {
  print('🟢 gpsInitProvider: создаём/получаем GpsService');
  
  final gpsService = GpsService();
  final shiftNotifier = ref.watch(shiftProvider.notifier);
  
  print('🟢 gpsInitProvider: настройка колбэка');
  
  gpsService.setOnDistanceUpdate((deltaKm, isPaid) {
    final shiftState = ref.read(shiftProvider);
    print('📍 GPS колбэк: deltaKm=$deltaKm, isActive=${shiftState.isActive}, isOnOrder=${shiftState.isOnOrder}');
    
    if (!shiftState.isActive) {
      print('⚠️ Смена не активна, пробег не добавлен');
      return;
    }
    
    if (shiftState.isOnOrder) {
      shiftNotifier.updatePaidDistance(deltaKm);
      print('✅ Платный пробег: $deltaKm км');
    } else {
      shiftNotifier.addIdleDistance(deltaKm);
      print('✅ Холостой пробег: $deltaKm км');
    }
  });
  
  return gpsService;
});

final gpsServiceProvider = Provider<GpsService>((ref) {
  ref.watch(gpsInitProvider);
  return GpsService();
});