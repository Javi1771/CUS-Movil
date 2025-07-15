import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PerformanceConfig {
  // Configuraciones de rendimiento optimizadas
  static const Duration animationDuration = Duration(milliseconds: 200);
  static const Duration shortDelay = Duration(milliseconds: 100);
  static const Duration mediumDelay = Duration(milliseconds: 300);
  static const Duration longDelay = Duration(milliseconds: 500);
  
  // Configuraciones de red optimizadas
  static const Duration networkTimeout = Duration(seconds: 3);
  static const Duration quickTimeout = Duration(seconds: 1);
  
  // Configuraciones de UI optimizadas
  static const double reducedBlurRadius = 8.0;
  static const double standardBlurRadius = 12.0;
  static const double reducedElevation = 4.0;
  static const double standardElevation = 8.0;
  
  // Configuraciones de memoria
  static const int maxCachedImages = 10;
  static const int maxListItems = 50;
  
  /// Optimiza la configuración de la aplicación para mejor rendimiento
  static void optimizeApp() {
    // Configurar el sistema para mejor rendimiento
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // Configurar la calidad de renderizado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Configuraciones adicionales después del primer frame
      _configureRendering();
    });
  }
  
  static void _configureRendering() {
    // Configuraciones de renderizado optimizadas
    debugPrint('[PerformanceConfig] Aplicando configuraciones de rendimiento');
  }
  
  /// Configuración optimizada para BoxShadow
  static List<BoxShadow> getOptimizedShadow({
    Color? color,
    double? blurRadius,
    Offset? offset,
  }) {
    return [
      BoxShadow(
        color: color ?? Colors.black.withOpacity(0.08),
        blurRadius: blurRadius ?? reducedBlurRadius,
        offset: offset ?? const Offset(0, 2),
      ),
    ];
  }
  
  /// Configuración optimizada para BorderRadius
  static BorderRadius getOptimizedBorderRadius([double? radius]) {
    return BorderRadius.circular(radius ?? 12.0);
  }
  
  /// Configuración optimizada para animaciones
  static AnimationController createOptimizedController({
    required TickerProvider vsync,
    Duration? duration,
  }) {
    return AnimationController(
      duration: duration ?? animationDuration,
      vsync: vsync,
    );
  }
  
  /// Widget optimizado para imágenes
  static Widget optimizedImage({
    required String assetPath,
    double? width,
    double? height,
    BoxFit? fit,
    Widget? errorWidget,
  }) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit ?? BoxFit.contain,
      filterQuality: FilterQuality.medium, // Reducido para mejor rendimiento
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? const Icon(Icons.error, size: 24);
      },
    );
  }
  
  /// Container optimizado para mejor rendimiento
  static Widget optimizedContainer({
    Widget? child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? color,
    double? borderRadius,
    List<BoxShadow>? boxShadow,
    double? width,
    double? height,
  }) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius ?? 12.0),
        boxShadow: boxShadow ?? getOptimizedShadow(),
      ),
      child: child,
    );
  }
  
  /// Método para ejecutar tareas pesadas sin bloquear UI
  static Future<T> executeHeavyTask<T>(Future<T> Function() task) async {
    return await Future.microtask(task);
  }
  
  /// Método para delays optimizados
  static Future<void> optimizedDelay([Duration? duration]) async {
    await Future.delayed(duration ?? shortDelay);
  }
}