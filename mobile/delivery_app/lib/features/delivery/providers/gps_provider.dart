import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_app/features/delivery/services/gps_service.dart';

final gpsServiceProvider = Provider<GpsService>((ref) {
  return GpsService();
});