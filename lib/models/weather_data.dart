import 'package:flutter/material.dart';

class WeatherData {
  final String city;
  final double temperature;
  final String description;
  final String conditionCode;
  final int humidity;
  final double windSpeed;
  final double? feelsLike;
  final double? pressure;
  final int? uvIndex;
  final int? cloudCover;
  final double? dewPoint;

  WeatherData({
    required this.city,
    required this.temperature,
    required this.description,
    required this.conditionCode,
    required this.humidity,
    required this.windSpeed,
    this.feelsLike,
    this.pressure,
    this.uvIndex,
    this.cloudCover,
    this.dewPoint,
  });

  factory WeatherData.fromCurrentConditionsJson(
    Map<String, dynamic> json, {
    required String resolvedCity,
  }) {
    final condition = json['weatherCondition'] ?? {};
    final descriptionData = condition['description'] is Map
        ? (condition['description'] as Map<String, dynamic>)['text'] ?? ''
        : '';
    final conditionCode = condition['type']?.toString() ?? '';

    // Temperatura
    final tempObj = json['temperature'] ?? {};
    final temp = tempObj is Map
        ? (tempObj['degrees'] as num?)?.toDouble() ?? 0.0
        : 0.0;

    // Humedad
    final humidity = (json['relativeHumidity'] as num?)?.toInt() ?? 0;

    // Viento
    final windObj = json['wind'] ?? {};
    double windSpeed = 0.0;
    if (windObj is Map) {
      final speedObj = windObj['speed'];
      if (speedObj is Map) {
        windSpeed = (speedObj['value'] as num?)?.toDouble() ?? 0.0;
        final unit = speedObj['unit'] as String?;
        if (unit == 'MPH') {
          windSpeed *= 1.60934;
        } else if (unit == 'METERS_PER_SECOND') {
          windSpeed *= 3.6;
        }
      }
    }

    // Sensación térmica
    final feelsLikeObj = json['feelsLikeTemperature'] ?? {};
    final feelsLike = feelsLikeObj is Map
        ? (feelsLikeObj['degrees'] as num?)?.toDouble()
        : null;

    // Presión atmosférica
    final pressureObj = json['airPressure'] ?? {};
    final pressure = pressureObj is Map
        ? (pressureObj['meanSeaLevelMillibars'] as num?)?.toDouble()
        : null;

    // Índice UV
    final uvIndex = (json['uvIndex'] as num?)?.toInt();

    // Cobertura de nubes
    final cloudCover = (json['cloudCover'] as num?)?.toInt();

    // Punto de rocío
    final dewPointObj = json['dewPoint'] ?? {};
    final dewPoint = dewPointObj is Map
        ? (dewPointObj['degrees'] as num?)?.toDouble()
        : null;

    return WeatherData(
      city: resolvedCity,
      temperature: temp,
      description: descriptionData.toString(),
      conditionCode: conditionCode,
      humidity: humidity,
      windSpeed: windSpeed,
      feelsLike: feelsLike,
      pressure: pressure,
      uvIndex: uvIndex,
      cloudCover: cloudCover,
      dewPoint: dewPoint,
    );
  }

  // Getter básicos
  String get temperatureString => '${temperature.round()}°C';

  String get capitalizedDescription => description
      .split(' ')
      .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
      .join(' ');

  IconData get weatherIcon {
    final c = conditionCode.toUpperCase();
    if (c == 'CLEAR') return Icons.wb_sunny;
    if (c == 'CLOUDY' || c == 'MOSTLY_CLOUDY') return Icons.cloud;
    if (c == 'RAIN' || c == 'SHOWERS' || c == 'DRIZZLE') return Icons.grain;
    if (c == 'THUNDERSTORM') return Icons.flash_on;
    if (c == 'SNOW' || c == 'SNOW_SHOWERS' || c == 'SLEET') {
      return Icons.ac_unit;
    }
    if (c == 'MOSTLY_CLEAR') return Icons.wb_sunny;
    if (c == 'FOG' || c == 'HAZE' || c == 'MIST') return Icons.foggy;
    if (c == 'PARTLY_CLOUDY') return Icons.wb_cloudy;
    return Icons.wb_sunny;
  }

  Color get weatherColor {
    final c = conditionCode.toUpperCase();
    if (c == 'CLEAR') return const Color(0xFFFAA21B);
    if (c == 'CLOUDY' || c == 'MOSTLY_CLOUDY') {
      return const Color(0xFF7ECBFB);
    }
    if (c == 'RAIN' || c == 'SHOWERS' || c == 'DRIZZLE') {
      return const Color(0xFF00B2E2);
    }
    if (c == 'THUNDERSTORM') {
      return const Color(0xFF085184);
    }
    if (c == 'SNOW' || c == 'SNOW_SHOWERS' || c == 'SLEET') {
      return const Color(0xFFFFFFFF);
    }
    if (c == 'FOG' || c == 'HAZE' || c == 'MIST') {
      return const Color(0xFF64748B);
    }
    if (c == 'PARTLY_CLOUDY') {
      return const Color(0xFF90CAF9);
    }
    return const Color(0xFFFAA21B);
  }

  // Gradiente según la condición
  List<Color> get weatherGradient {
    final c = conditionCode.toUpperCase();
    if (c.contains('RAIN')) {
      return [const Color(0xFF4DA0B0), const Color(0xFF2C3E50)];
    } else if (c.contains('CLOUD')) {
      return [const Color(0xFF616161), const Color(0xFF9BC5C3)];
    } else if (c.contains('THUNDER')) {
      return [const Color(0xFF0F2027), const Color(0xFF203A43)];
    } else if (c.contains('SNOW')) {
      return [const Color(0xFFE6DADA), const Color(0xFF274046)];
    } else if (c.contains('FOG')) {
      return [const Color(0xFF606C88), const Color(0xFF3F4C6B)];
    }
    return [const Color.fromARGB(255, 99, 73, 40), const Color(0xFFED8F03)];
  }

  // Getters extendidos
  String get feelsLikeString =>
      feelsLike != null ? '${feelsLike!.round()}°C' : '--';

  String get pressureString =>
      pressure != null ? '${pressure!.round()} hPa' : '--';

  String get uvIndexString {
    if (uvIndex == null) return '--';
    if (uvIndex! >= 6) return '$uvIndex 🌡️';
    if (uvIndex! >= 3) return '$uvIndex ⚠️';
    return '$uvIndex ✅';
  }

  String get cloudCoverString =>
      cloudCover != null ? '$cloudCover%' : '--';

  String get dewPointString =>
      dewPoint != null ? '${dewPoint!.round()}°C' : '--';

  String get windSpeedString => '${windSpeed.round()} km/h';
}
