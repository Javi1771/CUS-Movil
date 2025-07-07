import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

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

  String get temperatureString => '${temperature.round()}°C';
  
  String get capitalizedDescription {
    return description.split(' ').map((word) => 
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word
    ).join(' ');
  }

  IconData get weatherIcon {
    switch (icon.substring(0, 2)) {
      case '01': return Icons.wb_sunny; // cielo despejado
      case '02': return Icons.wb_cloudy; // pocas nubes
      case '03': return Icons.cloud; // nubes dispersas
      case '04': return Icons.cloud; // nubes rotas
      case '09': return Icons.grain; // lluvia ligera
      case '10': return Icons.grain; // lluvia
      case '11': return Icons.flash_on; // tormenta
      case '13': return Icons.ac_unit; // nieve
      case '50': return Icons.foggy; // niebla
      default: return Icons.wb_sunny;
    }
  }

  Color get weatherColor {
    switch (icon.substring(0, 2)) {
      case '01': return const Color(0xFFFAA21B); // soleado - naranja
      case '02': 
      case '03': 
      case '04': return const Color(0xFF7ECBFB); // nublado - azul claro
      case '09': 
      case '10': return const Color(0xFF00B2E2); // lluvia - azul
      case '11': return const Color(0xFF085184); // tormenta - azul oscuro
      case '13': return const Color(0xFFFFFFFF); // nieve - blanco
      case '50': return const Color(0xFF64748B); // niebla - gris
      default: return const Color(0xFFFAA21B);
    }
  }
}

class WeatherService {
  static const String _apiKey = '54dca76038b89b0a89d195914b665af5'; // API key proporcionada
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  static Future<WeatherData> getCurrentWeather({
    String city = 'San Juan del Río',
    String country = 'MX'
  }) async {
    debugPrint('[WeatherService] ===== SERVICIO DE CLIMA =====');
    debugPrint('[WeatherService] Solicitando clima para $city, $country');
    
    try {
      final url = Uri.parse(
        '$_baseUrl?q=${Uri.encodeComponent(city)}&appid=$_apiKey&units=metric&lang=es'
      );

      debugPrint('[WeatherService] URL: $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 3), // Reduced timeout to prevent blocking
        onTimeout: () => throw Exception('Tiempo de espera agotado'),
      );

      debugPrint('[WeatherService] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[WeatherService] ✅ Datos recibidos');
        return WeatherData.fromJson(data);
      } else if (response.statusCode == 401) {
        debugPrint('[WeatherService] ❌ API key inválida');
        throw Exception('API key inválida');
      } else if (response.statusCode == 404) {
        debugPrint('[WeatherService] ❌ Ciudad no encontrada');
        throw Exception('Ciudad no encontrada');
      } else {
        debugPrint('[WeatherService] ❌ Error del servicio: ${response.statusCode}');
        throw Exception('Error del servicio de clima');
      }
    } catch (e) {
      debugPrint('[WeatherService] ❌ Error: $e');
      debugPrint('[WeatherService] ⚠️ Usando datos mock como respaldo');
      return _getMockWeatherData(city);
    }
  }

  static WeatherData _getMockWeatherData(String city) {
    debugPrint('[WeatherService] ✅ Generando datos mock para $city');
    
    // Generar datos realistas basados en la hora del día
    final now = DateTime.now();
    final hour = now.hour;
    
    double temp;
    String desc;
    String iconCode;
    
    if (hour >= 6 && hour < 12) {
      // Mañana
      temp = 18.0 + (hour - 6) * 2; // 18°C a 30°C
      desc = 'soleado';
      iconCode = '01d';
    } else if (hour >= 12 && hour < 18) {
      // Tarde
      temp = 28.0 + (hour - 12) * 0.5; // 28°C a 31°C
      desc = 'parcialmente nublado';
      iconCode = '02d';
    } else if (hour >= 18 && hour < 22) {
      // Noche temprana
      temp = 25.0 - (hour - 18) * 2; // 25°C a 17°C
      desc = 'despejado';
      iconCode = '01n';
    } else {
      // Noche/Madrugada
      temp = 15.0 + (hour < 6 ? hour : hour - 24) * 0.5; // 15°C a 18°C
      desc = 'noche despejada';
      iconCode = '01n';
    }
    
    final weatherData = WeatherData(
      city: city,
      temperature: temp,
      description: desc,
      icon: iconCode,
      humidity: 60 + (hour % 4) * 5, // 60-75%
      windSpeed: 2.0 + (hour % 3) * 1.5, // 2.0-5.0 km/h
    );
    
    debugPrint('[WeatherService] ✅ Mock data: ${weatherData.temperatureString}, ${weatherData.description}');
    return weatherData;
  }

  static Future<WeatherData> getWeatherByCoordinates({
    required double lat,
    required double lon,
  }) async {
    try {
      debugPrint('[WeatherService] Obteniendo clima por coordenadas: $lat, $lon');
      
      final url = Uri.parse(
        '$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=es'
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Tiempo de espera agotado'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeatherData.fromJson(data);
      } else {
        throw Exception('Error del servicio de clima');
      }
    } catch (e) {
      debugPrint('[WeatherService] Error: $e');
      return _getMockWeatherData('Tu ubicación');
    }
  }
}