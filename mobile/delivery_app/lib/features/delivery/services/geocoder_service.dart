import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocoderService {
  // Зарегистрируйтесь на https://dadata.ru и получите токен
  static const String _apiKey = 'ca259b6a7aaaeb40d39ae05e413abb32a4cec340';
  static const String _secretKey = 'bd57244cd60920ad9ff8290a7d8db0b483bd1cf5';

  static Future<String?> reverseGeocode(
    double lat,
    double lon, {
    void Function(String)? onLog,
  }) async {
    onLog?.call('🌍 Запрос к DaData: lat=$lat, lon=$lon');

    final url = Uri.parse('https://suggestions.dadata.ru/suggestions/api/4_1/rs/geolocate/address');
    final body = jsonEncode({
      "lat": lat,
      "lon": lon,
      "count": 1,
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Token $_apiKey',
          'X-Secret': _secretKey,
        },
        body: body,
      );

      onLog?.call('📡 Ответ DaData: статус ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final suggestions = data['suggestions'];
        if (suggestions != null && suggestions.isNotEmpty) {
          final address = suggestions[0]['value'];
          onLog?.call('✅ Адрес получен: "$address"');
          return address;
        } else {
          onLog?.call('⚠️ Адрес не найден');
          return null;
        }
      } else {
        onLog?.call('❌ HTTP ошибка: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      onLog?.call('❌ Исключение: $e');
      return null;
    }
  }
}