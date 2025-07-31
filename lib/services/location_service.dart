import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Cache de permisos y estado del servicio
  LocationPermission? _cachedPermission;
  bool? _cachedServiceEnabled;
  DateTime? _lastPermissionCheck;
  DateTime? _lastServiceCheck;
  
  // Duración del cache (5 minutos)
  static const Duration _cacheTimeout = Duration(minutes: 5);

  /// Inicializa el servicio de ubicación
  Future<bool> initialize() async {
    try {
      // Verificar servicios de ubicación con timeout
      final serviceEnabled = await _isLocationServiceEnabledCached();
      
      if (!serviceEnabled) {
        debugPrint('[LocationService] Servicios de ubicación deshabilitados');
        return false;
      }

      // Verificar permisos con timeout
      final permission = await _checkPermissionCached();
      
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Permisos de ubicación denegados');
        return false;
      }

      debugPrint('[LocationService] Inicialización exitosa');
      return true;
    } catch (e) {
      debugPrint('[LocationService] Error en inicialización: $e');
      return false;
    }
  }

  /// Verifica si los servicios de ubicación están habilitados (con cache)
  Future<bool> _isLocationServiceEnabledCached() async {
    final now = DateTime.now();
    
    // Usar cache si es válido
    if (_cachedServiceEnabled != null && 
        _lastServiceCheck != null &&
        now.difference(_lastServiceCheck!) < _cacheTimeout) {
      return _cachedServiceEnabled!;
    }

    try {
      _cachedServiceEnabled = await Geolocator.isLocationServiceEnabled();
      _lastServiceCheck = now;
      return _cachedServiceEnabled!;
    } catch (e) {
      debugPrint('[LocationService] Error verificando servicios: $e');
      return false;
    }
  }

  /// Verifica permisos de ubicación (con cache)
  Future<LocationPermission> _checkPermissionCached() async {
    final now = DateTime.now();
    
    // Usar cache si es válido
    if (_cachedPermission != null && 
        _lastPermissionCheck != null &&
        now.difference(_lastPermissionCheck!) < _cacheTimeout) {
      return _cachedPermission!;
    }

    try {
      _cachedPermission = await Geolocator.checkPermission();
      _lastPermissionCheck = now;
      return _cachedPermission!;
    } catch (e) {
      debugPrint('[LocationService] Error verificando permisos: $e');
      return LocationPermission.denied;
    }
  }

  /// Solicita permisos de ubicación
  Future<LocationPermission> requestPermission() async {
    try {
      final permission = await Geolocator.requestPermission()
          .timeout(const Duration(seconds: 10));
      
      // Actualizar cache
      _cachedPermission = permission;
      _lastPermissionCheck = DateTime.now();
      
      return permission;
    } catch (e) {
      debugPrint('[LocationService] Error solicitando permisos: $e');
      return LocationPermission.denied;
    }
  }

  /// Obtiene la ubicación actual con fallback
  Future<LatLng?> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.best,
    Duration? timeout,
  }) async {
    try {
      // Verificar servicios y permisos primero
      final serviceEnabled = await _isLocationServiceEnabledCached();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Servicios de ubicación no disponibles');
        return _getDefaultLocation();
      }

      final permission = await _checkPermissionCached();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Permisos insuficientes');
        return _getDefaultLocation();
      }

      // Obtener posición con timeout reducido para evitar ANR
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
      ).timeout(timeout ?? const Duration(seconds: 10));

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('[LocationService] Error obteniendo ubicación, usando fallback: $e');
      return _getDefaultLocation();
    }
  }

  /// Ubicación por defecto (Ciudad de México)
  LatLng _getDefaultLocation() {
    return const LatLng(19.4326, -99.1332);
  }

  /// Verifica si el servicio está listo para usar
  Future<bool> isReady() async {
    try {
      final serviceEnabled = await _isLocationServiceEnabledCached();
      final permission = await _checkPermissionCached();
      
      return serviceEnabled && 
             (permission == LocationPermission.always || 
              permission == LocationPermission.whileInUse);
    } catch (e) {
      debugPrint('[LocationService] Error verificando estado: $e');
      return false;
    }
  }

  /// Limpia el cache
  void clearCache() {
    _cachedPermission = null;
    _cachedServiceEnabled = null;
    _lastPermissionCheck = null;
    _lastServiceCheck = null;
  }

  /// Stream para monitorear cambios en la posición
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.best,
    int distanceFilter = 100,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }
}