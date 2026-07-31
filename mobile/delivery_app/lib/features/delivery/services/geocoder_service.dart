import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocoderService {
  // Замените на свой API-ключ
  static const String _apiKey = '5ca7e701-237d-4fc0-9327-a1cdf7171dcd';

  static Future<String?> reverseGeocode(
    double lat,
    double lon, {
    void Function(String)? onLog,
  }) async {
    onLog?.call('🌍 Запрос геокодера: lat=$lat, lon=$lon');

    final url = Uri.parse(
        'https://geocode-maps.yandex.ru/1.x/'
        '?apikey=$_apiKey'
        '&geocode=$lat,$lon'
        '&kind=house'           // ищем дома, а не страны
        '&lang=ru_RU'           // явный язык
        '&format=json'
        '&sco=latlong'
        '&results=1'
    );

    try {
      final response = await http.get(url);
      onLog?.call('📡 Ответ геокодера: статус ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = response.body;
        // Логируем первые 500 символов ответа
        final preview = body.length > 500 ? body.substring(0, 500) + '...' : body;
        onLog?.call('📄 Сырой ответ (первые 500 символов): $preview');

        final data = jsonDecode(body);
        try {
          final featureMember = data['response']['GeoObjectCollection']['featureMember'];
          if (featureMember == null || featureMember.isEmpty) {
            onLog?.call('⚠️ Нет объектов в ответе (массив пуст)');
            return null;
          }
          final geoObject = featureMember[0]['GeoObject'];
          final address = geoObject['metaDataProperty']['GeocoderMetaData']['text'];
          onLog?.call('✅ Адрес получен: "$address"');
          return address;
        } catch (e) {
          onLog?.call('❌ Ошибка парсинга ответа: $e');
          return null;
        }
      } else {
        onLog?.call('❌ HTTP ошибка: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      onLog?.call('❌ Исключение при запросе: $e');
      return null;
    }
  }
}