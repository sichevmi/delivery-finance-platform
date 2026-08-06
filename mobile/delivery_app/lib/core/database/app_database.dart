import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:delivery_app/logger.dart';

import 'tables/shifts.dart';
import 'tables/orders.dart';
import 'tables/deliveries.dart';
import 'tables/gps_points.dart';
import 'tables/pricing.dart';
import 'tables/settings.dart';
import 'tables/x5_settings.dart';

import 'dao/shift_dao.dart';
import 'dao/order_dao.dart';
import 'dao/delivery_dao.dart';
import 'dao/gps_point_dao.dart';
import 'dao/pricing_dao.dart';
import 'dao/settings_dao.dart';
import 'dao/x5_settings_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    PricingTable,
    SettingsTable,
    X5SettingsTable,  
    ShiftTable,
    OrderTable,
    DeliveryTable,
    GpsPointTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      logMessage('📁 База данных создана', category: 'DATABASE');
      await _createDefaultData();
    },
    onUpgrade: (m, from, to) async {
      logMessage('🔄 Миграция БД с $from на $to', category: 'DATABASE');
    },
  );

  ShiftDao get shiftDao => ShiftDao(this);
  OrderDao get orderDao => OrderDao(this);
  DeliveryDao get deliveryDao => DeliveryDao(this);
  GpsPointDao get gpsPointDao => GpsPointDao(this);
  PricingDao get pricingDao => PricingDao(this);
  SettingsDao get settingsDao => SettingsDao(this);
  X5SettingsDao get x5SettingsDao => X5SettingsDao(this);

  Future<void> _createDefaultData() async {
    try {
      final pricingCompanion = PricingTableCompanion(
        receivingFee: Value(50.0),
        deliveryFee: Value(100.0),
        pricePerKg: Value(5.0),
        pricePerKm: Value(10.0),
        baseCoefficient: Value(1.0),
        name: Value('Стандартный тариф'),
        isDefault: Value(true),
        isActive: Value(true),
        createdAt: Value(DateTime.now()),
      );
      await pricingDao.insertPricing(pricingCompanion);

      final settingsCompanion = SettingsTableCompanion(
        fuelConsumption: Value(10.0),
        fuelPrice: Value(50.0),
        repairCost: Value(2.0),
        additionalCosts: Value(0.0),
        name: Value('Стандартные настройки'),
        isDefault: Value(true),
        isActive: Value(true),
        createdAt: Value(DateTime.now()),
      );
      await settingsDao.insertSettings(settingsCompanion);

      final x5SettingsCompanion = X5SettingsTableCompanion(
        pickupPrice: const Value(250.0),
        deliveryPrice: const Value(150.0),
        perKmPrice: const Value(25.0),
        perKgPrice: const Value(10.0),
        isDefault: const Value(true),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
      );
      await x5SettingsDao.insertX5Settings(x5SettingsCompanion);

      logMessage('✅ Дефолтные справочники созданы', category: 'DATABASE');
    } catch (e) {
      logMessage('⚠️ Ошибка создания дефолтных справочников: $e', category: 'DATABASE');
      logMessage('⚠️ Ошибка создания дефолтных X5 настроек: $e', category: 'DATABASE');
    }
  }
}

QueryExecutor _openConnection() {
  // Используем in-memory базу для веба
  return driftDatabase(
    name: 'delivery_app.db',
  );
}