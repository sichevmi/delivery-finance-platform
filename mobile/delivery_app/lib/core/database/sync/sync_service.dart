import 'package:delivery_app/core/database/database_provider.dart';
import 'package:delivery_app/core/services/api_client.dart';
import 'package:delivery_app/core/services/connectivity_service.dart';
import 'package:delivery_app/logger.dart';

class SyncService {
  final AppDatabase _db;
  final ApiClient _apiClient;
  final ConnectivityService _connectivity;

  SyncService(this._db, this._apiClient, this._connectivity);

  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

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

  Future<void> _syncOrders() async {
    logMessage('📤 Синхронизация заказов...', category: 'SYNC');
    try {
      final orders = await _db.orderDao.getUnsyncedOrders();
      if (orders.isEmpty) {
        logMessage('✅ Нет несинхронизированных заказов', category: 'SYNC');
        return;
      }

      logMessage('📊 Найдено ${orders.length} заказов', category: 'SYNC');

      final ordersWithDeliveries = <Map<String, dynamic>>[];
      for (final order in orders) {
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