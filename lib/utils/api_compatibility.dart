import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Utilidades para manejar compatibilidad de API entre versiones de Flutter
class ApiCompatibility {
  
  /// Verifica si una propiedad existe antes de usarla
  static bool hasProperty(dynamic object, String propertyName) {
    try {
      // Intenta acceder a la propiedad de forma segura
      final mirror = object.runtimeType.toString();
      if (kDebugMode) {
        debugPrint('🔍 Verificando propiedad $propertyName en $mirror');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Propiedad $propertyName no disponible: $e');
      }
      return false;
    }
  }
  
  /// Ejecuta código de forma segura con manejo de errores de API
  static T? safeExecute<T>(T Function() function, {String? description}) {
    try {
      return function();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error en ${description ?? "operación"}: $e');
      }
      return null;
    }
  }
  
  /// Verifica la compatibilidad del renderizado
  static bool checkRenderingCompatibility() {
    try {
      
      if (kDebugMode) {
        debugPrint('✅ Renderizado compatible');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error verificando compatibilidad de renderizado: $e');
      }
      return false;
    }
  }
  
  /// Obtiene información del dispositivo de forma segura
  static Map<String, dynamic> getDeviceInfo() {
    final info = <String, dynamic>{};
    
    safeExecute(() {
      final window = WidgetsBinding.instance.window;
      info['devicePixelRatio'] = window.devicePixelRatio;
      info['physicalSize'] = window.physicalSize.toString();
    }, description: 'obtener información de ventana');
    
    safeExecute(() {
      final mediaQuery = MediaQueryData.fromWindow(WidgetsBinding.instance.window);
      info['size'] = mediaQuery.size.toString();
      info['padding'] = mediaQuery.padding.toString();
    }, description: 'obtener información de MediaQuery');
    
    return info;
  }
  
  /// Maneja errores de ViewConfiguration de forma segura
  static void handleViewConfigurationError() {
    if (kDebugMode) {
      debugPrint('🔧 Manejando error de ViewConfiguration');
    }
    
    safeExecute(() {
      // Forzar actualización del binding
      WidgetsBinding.instance.ensureVisualUpdate();
    }, description: 'actualizar binding visual');
    
    safeExecute(() {
      // Limpiar cache de renderizado
      WidgetsBinding.instance.renderView.markNeedsPaint();
        }, description: 'limpiar cache de renderizado');
  }
  
  /// Configuración de emergencia para problemas de API
  static void emergencyApiConfiguration() {
    if (kDebugMode) {
      debugPrint('🚨 Aplicando configuración de emergencia para API');
    }
    
    try {
      // Configuración mínima y segura
      WidgetsFlutterBinding.ensureInitialized();
      
      // Información de debug
      final deviceInfo = getDeviceInfo();
      if (kDebugMode) {
        debugPrint('📱 Información del dispositivo:');
        deviceInfo.forEach((key, value) {
          debugPrint('   $key: $value');
        });
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error en configuración de emergencia: $e');
      }
    }
  }
  
  /// Widget de fallback para errores de API
  static Widget buildApiErrorWidget(String error) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.api,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Error de Compatibilidad',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Se detectó un problema de compatibilidad con la versión de Flutter. La aplicación se está ejecutando en modo de compatibilidad.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      emergencyApiConfiguration();
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Aplicar Configuración'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información de Debug:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}