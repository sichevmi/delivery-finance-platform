import 'package:drift/drift.dart';
import 'package:delivery_app/core/database/database_provider.dart';
import 'package:delivery_app/core/services/api_client.dart';
import 'package:delivery_app/core/services/connectivity_service.dart';
import 'package:delivery_app/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SyncService {
  final AppDatabase _db;
  final ApiClient _apiClient;
  final ConnectivityService _connectivity;

  SyncService(this._db, this._apiClient, this._connectivity);

  bool _isSyncing = false;
  bool _isLoadingFromServer = false; // 🔥 ЗАЩИТА ОТ ДВОЙНОГО ВЫЗОВА

  bool get isSyncing => _isSyncing;

  // ===== ОСНОВНАЯ СИНХРОНИЗАЦИЯ =====

  Future<void> syncAll() async {
    if (_isSyncing) {
      logMessage('⚠️ Синхронизация уже выполняется', category: 'SYNC');
      return;
    }

    final hasInternet = await _connectivity.hasInternet();
    if (!hasInternet) {
      logMessage('⚠️ Нет интернета, синхронизация отложена', category: 'SYNC');
      return;
    }

    _isSyncing = true;
    logMessage('🔄 Начинаем синхронизацию...', category: 'SYNC');

    try {
      await _syncSettings();
      await _syncShifts();
      await _syncOrders();
      logMessage('✅ Синхронизация завершена', category: 'SYNC');
    } catch (e) {
      logMessage('❌ Ошибка синхронизации: $e', category: 'SYNC', level: LogLevel.error);
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  // ===== ЗАГРУЗКА ДАННЫХ С СЕРВЕРА =====

  Future<void> loadFromServer() async {
    // 🔥 ЗАЩИТА ОТ ДВОЙНОГО ВЫЗОВА
    if (_isLoadingFromServer) {
      logMessage('⏭️ Загрузка с сервера уже выполняется, пропускаем', category: 'SYNC');
      return;
    }

    final hasInternet = await _connectivity.hasInternet();
    if (!hasInternet) {
      logMessage('⚠️ Нет интернета, загрузка с сервера невозможна', category: 'SYNC');
      return;
    }

    _isLoadingFromServer = true;
    try {
      logMessage('📥 Загрузка данных с сервера...', category: 'SYNC');

      // 1. Загружаем справочники
      await _loadDirectories();

      // 2. Загружаем данные за сегодня
      await _loadTodayData();

      logMessage('✅ Загрузка с сервера завершена', category: 'SYNC');
    } catch (e) {
      logMessage('❌ Ошибка загрузки с сервера: $e', category: 'SYNC', level: LogLevel.error);
    } finally {
      _isLoadingFromServer = false;
    }
  }

  // ===== ЗАГРУЗКА СПРАВОЧНИКОВ =====

  Future<void> _loadDirectories() async {
    try {
      logMessage('📥 Загрузка справочников с сервера...', category: 'SYNC');
      final response = await _apiClient.getDirectories();

      if (response['status'] != 'success') {
        logMessage('⚠️ Ошибка загрузки справочников', category: 'SYNC');
        return;
      }

      final settings = response['settings'];
      if (settings != null && settings['id'] != null) {
        await _updateSettingsLocal(settings);
      }

      final pricing = response['pricing'];
      if (pricing != null && pricing['id'] != null) {
        await _updatePricingLocal(pricing);
      }

      final x5Settings = response['x5Settings'];
      if (x5Settings != null && x5Settings['id'] != null) {
        await _updateX5SettingsLocal(x5Settings);
      }

      logMessage('✅ Справочники загружены с сервера', category: 'SYNC');
    } catch (e) {
      logMessage('❌ Ошибка загрузки справочников: $e', category: 'SYNC', level: LogLevel.error);
    }
  }

  Future<void> _updateSettingsLocal(Map<String, dynamic> data) async {
    try {
      final existing = await _db.settingsDao.getActiveSettings();
      if (existing != null) {
        if (data['version'] > existing.version) {
          await _db.settingsDao.updateSettings(
            existing.id,
            SettingsTableCompanion(
              fuelConsumption: Value(data['fuelConsumption'] ?? 10.0),
              fuelPrice: Value(data['fuelPrice'] ?? 50.0),
              repairCost: Value(data['repairCost'] ?? 2.0),
              additionalCosts: Value(data['additionalCosts'] ?? 0.0),
              version: Value(data['version'] ?? 1),
              isSynced: const Value(true),
              updatedAt: Value(DateTime.now()),
            ),
          );
          logMessage('✅ Настройки обновлены с сервера (версия ${data['version']})', category: 'SYNC');
        }
      } else {
        await _db.settingsDao.insertSettings(
          SettingsTableCompanion(
            fuelConsumption: Value(data['fuelConsumption'] ?? 10.0),
            fuelPrice: Value(data['fuelPrice'] ?? 50.0),
            repairCost: Value(data['repairCost'] ?? 2.0),
            additionalCosts: Value(data['additionalCosts'] ?? 0.0),
            version: Value(data['version'] ?? 1),
            isDefault: const Value(true),
            isActive: const Value(true),
            isSynced: const Value(true),
            createdAt: Value(DateTime.now()),
          ),
        );
        logMessage('✅ Настройки созданы с сервера', category: 'SYNC');
      }
    } catch (e) {
      logMessage('❌ Ошибка обновления настроек локально: $e', category: 'SYNC', level: LogLevel.error);
    }
  }

  Future<void> _updatePricingLocal(Map<String, dynamic> data) async {
    try {
      final existing = await _db.pricingDao.getActivePricing();
      if (existing != null) {
        if (data['version'] > existing.version) {
          await _db.pricingDao.updatePricing(
            existing.id,
            PricingTableCompanion(
              receivingFee: Value(data['receivingFee'] ?? 50.0),
              deliveryFee: Value(data['deliveryFee'] ?? 100.0),
              pricePerKg: Value(data['pricePerKg'] ?? 5.0),
              pricePerKm: Value(data['pricePerKm'] ?? 10.0),
              baseCoefficient: Value(data['baseCoefficient'] ?? 1.0),
              version: Value(data['version'] ?? 1),
              isSynced: const Value(true),
              updatedAt: Value(DateTime.now()),
            ),
          );
          logMessage('✅ Тарифы обновлены с сервера (версия ${data['version']})', category: 'SYNC');
        }
      } else {
        await _db.pricingDao.insertPricing(
          PricingTableCompanion(
            receivingFee: Value(data['receivingFee'] ?? 50.0),
            deliveryFee: Value(data['deliveryFee'] ?? 100.0),
            pricePerKg: Value(data['pricePerKg'] ?? 5.0),
            pricePerKm: Value(data['pricePerKm'] ?? 10.0),
            baseCoefficient: Value(data['baseCoefficient'] ?? 1.0),
            version: Value(data['version'] ?? 1),
            isDefault: const Value(true),
            isActive: const Value(true),
            isSynced: const Value(true),
            createdAt: Value(DateTime.now()),
          ),
        );
        logMessage('✅ Тарифы созданы с сервера', category: 'SYNC');
      }
    } catch (e) {
      logMessage('❌ Ошибка обновления тарифов локально: $e', category: 'SYNC', level: LogLevel.error);
    }
  }

  Future<void> _updateX5SettingsLocal(Map<String, dynamic> data) async {
    try {
      final existing = await _db.x5SettingsDao.getActiveX5Settings();
      if (existing != null) {
        await _db.x5SettingsDao.updateX5Settings(
          existing.id,
          X5SettingsTableCompanion(
            pickupPrice: Value(data['pickupPrice'] ?? 250.0),
            deliveryPrice: Value(data['deliveryPrice'] ?? 150.0),
            perKmPrice: Value(data['perKmPrice'] ?? 25.0),
            perKgPrice: Value(data['perKgPrice'] ?? 10.0),
            isSynced: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
        );
        logMessage('✅ X5 настройки обновлены с сервера', category: 'SYNC');
      } else {
        await _db.x5SettingsDao.insertX5Settings(
          X5SettingsTableCompanion(
            pickupPrice: Value(data['pickupPrice'] ?? 250.0),
            deliveryPrice: Value(data['deliveryPrice'] ?? 150.0),
            perKmPrice: Value(data['perKmPrice'] ?? 25.0),
            perKgPrice: Value(data['perKgPrice'] ?? 10.0),
            isDefault: const Value(true),
            isActive: const Value(true),
            isSynced: const Value(true),
            createdAt: Value(DateTime.now()),
          ),
        );
        logMessage('✅ X5 настройки созданы с сервера', category: 'SYNC');
      }
    } catch (e) {
      logMessage('❌ Ошибка обновления X5 настроек локально: $e', category: 'SYNC', level: LogLevel.error);
    }
  }

  // ===== ЗАГРУЗКА ДАННЫХ ЗА СЕГОДНЯ =====

  Future<void> _loadTodayData() async {
  try {
    logMessage('📥 Загрузка данных за сегодня...', category: 'SYNC');
    final response = await _apiClient.getTodayData();

    if (response['status'] != 'success') {
      logMessage('⚠️ Ошибка загрузки данных за сегодня', category: 'SYNC');
      return;
    }

    final shifts = response['shifts'] as List;
    final orders = response['orders'] as List;

    // 🔥 ПОЛУЧАЕМ АКТИВНУЮ СМЕНУ (ЕЁ НЕ УДАЛЯЕМ)
    final activeShift = await _db.shiftDao.getActiveShift();
    final activeShiftId = activeShift?.id;

    // 🔥 УДАЛЯЕМ ТОЛЬКО ЗАВЕРШЁННЫЕ СМЕНЫ С SERVER_ID
    final now = DateTime.now();
    final todayShifts = await _db.shiftDao.getShiftsForDate(now);
    for (final shift in todayShifts) {
      if (shift.id == activeShiftId) {
        logMessage('⏭️ Активная смена ${shift.id} сохранена', category: 'SYNC');
        continue;
      }
      if (shift.serverId != null && shift.status == 'completed') {
        await _db.shiftDao.deleteShift(shift.id);
        logMessage('🗑️ Удалена завершённая смена ${shift.id} (serverId=${shift.serverId})', category: 'SYNC');
      }
    }

    // 🔥 НЕ УДАЛЯЕМ ЗАКАЗЫ АКТИВНОЙ СМЕНЫ
    final todayOrders = await _db.orderDao.getOrdersForDate(now);
    for (final order in todayOrders) {
      if (order.shiftId == activeShiftId) {
        continue;
      }
      if (order.serverId != null) {
        final deliveries = await _db.deliveryDao.getDeliveriesByOrder(order.id);
        for (final delivery in deliveries) {
          await _db.deliveryDao.deleteDelivery(delivery.id);
        }
        await _db.orderDao.deleteOrder(order.id);
        logMessage('🗑️ Удалён заказ ${order.id} (serverId=${order.serverId})', category: 'SYNC');
      }
    }

    // Загружаем смены с сервера (пропускаем активную)
    for (final shiftData in shifts) {
      if (shiftData['id'] == activeShift?.serverId) {
        logMessage('⏭️ Активная смена ${shiftData['id']} уже есть, пропускаем', category: 'SYNC');
        continue;
      }
      await _db.shiftDao.insertShiftFromServer(shiftData);
      logMessage('💾 Смена ${shiftData['id']} загружена с сервера', category: 'SYNC');
    }

    // Загружаем заказы (пропускаем заказы активной смены)
    for (final orderData in orders) {
      if (orderData['shiftId'] == activeShift?.id) {
        continue;
      }
      final orderId = await _db.orderDao.insertOrderFromServer(orderData);
      logMessage('💾 Заказ ${orderData['id']} загружен с сервера', category: 'SYNC');

      final deliveries = orderData['deliveries'] as List;
      for (final deliveryData in deliveries) {
        await _db.deliveryDao.insertDeliveryFromServer(deliveryData, orderId: orderId);
      }
      logMessage('💾 ${deliveries.length} доставок загружено для заказа ${orderData['id']}', category: 'SYNC');
    }

    logMessage('✅ Загружено ${shifts.length} смен и ${orders.length} заказов', category: 'SYNC');
  } catch (e) {
    logMessage('⚠️ Ошибка загрузки данных за сегодня: $e', category: 'SYNC', level: LogLevel.error);
  }
}

  // ===== ОТПРАВКА СПРАВОЧНИКОВ =====

  Future<void> _syncDirectories() async {
    try {
      logMessage('📤 Синхронизация справочников...', category: 'SYNC');

      final settings = await _db.settingsDao.getActiveSettings();
      if (settings != null && !settings.isSynced) {
        final response = await _apiClient.updateSettings({
          'fuelConsumption': settings.fuelConsumption,
          'fuelPrice': settings.fuelPrice,
          'repairCost': settings.repairCost,
          'additionalCosts': settings.additionalCosts,
          'version': settings.version,
        });

        if (response['status'] == 'success') {
          final serverSettings = response['settings'];
          await _db.settingsDao.updateSettings(
            settings.id,
            SettingsTableCompanion(
              version: Value(serverSettings['version']),
              isSynced: const Value(true),
              updatedAt: Value(DateTime.now()),
            ),
          );
          logMessage('✅ Настройки отправлены на сервер', category: 'SYNC');
        } else if (response['status'] == 'conflict') {
          logMessage('⚠️ Конфликт настроек, загружаем серверную версию', category: 'SYNC');
          final serverData = response['server'];
          await _db.settingsDao.updateSettings(
            settings.id,
            SettingsTableCompanion(
              fuelConsumption: Value(serverData['fuelConsumption']),
              fuelPrice: Value(serverData['fuelPrice']),
              repairCost: Value(serverData['repairCost']),
              additionalCosts: Value(serverData['additionalCosts']),
              version: Value(serverData['version']),
              isSynced: const Value(true),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
      }

      final pricing = await _db.pricingDao.getActivePricing();
      if (pricing != null && !pricing.isSynced) {
        final response = await _apiClient.updatePricing({
          'receivingFee': pricing.receivingFee,
          'deliveryFee': pricing.deliveryFee,
          'pricePerKg': pricing.pricePerKg,
          'pricePerKm': pricing.pricePerKm,
          'baseCoefficient': pricing.baseCoefficient,
          'version': pricing.version,
        });

        if (response['status'] == 'success') {
          final serverPricing = response['pricing'];
          await _db.pricingDao.updatePricing(
            pricing.id,
            PricingTableCompanion(
              version: Value(serverPricing['version']),
              isSynced: const Value(true),
              updatedAt: Value(DateTime.now()),
            ),
          );
          logMessage('✅ Тарифы отправлены на сервер', category: 'SYNC');
        }
      }

      final x5Settings = await _db.x5SettingsDao.getActiveX5Settings();
      if (x5Settings != null && !x5Settings.isSynced) {
        final response = await _apiClient.updateX5Settings({
          'pickupPrice': x5Settings.pickupPrice,
          'deliveryPrice': x5Settings.deliveryPrice,
          'perKmPrice': x5Settings.perKmPrice,
          'perKgPrice': x5Settings.perKgPrice,
        });

        if (response['status'] == 'success') {
          await _db.x5SettingsDao.updateX5Settings(
            x5Settings.id,
            X5SettingsTableCompanion(
              isSynced: const Value(true),
              updatedAt: Value(DateTime.now()),
            ),
          );
          logMessage('✅ X5 настройки отправлены на сервер', category: 'SYNC');
        }
      }
    } catch (e) {
      logMessage('❌ Ошибка синхронизации справочников: $e', category: 'SYNC', level: LogLevel.error);
    }
  }

  // ===== СИНХРОНИЗАЦИЯ НАСТРОЕК (ОТПРАВКА) =====

  Future<void> _syncSettings() async {
    logMessage('📤 Синхронизация настроек...', category: 'SYNC');
    try {
      final settings = await _db.settingsDao.getActiveSettings();
      if (settings != null && !settings.isSynced) {
        await _apiClient.syncSettings({
          'fuelConsumption': settings.fuelConsumption,
          'fuelPrice': settings.fuelPrice,
          'repairCost': settings.repairCost,
          'additionalCosts': settings.additionalCosts,
          'version': settings.version,
        });
        await _db.settingsDao.updateSettings(
          settings.id,
          SettingsTableCompanion(
            isSynced: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
        );
        logMessage('✅ Настройки синхронизированы', category: 'SYNC');
      }
    } catch (e) {
      logMessage('❌ Ошибка синхронизации настроек: $e', category: 'SYNC', level: LogLevel.error);
    }
  }

  // ===== СИНХРОНИЗАЦИЯ СМЕН (ОТПРАВКА) =====

  Future<void> _syncShifts() async {
  logMessage('📤 Синхронизация смен...', category: 'SYNC');
  try {
    // 🔥 НЕ ОТПРАВЛЯЕМ АКТИВНУЮ СМЕНУ
    final activeShift = await _db.shiftDao.getActiveShift();
    final activeShiftId = activeShift?.id;
    
    final allShifts = await _db.shiftDao.getAllShifts();
    final unsyncedShifts = allShifts.where((shift) => 
      shift.serverId == null && shift.id != activeShiftId
    ).toList();
    
    if (unsyncedShifts.isEmpty) {
      logMessage('✅ Нет смен для отправки на сервер', category: 'SYNC');
      return;
    }

    logMessage('📊 Найдено ${unsyncedShifts.length} смен для отправки', category: 'SYNC');

    final shiftsData = unsyncedShifts.map((shift) => ({
      'localId': shift.id,
      'startTime': shift.startTime,
      'endTime': shift.endTime,
      'durationSeconds': shift.durationSeconds,
      'totalPaidDistance': shift.totalPaidDistance,
      'totalIdleDistance': shift.totalIdleDistance,
      'ordersCount': shift.ordersCount,
      'totalIncome': shift.totalIncome,
      'totalExpenses': shift.totalExpenses,
      'netProfit': shift.netProfit,
      'status': shift.status,
    })).toList();

    final response = await _apiClient.syncShifts(shiftsData);
    
    for (final result in response['synced']) {
      await _db.shiftDao.markAsSynced(result['localId'], result['serverId']);
      logMessage('✅ Смена ${result['localId']} синхронизирована (serverId=${result['serverId']})', category: 'SYNC');
    }
  } catch (e) {
    logMessage('❌ Ошибка синхронизации смен: $e', category: 'SYNC', level: LogLevel.error);
  }
}

  // ===== СИНХРОНИЗАЦИЯ ЗАКАЗОВ (ОТПРАВКА) =====

  Future<void> _syncOrders() async {
  logMessage('📤 Синхронизация заказов...', category: 'SYNC');
  try {
    // 🔥 ПОЛУЧАЕМ АКТИВНУЮ СМЕНУ
    final activeShift = await _db.shiftDao.getActiveShift();
    final activeShiftId = activeShift?.id;
    
    final allOrders = await _db.orderDao.getAllOrders();
    final unsyncedOrders = allOrders.where((order) => 
      order.serverId == null && order.shiftId != activeShiftId
    ).toList();
    
    if (unsyncedOrders.isEmpty) {
      logMessage('✅ Нет заказов для отправки на сервер', category: 'SYNC');
      return;
    }

    logMessage('📊 Найдено ${unsyncedOrders.length} заказов для отправки', category: 'SYNC');

    final ordersWithDeliveries = <Map<String, dynamic>>[];
    for (final order in unsyncedOrders) {
      final deliveries = await _db.deliveryDao.getDeliveriesByOrder(order.id);
      ordersWithDeliveries.add({
        'localId': order.id,
        'shiftId': order.shiftId,
        'serviceName': order.serviceName,
        'coefficient': order.coefficient,
        'deliveryNumber': order.deliveryNumber,
        'totalPaidDistance': order.totalPaidDistance,
        'totalIncome': order.totalIncome,
        'totalExpenses': order.totalExpenses,
        'netProfit': order.netProfit,
        'totalTimeSeconds': order.totalTimeSeconds,
        'deliveries': deliveries.map((d) => ({
          'localId': d.id,
          'number': d.number,
          'clientAddress': d.clientAddress,
          'apartment': d.apartment,
          'weight': d.weight,
          'timeToShop': d.timeToShop,
          'distanceToShop': d.distanceToShop,
          'timeReceiving': d.timeReceiving,
          'timeToClient': d.timeToClient,
          'distanceToClient': d.distanceToClient,
          'timeDelivery': d.timeDelivery,
        })).toList(),
      });
    }

    if (ordersWithDeliveries.isEmpty) {
      logMessage('✅ Нет новых заказов для отправки', category: 'SYNC');
      return;
    }

    final response = await _apiClient.syncOrders(ordersWithDeliveries);

    for (final result in response['synced']) {
      await _db.orderDao.markAsSynced(result['localId'], result['serverId']);
      logMessage('✅ Заказ ${result['localId']} синхронизирован (serverId=${result['serverId']})', category: 'SYNC');
    }
  } catch (e) {
    logMessage('❌ Ошибка синхронизации заказов: $e', category: 'SYNC', level: LogLevel.error);
  }
}
}