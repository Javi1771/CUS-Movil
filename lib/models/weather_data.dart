import 'package:flutter/material.dart';

class WeatherData {
  final String city;
  final double temperature;
  final String description;
  final String conditionCode;
  final int humidity;
  final double windSpeed;

  WeatherData({
    required this.city,
    required this.temperature,
    required this.description,
    required this.conditionCode,
    required this.humidity,
    required this.windSpeed,
  });

  factory WeatherData.fromGoogleJson(Map<String, dynamic> json,
      {required String resolvedCity}) {
    final current = json['currentConditions'] ?? {};
    double toDoubleOrZero(dynamic v) => (v as num?)?.toDouble() ?? 0;

    final code = (current['conditionCode'] ?? '').toString();
    final desc =
        (current['conditionDescription'] ?? current['summary'] ?? code).toString();

    return WeatherData(
      city: resolvedCity,
      temperature: toDoubleOrZero(current['temperature']),
      description: desc,
      conditionCode: code,
      humidity: (current['humidity'] as num?)?.toInt() ?? 0,
      windSpeed: toDoubleOrZero(current['windSpeed']),
    );
  }

  String get temperatureString => '${temperature.round()}°C';

  String get capitalizedDescription => description
      .split(' ')
      .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w)
      .join(' ');

  IconData get weatherIcon {
    final c = conditionCode.toUpperCase();
    if (c.contains('CLEAR')) return Icons.wb_sunny;
    if (c.contains('CLOUD')) return Icons.cloud;
    if (c.contains('RAIN') || c.contains('DRIZZLE')) return Icons.grain;
    if (c.contains('THUNDER')) return Icons.flash_on;
    if (c.contains('SNOW') || c.contains('SLEET')) return Icons.ac_unit;
    if (c.contains('FOG') || c.contains('MIST')) return Icons.foggy;
    return Icons.wb_sunny;
  }

  Color get weatherColor {
    final c = conditionCode.toUpperCase();
    if (c.contains('CLEAR')) return const Color(0xFFFAA21B);
    if (c.contains('CLOUD')) return const Color(0xFF7ECBFB);
    if (c.contains('RAIN') || c.contains('DRIZZLE')) return const Color(0xFF00B2E2);
    if (c.contains('THUNDER')) return const Color(0xFF085184);
    if (c.contains('SNOW') || c.contains('SLEET')) return const Color(0xFFFFFFFF);
    if (c.contains('FOG') || c.contains('MIST')) return const Color(0xFF64748B);
    return const Color(0xFFFAA21B);
  }
}
