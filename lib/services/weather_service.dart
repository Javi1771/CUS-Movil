import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';

class WeatherService {
  static String get _key => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  static const _weatherEndpoint =
      'https://weather.googleapis.com/v1/weather:lookup';

  static Future<WeatherData> getByCoords({
    required double lat,
    required double lon,
    String language = 'es',
    String resolvedCity = '',
  }) async {
    final url = Uri.parse(
      '$_weatherEndpoint?location=$lat,$lon'
      '&languageCode=$language&unitSystem=SI&key=$_key',
    );

    final headers = {
      //! Obligatorio el FieldMask
      'X-Goog-FieldMask':
          'currentConditions.temperature,currentConditions.humidity,'
          'currentConditions.windSpeed,currentConditions.conditionCode,'
          'currentConditions.conditionDescription',
    };

    final resp = await http.get(url, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Weather API error: ${resp.statusCode} ${resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return WeatherData.fromGoogleJson(
      data,
      resolvedCity: resolvedCity.isEmpty ? '$lat,$lon' : resolvedCity,
    );
  }
}
