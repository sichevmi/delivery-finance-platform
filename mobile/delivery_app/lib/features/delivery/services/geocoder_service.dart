import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocoderService {
  // Замените на свой API-ключ
  static const String _apiKey = '5ca7e701-237d-4fc0-9327-a1cdf7171dcd';

  /// Обратное геокодирование: координаты → адрес
  static Future<String?> reverseGeocode(double lat, double lon) async {
    final url = Uri.parse(
      'https://geocode-maps.yandex.ru/1.x/'
      '?apikey=$_apiKey'
      '&geocode=$lat,$lon'
      '&kind=house'
      '&format=json'
      '&results=1'
    );

    try {
      print('🌍 Запрос геокодера: $lat, $lon');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        try {
          final geoObject = data['response']['GeoObjectCollection']['featureMember'][0]['GeoObject'];
          final address = geoObject['metaDataProperty']['GeocoderMetaData']['text'];
          print('✅ Адрес получен: $address');
          return address;
        } catch (e) {
          print('❌ Ошибка парсинга адреса: $e');
          return null;
        }
      } else {
        print('❌ Ошибка геокодирования: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Ошибка запроса: $e');
      return null;
    }
  }
}