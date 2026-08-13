import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/core/database/app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Экспортируем для удобства использования в других файлах
export 'app_database.dart';
export 'dao/shift_dao.dart';
export 'dao/order_dao.dart';
export 'dao/delivery_dao.dart';
export 'dao/settings_dao.dart';