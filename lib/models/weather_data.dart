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

    //? Temperatura
    final tempObj = json['temperature'] ?? {};
    final temp = tempObj is Map
        ? (tempObj['degrees'] as num?)?.toDouble() ?? 0.0
        : 0.0;

    //? Humedad
    final humidity = (json['relativeHumidity'] as num?)?.toInt() ?? 0;

    //? Viento
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

    //? Sensación térmica
    final feelsLikeObj = json['feelsLikeTemperature'] ?? {};
    final feelsLike = feelsLikeObj is Map
        ? (feelsLikeObj['degrees'] as num?)?.toDouble()
        : null;

    //? Presión atmosférica
    final pressureObj = json['airPressure'] ?? {};
    final pressure = pressureObj is Map
        ? (pressureObj['meanSeaLevelMillibars'] as num?)?.toDouble()
        : null;

    //? Índice UV
    final uvIndex = (json['uvIndex'] as num?)?.toInt();

    //? Cobertura de nubes
    final cloudCover = (json['cloudCover'] as num?)?.toInt();

    //? Punto de rocío
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

  //* Getters básicos
  String get temperatureString => '${temperature.round()}°C';

  String get capitalizedDescription => description
      .split(' ')
      .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
      .join(' ');

  //? Icono según condición (usa contains para códigos en inglés y español)
  IconData get weatherIcon {
    final c = conditionCode.toUpperCase();

    //? Llovizna ligera
    if (c.contains('DRIZZLE') || c.contains('LLUVIZNA')) {
      return Icons.snowing;
    }

    //? Lluvia normal
    if (c.contains('RAIN') && !c.contains('HEAVY')) {
      return Icons.umbrella_rounded;
    }

    //? Aguaceros fuertes / tormenta de lluvia
    if (c.contains('HEAVY RAIN') || c.contains('TORRENTIAL')) {
      return Icons.beach_access_rounded;
    }

    //? Tormenta eléctrica 
    if (c.contains('THUNDER') || c.contains('STORM')) {
      return Icons.thunderstorm_rounded;
    }

    //? Sol y nieve mezclados
    if (c.contains('SUNNY_SNOW') || (c.contains('SNOW') && c.contains('SUNNY'))) {
      return Icons.sunny_snowing;
    }

    //? Nieve con nubes
    if (c.contains('CLOUDY_SNOW') || (c.contains('SNOW') && c.contains('CLOUD'))) {
      return Icons.cloudy_snowing;
    }

    //? Nieve simple
    if (c.contains('SNOW') || c.contains('BLIZZARD')) {
      return Icons.ac_unit_rounded;
    }

    //? Aguanieve o granizo
    if (c.contains('SLEET') || c.contains('HAIL')) {
      return Icons.grain;
    }

    //? Niebla / calina
    if (c.contains('FOG') || c.contains('MIST') || c.contains('HAZE')) {
      return Icons.foggy;
    }

    //? Parcialmente soleado
    if (c.contains('PARTLY') && c.contains('SUNNY')) {
      return Icons.sunny;
    }

    //? Parcialmente nublado
    if (c.contains('PARTLY') && c.contains('CLOUD')) {
      return Icons.filter_drama;
    }

    //? Nublado
    if (c.contains('CLOUD') || c.contains('OVERCAST')) {
      return Icons.wb_cloudy_rounded;
    }

    //? Crepúsculo (amanecer/atardecer)
    if (c.contains('TWILIGHT') || c.contains('SUNSET') || c.contains('SUNRISE')) {
      return Icons.wb_twilight;
    }

    //? Noche despejada
    if (c.contains('NIGHT') || c.contains('MOON')) {
      return Icons.bedtime;
    }

    //? Despejado / soleado
    if (c.contains('CLEAR') || c.contains('SUNNY')) {
      return Icons.wb_sunny_rounded;
    }

    //! Por defecto
    return Icons.help_outline_rounded;
  }

  //? Color principal según condición
  Color get weatherColor {
    final c = conditionCode.toUpperCase();
    if (c.contains('RAIN') || c.contains('DRIZZLE') || c.contains('LLUV')) {
      return const Color(0xFF00B2E2);
    }
    if (c.contains('THUNDER')) {
      return const Color(0xFF085184);
    }
    if (c.contains('SNOW') || c.contains('NIEVE')) {
      return const Color(0xFFB3E5FC);
    }
    if (c.contains('FOG') || c.contains('HAZE') || c.contains('MIST')) {
      return const Color(0xFF64748B);
    }
    if (c.contains('CLOUD') || c.contains('NUB')) {
      return const Color(0xFF7ECBFB);
    }
    if (c.contains('CLEAR')) {
      return const Color(0xFFFAA21B);
    }
    return const Color(0xFFFAA21B);
  }

  //? Gradiente según la condición
  List<Color> get weatherGradient {
    final c = conditionCode.toUpperCase();
    if (c.contains('RAIN') || c.contains('DRIZZLE') || c.contains('LLUV')) {
      return [const Color(0xFF4DA0B0), const Color(0xFF2C3E50)];
    }
    if (c.contains('THUNDER')) {
      return [const Color(0xFF0F2027), const Color(0xFF203A43)];
    }
    if (c.contains('SNOW') || c.contains('NIEVE')) {
      return [const Color(0xFFE6DADA), const Color(0xFF274046)];
    }
    if (c.contains('FOG') || c.contains('HAZE') || c.contains('MIST')) {
      return [const Color(0xFF606C88), const Color(0xFF3F4C6B)];
    }
    if (c.contains('CLOUD') || c.contains('NUB')) {
      return [const Color(0xFF616161), const Color(0xFF9BC5C3)];
    }
    //! default: despejado
    return [const Color(0xFFFAA21B), const Color.fromARGB(255, 83, 72, 36)];
  }

  //? Getters extendidos
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
