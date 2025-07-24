import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class PerformanceConfig {
  
  // Configuración de timeouts para evitar ANRs
  static const Duration networkTimeout = Duration(seconds: 10);
  static const Duration locationTimeout = Duration(seconds: 5);
  static const Duration weatherTimeout = Duration(seconds: 8);
  static const Duration tramitesTimeout = Duration(seconds: 15);
  
  // Configuración de delays para operaciones asíncronas
  static const Duration initDelay = Duration(milliseconds: 100);
  static const Duration weatherDelay = Duration(milliseconds: 500);
  static const Duration dataDelay = Duration(milliseconds: 1000);
  
  // Configuración de carrusel
  static const Duration carouselAutoPlayInterval = Duration(seconds: 4);
  static const Duration carouselAnimationDuration = Duration(milliseconds: 800);
  
  // Configuración de imágenes
  static const int maxImageCacheSize = 100;
  static const Duration imageFadeInDuration = Duration(milliseconds: 300);
  
  /// Inicializa configuraciones de rendimiento
  static void initialize() {
    try {
      // Configurar el cache de imágenes
      PaintingBinding.instance.imageCache.maximumSize = maxImageCacheSize;
      
      // Configurar orientación (solo portrait para mejor rendimiento)
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      
      // Configurar el estilo de la barra de estado
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
        ),
      );
      
      if (kDebugMode) {
        debugPrint('🚀 PerformanceConfig inicializado');
        debugPrint('   - Network timeout: ${networkTimeout.inSeconds}s');
        debugPrint('   - Image cache size: $maxImageCacheSize');
        debugPrint('   - Weather timeout: ${weatherTimeout.inSeconds}s');
        debugPrint('   - Location timeout: ${locationTimeout.inSeconds}s');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error inicializando PerformanceConfig: $e');
      }
    }
  }
  
  /// Limpia el cache de imágenes para liberar memoria
  static void clearImageCache() {
    try {
      PaintingBinding.instance.imageCache.clear();
      if (kDebugMode) {
        debugPrint('🧹 Cache de imágenes limpiado');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error limpiando cache de imágenes: $e');
      }
    }
  }
  
  /// Configuración para operaciones de red con timeout
  static Future<T> withTimeout<T>(
    Future<T> future, {
    Duration? timeout,
    String? operation,
  }) async {
    final timeoutDuration = timeout ?? networkTimeout;
    
    try {
      return await future.timeout(timeoutDuration);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⏰ Timeout en operación: ${operation ?? "desconocida"}');
        debugPrint('   - Duración: ${timeoutDuration.inSeconds}s');
        debugPrint('   - Error: $e');
      }
      rethrow;
    }
  }
  
  /// Ejecuta una operación de forma asíncrona con delay
  static Future<void> delayedExecution(
    VoidCallback callback, {
    Duration? delay,
  }) async {
    try {
      await Future.delayed(delay ?? initDelay);
      callback();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error en delayedExecution: $e');
      }
    }
  }
  
  /// Configuración para debugging de rendimiento
  static void logPerformanceWarning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ Performance Warning: $message');
    }
  }
  
  /// Configuración para debugging de memoria
  static void logMemoryUsage(String context) {
    if (kDebugMode) {
      try {
        final imageCache = PaintingBinding.instance.imageCache;
        debugPrint('📊 Memory Usage ($context):');
        debugPrint('   - Image cache size: ${imageCache.currentSize}/${imageCache.maximumSize}');
        debugPrint('   - Image cache bytes: ${imageCache.currentSizeBytes}/${imageCache.maximumSizeBytes}');
      } catch (e) {
        debugPrint('⚠️ Error obteniendo información de memoria: $e');
      }
    }
  }

  /// Optimiza la configuración para dispositivos de gama baja
  static void optimizeForLowEndDevices() {
    try {
      // Reducir cache de imágenes para dispositivos de gama baja
      PaintingBinding.instance.imageCache.maximumSize = 50;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50MB
      
      if (kDebugMode) {
        debugPrint('📱 Optimización para dispositivos de gama baja aplicada');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error en optimizeForLowEndDevices: $e');
      }
    }
  }

  /// Verifica si el dispositivo necesita optimizaciones especiales
  static bool shouldOptimizeForPerformance() {
    // Esta sería una implementación básica
    // En producción se podría verificar RAM, CPU, etc.
    return false;
  }

  /// Configuración de timeouts específicos por operación
  static Duration getTimeoutForOperation(String operation) {
    switch (operation.toLowerCase()) {
      case 'weather':
        return weatherTimeout;
      case 'location':
        return locationTimeout;
      case 'tramites':
        return tramitesTimeout;
      default:
        return networkTimeout;
    }
  }

  /// Configuración de delays específicos por operación
  static Duration getDelayForOperation(String operation) {
    switch (operation.toLowerCase()) {
      case 'init':
        return initDelay;
      case 'weather':
        return weatherDelay;
      case 'data':
        return dataDelay;
      default:
        return initDelay;
    }
  }
}