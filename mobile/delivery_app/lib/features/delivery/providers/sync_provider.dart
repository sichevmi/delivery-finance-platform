import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/core/database/database_provider.dart';
import 'package:delivery_app/core/database/sync/sync_service.dart';
import 'package:delivery_app/core/services/api_client.dart';
import 'package:delivery_app/core/services/connectivity_service.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final apiClient = ref.watch(apiClientProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  return SyncService(db, apiClient, connectivity);
});

final syncStatusProvider = StateProvider<bool>((ref) => false);

final lastSyncTimeProvider = StateProvider<DateTime?>((ref) => null);