import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/delivery/services/gps_service.dart';
import 'package:delivery_app/features/delivery/providers/shift_provider.dart';

// Храним ссылку на GpsService
final gpsServiceInstanceProvider = StateProvider<GpsService?>((ref) => null);

// Инициализация GPS
final gpsInitProvider = Provider((ref) {
  print('🟢 gpsInitProvider: создаём GpsService');
  
  final gpsService = GpsService();
  
  // Сохраняем ссылку в StateProvider
  ref.read(gpsServiceInstanceProvider.notifier).state = gpsService;
  print('🟢 GpsService сохранён в провайдере');
  
  // Получаем shiftNotifier через watch
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
  
  print('🟢 gpsInitProvider: колбэк настроен');
  return gpsService;
});

// Провайдер для получения GpsService
final gpsServiceProvider = Provider<GpsService>((ref) {
  final instance = ref.watch(gpsServiceInstanceProvider);
  if (instance == null) {
    // Если ещё не инициализирован - инициализируем
    print('⚠️ GpsService не инициализирован, инициализируем...');
    ref.read(gpsInitProvider);
    final newInstance = ref.watch(gpsServiceInstanceProvider);
    if (newInstance == null) {
      throw StateError('GpsService не инициализирован');
    }
    return newInstance;
  }
  return instance;
});