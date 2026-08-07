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
  AppDatabase() : super(_openConnection()) {
    _printDatabasePath();
  }

  void _printDatabasePath() {
    try {
      final path = 'База данных инициализирована (Drift 2.x)';
      logMessage('📁 $path', category: 'DATABASE');
    } catch (e) {
      logMessage('⚠️ Не удалось определить путь к БД: $e', category: 'DATABASE');
    }
  }

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
        receivingFee: const Value(50.0),
        deliveryFee: const Value(100.0),
        pricePerKg: const Value(5.0),
        pricePerKm: const Value(10.0),
        baseCoefficient: const Value(1.0),
        name: const Value('Стандартный тариф'),
        isDefault: const Value(true),
        isActive: const Value(true),
        createdAt: Value(DateTime.now()),
      );
      await pricingDao.insertPricing(pricingCompanion);

      final settingsCompanion = SettingsTableCompanion(
        fuelConsumption: const Value(10.0),
        fuelPrice: const Value(50.0),
        repairCost: const Value(2.0),
        additionalCosts: const Value(0.0),
        name: const Value('Стандартные настройки'),
        isDefault: const Value(true),
        isActive: const Value(true),
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
    }
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'delivery_app.db',
  );
}