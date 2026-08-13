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

  bool get isSyncing => _isSyncing;

  // ===== ОСНОВНАЯ СИНХРОНИЗАЦИЯ (ОТПРАВКА) =====

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
    final hasInternet = await _connectivity.hasInternet();
    if (!hasInternet) {
      logMessage('⚠️ Нет интернета, загрузка с сервера невозможна', category: 'SYNC');
      return;
    }

    try {
      logMessage('📥 Загрузка данных с сервера...', category: 'SYNC');
      await _loadTodayData();
      logMessage('✅ Загрузка с сервера завершена', category: 'SYNC');
    } catch (e) {
      logMessage('❌ Ошибка загрузки с сервера: $e', category: 'SYNC', level: LogLevel.error);
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

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      await _db.shiftDao.deleteShiftsForDate(startOfDay, endOfDay);
      await _db.orderDao.deleteOrdersForDate(startOfDay, endOfDay);

      final shifts = response['shifts'] as List;
      for (final shiftData in shifts) {
        await _db.shiftDao.insertShiftFromServer(shiftData);
        logMessage('💾 Смена ${shiftData['id']} загружена с сервера', category: 'SYNC');
      }

      final orders = response['orders'] as List;
      for (final orderData in orders) {
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
      final unsyncedShifts = await _db.shiftDao.getUnsyncedShifts();
      if (unsyncedShifts.isEmpty) {
        logMessage('✅ Нет несинхронизированных смен', category: 'SYNC');
        return;
      }

      logMessage('📊 Найдено ${unsyncedShifts.length} смен', category: 'SYNC');

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
        logMessage('✅ Смена ${result['localId']} синхронизирована', category: 'SYNC');
      }
    } catch (e) {
      logMessage('❌ Ошибка синхронизации смен: $e', category: 'SYNC', level: LogLevel.error);
    }
  }

  // ===== СИНХРОНИЗАЦИЯ ЗАКАЗОВ (ОТПРАВКА) =====

  Future<void> _syncOrders() async {
    logMessage('📤 Синхронизация заказов...', category: 'SYNC');
    try {
      final unsyncedOrders = await _db.orderDao.getUnsyncedOrders();
      if (unsyncedOrders.isEmpty) {
        logMessage('✅ Нет несинхронизированных заказов', category: 'SYNC');
        return;
      }

      logMessage('📊 Найдено ${unsyncedOrders.length} заказов', category: 'SYNC');

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

      final response = await _apiClient.syncOrders(ordersWithDeliveries);
      
      for (final result in response['synced']) {
        await _db.orderDao.markAsSynced(result['localId'], result['serverId']);
        logMessage('✅ Заказ ${result['localId']} синхронизирован', category: 'SYNC');
      }
    } catch (e) {
      logMessage('❌ Ошибка синхронизации заказов: $e', category: 'SYNC', level: LogLevel.error);
    }
  }
}