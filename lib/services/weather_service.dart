import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherData {
  final String city;
  final double temperature;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;

  WeatherData({
    required this.city,
    required this.temperature,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      city: json['name'] ?? 'Ciudad',
      temperature: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'] ?? '',
      icon: json['weather'][0]['icon'] ?? '01d',
      humidity: json['main']['humidity'] ?? 0,
      windSpeed: (json['wind']['speed'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory WeatherData.fromWeatherstackJson(Map<String, dynamic> json) {
    try {
      final current = json['current'];
      final location = json['location'];

      debugPrint('[WeatherData] Procesando datos de Weatherstack...');
      debugPrint('[WeatherData] Location: ${location.toString()}');
      debugPrint('[WeatherData] Current: ${current.toString()}');

      final cityName = location['name'] ?? location['region'] ?? '';
      final temp = (current['temperature'] as num?)?.toDouble();
      final descriptions = current['weather_descriptions'] as List?;
      final description =
          descriptions?.isNotEmpty == true ? descriptions![0] : '';
      final weatherCode = current['weather_code'];
      final humidity = current['humidity'];
      final windSpeed = (current['wind_speed'] as num?)?.toDouble();

      // Validar que tenemos datos válidos
      if (cityName.isEmpty ||
          temp == null ||
          description.isEmpty ||
          weatherCode == null ||
          humidity == null ||
          windSpeed == null) {
        throw Exception('Datos incompletos de la API de clima');
      }

      debugPrint(
          '[WeatherData] ✅ Datos procesados: $cityName, $temp°C, $description');

      return WeatherData(
        city: cityName,
        temperature: temp,
        description: description,
        icon: _mapWeatherstackIcon(weatherCode),
        humidity: humidity,
        windSpeed: windSpeed,
      );
    } catch (e) {
      debugPrint('[WeatherData] ❌ Error procesando datos: $e');
      rethrow;
    }
  }

  static String _mapWeatherstackIcon(int weatherCode) {
    // Mapeo de códigos de Weatherstack a iconos similares
    switch (weatherCode) {
      case 113:
        return '01d'; // Sunny/Clear
      case 116:
        return '02d'; // Partly cloudy
      case 119:
        return '03d'; // Cloudy
      case 122:
        return '04d'; // Overcast
      case 143:
      case 248:
      case 260:
        return '50d'; // Mist/Fog
      case 176:
      case 263:
      case 266:
      case 293:
      case 296:
        return '09d'; // Light rain
      case 179:
      case 182:
      case 185:
      case 281:
      case 284:
        return '13d'; // Sleet/Snow
      case 200:
      case 386:
      case 389:
      case 392:
      case 395:
        return '11d'; // Thunderstorm
      case 299:
      case 302:
      case 305:
      case 308:
      case 311:
      case 314:
      case 317:
      case 320:
      case 323:
      case 326:
      case 329:
      case 332:
      case 335:
      case 338:
        return '10d'; // Rain
      case 227:
      case 230:
      case 323:
      case 326:
      case 329:
      case 332:
      case 335:
      case 338:
      case 350:
      case 353:
      case 356:
      case 359:
      case 362:
      case 365:
      case 368:
      case 371:
      case 374:
      case 377:
      case 350:
        return '13d'; // Snow
      default:
        return '02d'; // Default to partly cloudy
    }
  }

  String get temperatureString => '${temperature.round()}°C';

  String get capitalizedDescription {
    return description
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word)
        .join(' ');
  }

  IconData get weatherIcon {
    switch (icon.substring(0, 2)) {
      case '01':
        return Icons.wb_sunny; // cielo despejado
      case '02':
        return Icons.wb_cloudy; // pocas nubes
      case '03':
        return Icons.cloud; // nubes dispersas
      case '04':
        return Icons.cloud; // nubes rotas
      case '09':
        return Icons.grain; // lluvia ligera
      case '10':
        return Icons.grain; // lluvia
      case '11':
        return Icons.flash_on; // tormenta
      case '13':
        return Icons.ac_unit; // nieve
      case '50':
        return Icons.foggy; // niebla
      default:
        return Icons.wb_sunny;
    }
  }

  Color get weatherColor {
    switch (icon.substring(0, 2)) {
      case '01':
        return const Color(0xFFFAA21B); // soleado - naranja
      case '02':
      case '03':
      case '04':
        return const Color(0xFF7ECBFB); // nublado - azul claro
      case '09':
      case '10':
        return const Color(0xFF00B2E2); // lluvia - azul
      case '11':
        return const Color(0xFF085184); // tormenta - azul oscuro
      case '13':
        return const Color(0xFFFFFFFF); // nieve - blanco
      case '50':
        return const Color(0xFF64748B); // niebla - gris
      default:
        return const Color(0xFFFAA21B);
    }
  }
}

class WeatherService {
  static String get _apiKey =>
      dotenv.env['WEATHERSTACK_API_KEY'] ?? 'fa165b81a553b754e796de95390dafe6';
  static const String _baseUrl = 'https://api.weatherstack.com/current';

  static Future<WeatherData> getCurrentWeather(
      {String city = 'San Juan del Río', String country = 'MX'}) async {
    debugPrint('[WeatherService] ===== SERVICIO DE CLIMA WEATHERSTACK =====');
    debugPrint('[WeatherService] Solicitando clima para $city, $country');
    debugPrint('[WeatherService] API Key: ${_apiKey.substring(0, 8)}...');

    try {
      final query = country.isNotEmpty ? '$city, $country' : city;
      final url = Uri.parse(
          '$_baseUrl?access_key=$_apiKey&query=${Uri.encodeComponent(query)}&units=m');

      debugPrint('[WeatherService] URL completa: $url');

      final response = await http.get(url).timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw Exception('Tiempo de espera agotado'),
          );

      debugPrint('[WeatherService] Status Code: ${response.statusCode}');
      debugPrint('[WeatherService] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['error'] != null) {
          debugPrint('[WeatherService] ❌ Error de API: ${data['error']}');
          throw Exception(
              'Error de API: ${data['error']['info'] ?? 'Error desconocido'}');
        }

        if (data['current'] == null || data['location'] == null) {
          debugPrint('[WeatherService] ❌ Datos incompletos en la respuesta');
          throw Exception('Datos incompletos en la respuesta de la API');
        }

        debugPrint('[WeatherService] ✅ Datos válidos recibidos');
        return WeatherData.fromWeatherstackJson(data);
      } else {
        debugPrint(
            '[WeatherService] ❌ Error HTTP: ${response.statusCode} - ${response.body}');
        throw Exception('Error del servicio de clima: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[WeatherService] ❌ Error completo: $e');
      rethrow; // Propagar el error en lugar de usar datos mock
    }
  }

  static Future<WeatherData> getWeatherByCoordinates({
    required double lat,
    required double lon,
  }) async {
    try {
      debugPrint(
          '[WeatherService] Obteniendo clima por coordenadas: $lat, $lon');

      final query = '$lat,$lon';
      final url = Uri.parse(
          '$_baseUrl?access_key=$_apiKey&query=${Uri.encodeComponent(query)}&units=m');

      debugPrint('[WeatherService] URL coordenadas: $url');

      final response = await http.get(url).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Tiempo de espera agotado'),
          );

      debugPrint('[WeatherService] Status coordenadas: ${response.statusCode}');
      debugPrint('[WeatherService] Response coordenadas: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['error'] != null) {
          debugPrint(
              '[WeatherService] ❌ Error API coordenadas: ${data['error']}');
          throw Exception(
              'Error de API: ${data['error']['info'] ?? 'Error desconocido'}');
        }

        return WeatherData.fromWeatherstackJson(data);
      } else {
        throw Exception('Error del servicio de clima: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[WeatherService] ❌ Error coordenadas: $e');
      rethrow; // Propagar el error en lugar de usar datos mock
    }
  }
}
