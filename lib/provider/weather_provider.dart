import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/weather_data.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  WeatherData? weather;
  bool loading = false;
  String? error;

  StreamSubscription<Position>? _posSub;

  Future<void> initAndListen({int distanceFilter = 300}) async {
    await refresh(); //? primer fetch
    _posSub?.cancel();
    _posSub = LocationService()
        .getPositionStream(distanceFilter: distanceFilter)
        .listen(
      (pos) => _fetch(pos.latitude, pos.longitude),
      onError: (e) {
        error = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> refresh() async {
    try {
      final latLng = await LocationService().getCurrentLocation();
      if (latLng == null) {
        error = 'No se pudo obtener ubicación';
        notifyListeners();
        return;
      }
      await _fetch(latLng.latitude, latLng.longitude);
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _fetch(double lat, double lon) async {
    try {
      loading = true;
      notifyListeners();
      weather = await WeatherService.getByCoords(lat: lat, lon: lon);
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }
}
