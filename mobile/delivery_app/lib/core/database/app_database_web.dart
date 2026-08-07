// lib/core/database/app_database_web.dart
// ТОЛЬКО ДЛЯ ВЕБА
import 'package:drift/drift.dart';
import 'package:drift/web.dart' as web;
import 'package:flutter/foundation.dart' show kIsWeb;

// ... импорт таблиц и DAO

part 'app_database.g.dart';

@DriftDatabase(tables: [...])
class AppDatabaseWeb extends _$AppDatabaseWeb {
  // ... реализация для веба
}

QueryExecutor _openConnectionWeb() {
  return web.WebDatabase(
    name: 'delivery_app.db',
    memory: true,
  );
}