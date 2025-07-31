import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/weather_data.dart';

class WeatherService {
  static final Logger _logger = Logger();

  static String get _key {
    final key = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    if (key.isEmpty) {
      _logger.w('GOOGLE_MAPS_API_KEY no encontrada en .env');
      throw Exception('API key no configurada');
    }
    return key;
  }

  // Endpoints
  static const _currentEndpoint =
      'https://weather.googleapis.com/v1/currentConditions:lookup';
  static const _forecastEndpoint =
      'https://weather.googleapis.com/v1/forecast/days:lookup';

  /// Obtiene las condiciones actuales en [lat],[lon].
  static Future<WeatherData> getByCoords({
    required double lat,
    required double lon,
    String language = 'es',
    String resolvedCity = '',
  }) async {
    try {
      final uri = Uri.parse(
        '$_currentEndpoint'
        '?key=$_key'
        '&location.latitude=$lat'
        '&location.longitude=$lon'
        '&languageCode=$language'
        '&unitsSystem=METRIC',
      );

      final headers = {
        'X-Goog-FieldMask': [
          'currentTime',
          'timeZone.id',
          'isDaytime',
          'weatherCondition.description.text',
          'weatherCondition.type',
          'temperature.degrees',
          'feelsLikeTemperature.degrees',
          'dewPoint.degrees',
          'relativeHumidity',
          'uvIndex',
          'wind.speed.value',
          'wind.speed.unit',
          'cloudCover',
        ].join(','),
        'Content-Type': 'application/json',
      };

      _logger.d('[WeatherService] GET $uri');
      final resp = await http.get(uri, headers: headers)
        .timeout(const Duration(seconds: 10));

      _logger.d('[WeatherService] status: ${resp.statusCode}');
      _logger.d('[WeatherService] body: ${resp.body}');

      if (resp.statusCode != 200) {
        final error = _parseApiError(resp);
        throw Exception('Error del servidor: $error');
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return WeatherData.fromCurrentConditionsJson(
        data,
        resolvedCity: resolvedCity.isEmpty ? '$lat,$lon' : resolvedCity,
      );
    } catch (e, st) {
      _logger.e('Excepción en getByCoords', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Obtiene el pronóstico diario para [days] días a partir de hoy en [lat],[lon].
  /// Devuelve la lista de mapas JSON de cada día en `forecastDays`.
  static Future<List<dynamic>> getWeeklyForecast({
    required double lat,
    required double lon,
    int days = 7,
    String language = 'es',
  }) async {
    try {
      final uri = Uri.parse(
        '$_forecastEndpoint'
        '?key=$_key'
        '&location.latitude=$lat'
        '&location.longitude=$lon'
        '&days=$days'
        '&languageCode=$language'
        '&unitsSystem=METRIC',
      );

      final headers = {
        'Content-Type': 'application/json',
      };

      _logger.d('[WeatherService] GET Forecast $uri');
      final resp = await http.get(uri, headers: headers)
        .timeout(const Duration(seconds: 10));

      _logger.d('[WeatherService] status: ${resp.statusCode}');
      _logger.d('[WeatherService] body: ${resp.body}');

      if (resp.statusCode != 200) {
        final error = _parseApiError(resp);
        throw Exception('Error al obtener pronóstico: $error');
      }

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      return json['forecastDays'] as List<dynamic>;
    } catch (e, st) {
      _logger.e('Excepción en getWeeklyForecast', error: e, stackTrace: st);
      rethrow;
    }
  }

  static String _parseApiError(http.Response r) {
    try {
      final js = jsonDecode(r.body) as Map<String, dynamic>;
      return js['error']?['message'] ?? r.body;
    } catch (_) {
      return r.body;
    }
  }
}
