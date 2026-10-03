import 'package:dio/dio.dart';
import 'package:delivery_app/core/services/api_client.dart';
import 'package:delivery_app/logger.dart';
import 'package:delivery_app/features/analytics/models/analytics_models.dart';
import 'package:delivery_app/features/analytics/models/analytics_enums.dart';

class AnalyticsRepository {
  final ApiClient _apiClient = ApiClient();

  Future<AnalyticsData> getData({
    required int year,
    int? month,
    int? day,
    AnalyticsPeriod period = AnalyticsPeriod.year,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/analytics',
        queryParameters: {
          'year': year,
          if (month != null) 'month': month,
          if (day != null) 'day': day,
          'period': period.name,
        },
      );
      return AnalyticsData.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      logMessage('❌ [ANALYTICS] DioError: ${e.message}',
          category: 'API', level: LogLevel.error);
      rethrow;
    } catch (e) {
      logMessage('❌ [ANALYTICS] Error: $e',
          category: 'API', level: LogLevel.error);
      rethrow;
    }
  }

  Future<OrderDetails> getOrderDetails(int orderId) async {
    try {
      final response = await _apiClient.dio.get('/analytics/order/$orderId');
      return OrderDetails.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      logMessage('❌ [ANALYTICS] DioError (order): ${e.message}',
          category: 'API', level: LogLevel.error);
      rethrow;
    }
  }
}