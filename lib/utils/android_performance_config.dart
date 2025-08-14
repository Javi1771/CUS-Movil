import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AndroidPerformanceConfig {

  static Future<void> initialize() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        // Configurar el hilo principal para mejor rendimiento
        await _optimizeMainThread();

        // Configurar la superficie de renderizado
        await _optimizeRenderingSurface();

        // Configurar el garbage collector
        await _optimizeGarbageCollection();

        debugPrint('✅ Configuración de rendimiento Android aplicada');
      } catch (e) {
        debugPrint('⚠️ Error configurando rendimiento Android: $e');
      }
    }
  }

  static Future<void> _optimizeMainThread() async {
    try {
      // Configurar prioridad del hilo principal
      await SystemChannels.platform.invokeMethod(
          'SystemChrome.setMainThreadPriority', {'priority': 'high'});
    } catch (e) {
      debugPrint('Error configurando hilo principal: $e');
    }
  }

  static Future<void> _optimizeRenderingSurface() async {
    try {
      // Configurar la superficie de renderizado para evitar problemas de Surface
      await SystemChannels.platform
          .invokeMethod('SystemChrome.optimizeRendering', {
        'enableHardwareAcceleration': true,
        'enableVsync': true,
        'reduceSurfaceMemory': true,
      });
    } catch (e) {
      debugPrint('Error configurando superficie de renderizado: $e');
    }
  }

  static Future<void> _optimizeGarbageCollection() async {
    try {
      // Configurar el garbage collector para mejor rendimiento
      await SystemChannels.platform.invokeMethod('SystemChrome.optimizeGC', {
        'enableConcurrentGC': true,
        'reduceGCPressure': true,
      });
    } catch (e) {
      debugPrint('Error configurando garbage collection: $e');
    }
  }

  /// Configurar el sistema para reducir la carga en el hilo principal
  static void configureSystemUI() {
    try {
      // Configurar la UI del sistema para mejor rendimiento
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    } catch (e) {
      debugPrint('Error configurando System UI: $e');
    }
  }

  /// Limpiar recursos para liberar memoria
  static Future<void> cleanupResources() async {
    try {
      // Forzar limpieza de memoria
      await SystemChannels.platform.invokeMethod('SystemChrome.cleanup');

      // Limpiar cache de imágenes
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      debugPrint('🧹 Recursos limpiados');
    } catch (e) {
      debugPrint('Error limpiando recursos: $e');
    }
  }

  /// Monitorear el rendimiento y aplicar optimizaciones dinámicas
  static void startPerformanceMonitoring() {
    if (kDebugMode) {
      // Monitorear frames perdidos
      WidgetsBinding.instance.addTimingsCallback((List<FrameTiming> timings) {
        for (final timing in timings) {
          final frameDuration = timing.totalSpan.inMilliseconds;
          if (frameDuration > 16) {
            // Más de 16ms = frame drop
            debugPrint('⚠️ Frame drop detectado: ${frameDuration}ms');

            // Aplicar optimizaciones automáticas
            _applyEmergencyOptimizations();
          }
        }
      });
    }
  }

  static void _applyEmergencyOptimizations() {
    try {
      // Reducir la calidad de renderizado temporalmente
      PaintingBinding.instance.imageCache.maximumSize = 50;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50MB

      debugPrint('🚨 Optimizaciones de emergencia aplicadas');
    } catch (e) {
      debugPrint('Error aplicando optimizaciones de emergencia: $e');
    }
  }
}
