import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Banderas para evitar llamadas duplicadas
  bool _isInitializing = false;
  bool _isGettingLocation = false;
  bool _isPermissionChecked = false;
  
  // Cache de permisos y estado del servicio
  LocationPermission? _cachedPermission;
  bool? _cachedServiceEnabled;
  DateTime? _lastPermissionCheck;
  DateTime? _lastServiceCheck;
  
  // Duración del cache (5 minutos)
  static const Duration _cacheTimeout = Duration(minutes: 5);
  
  // Completer para evitar múltiples inicializaciones
  Completer<bool>? _initCompleter;

  /// Inicializa el servicio de ubicación de manera optimizada
  Future<bool> initialize() async {
    if (_isInitializing) {
      // Si ya se está inicializando, esperar a que termine
      return _initCompleter?.future ?? false;
    }

    _isInitializing = true;
    _initCompleter = Completer<bool>();

    try {
      // Usar addPostFrameCallback para ejecutar después del render inicial
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final result = await _performInitialization();
          _initCompleter?.complete(result);
        } catch (e) {
          debugPrint('[LocationService] Error en inicialización: $e');
          _initCompleter?.complete(false);
        } finally {
          _isInitializing = false;
        }
      });

      return await _initCompleter!.future;
    } catch (e) {
      debugPrint('[LocationService] Error en initialize: $e');
      _isInitializing = false;
      _initCompleter?.complete(false);
      return false;
    }
  }

  Future<bool> _performInitialization() async {
    try {
      // EMERGENCY FIX: Deshabilitar temporalmente para evitar ANR
      debugPrint('[LocationService] ⚠️ EMERGENCY: Geolocator deshabilitado para evitar ANR');
      debugPrint('[LocationService] ⚠️ Retornando false para usar ubicación por defecto');
      return false;
      
      /* CÓDIGO ORIGINAL COMENTADO PARA EVITAR BLOQUEOS ANR
      // Verificar servicios de ubicación con timeout
      final serviceEnabled = await _isLocationServiceEnabledCached()
          .timeout(const Duration(seconds: 3));
      
      if (!serviceEnabled) {
        debugPrint('[LocationService] Servicios de ubicación deshabilitados');
        return false;
      }

      // Verificar permisos con timeout
      final permission = await _checkPermissionCached()
          .timeout(const Duration(seconds: 3));
      
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Permisos de ubicación denegados');
        return false;
      }

      debugPrint('[LocationService] Inicialización exitosa');
      return true;
      */
    } catch (e) {
      debugPrint('[LocationService] Error en _performInitialization: $e');
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
      _isPermissionChecked = true;
      return _cachedPermission!;
    } catch (e) {
      debugPrint('[LocationService] Error verificando permisos: $e');
      return LocationPermission.denied;
    }
  }

  /// Solicita permisos de ubicación de manera optimizada
  Future<LocationPermission> requestPermission() async {
    try {
      final permission = await Geolocator.requestPermission()
          .timeout(const Duration(seconds: 10));
      
      // Actualizar cache
      _cachedPermission = permission;
      _lastPermissionCheck = DateTime.now();
      _isPermissionChecked = true;
      
      return permission;
    } catch (e) {
      debugPrint('[LocationService] Error solicitando permisos: $e');
      return LocationPermission.denied;
    }
  }

  /// Obtiene la ubicación actual de manera optimizada
  Future<LatLng?> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration? timeout,
  }) async {
    // Evitar llamadas duplicadas
    if (_isGettingLocation) {
      debugPrint('[LocationService] Ya se está obteniendo ubicación, ignorando llamada duplicada');
      return null;
    }

    _isGettingLocation = true;

    try {
      // Verificar servicios y permisos primero
      final serviceEnabled = await _isLocationServiceEnabledCached();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Servicios de ubicación no disponibles');
        return null;
      }

      final permission = await _checkPermissionCached();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Permisos insuficientes');
        return null;
      }

      // Obtener posición con timeout reducido para evitar ANR
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: timeout ?? const Duration(seconds: 8), // Timeout reducido
      ).timeout(const Duration(seconds: 10)); // Timeout adicional

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('[LocationService] Error obteniendo ubicación: $e');
      return null;
    } finally {
      _isGettingLocation = false;
    }
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

  /// Limpia el cache (útil para forzar verificación)
  void clearCache() {
    _cachedPermission = null;
    _cachedServiceEnabled = null;
    _lastPermissionCheck = null;
    _lastServiceCheck = null;
    _isPermissionChecked = false;
  }

  /// Obtiene el estado actual de permisos sin hacer llamadas al sistema
  LocationPermission? getCachedPermission() => _cachedPermission;

  /// Obtiene el estado actual de servicios sin hacer llamadas al sistema
  bool? getCachedServiceEnabled() => _cachedServiceEnabled;

  /// Verifica si los permisos ya fueron verificados
  bool get isPermissionChecked => _isPermissionChecked;

  /// Stream para monitorear cambios en la posición (uso opcional)
  Stream<Position>? _positionStream;
  
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    _positionStream ??= Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        timeLimit: const Duration(seconds: 10),
      ),
    );
    
    return _positionStream!;
  }

  /// Detiene el stream de posición para liberar recursos
  void stopPositionStream() {
    _positionStream = null;
  }
}