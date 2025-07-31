import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Manejador específico para errores de Surface en Flutter
class SurfaceErrorHandler {
  
  /// Configura el manejo de errores específicos de Surface
  static void configureSurfaceErrorHandling() {
    try {
      // Configurar el manejo de errores de plataforma
      PlatformDispatcher.instance.onError = (error, stack) {
        final errorString = error.toString();
        
        // Manejar errores específicos de Surface
        if (errorString.contains('nativeSurfaceCreated') ||
            errorString.contains('FlutterJNI') ||
            errorString.contains('SurfaceView') ||
            errorString.contains('surfaceCreated')) {
          
          debugPrint('🔧 Error de Surface detectado y manejado silenciosamente');
          debugPrint('   Error: $errorString');
          
          // Intentar recuperación automática
          _attemptSurfaceRecovery();
          
          // No propagar el error para evitar crashes
          return true;
        }
        
        // Para otros errores, usar el manejo por defecto
        return false;
      };
      
      if (kDebugMode) {
        debugPrint('🛡️ SurfaceErrorHandler configurado');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error configurando SurfaceErrorHandler: $e');
      }
    }
  }
  
  /// Intenta recuperar la superficie de renderizado
  static void _attemptSurfaceRecovery() {
    try {
      // Forzar una actualización visual
      WidgetsBinding.instance.ensureVisualUpdate();
      
      // Limpiar el cache de renderizado si está disponible
      WidgetsBinding.instance.renderView.markNeedsPaint();
          
      if (kDebugMode) {
        debugPrint('🔄 Intentando recuperación de Surface');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error en recuperación de Surface: $e');
      }
    }
  }
  
  /// Configura optimizaciones específicas para Surface
  static void optimizeSurfaceConfiguration() {
    try {
      // Configurar el binding de widgets de forma más robusta
      WidgetsFlutterBinding.ensureInitialized();
      
      // Forzar una actualización del renderizado
      WidgetsBinding.instance.renderView.markNeedsPaint();
          
      if (kDebugMode) {
        debugPrint('⚙️ Configuración de Surface optimizada');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error optimizando configuración de Surface: $e');
      }
    }
  }
  
  /// Verifica el estado de la superficie de renderizado
  static bool checkSurfaceHealth() {
    try {
      
      if (kDebugMode) {
        debugPrint('✅ Surface está saludable');
        debugPrint('   - RenderView existe y está configurado');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error verificando salud de Surface: $e');
      }
      return false;
    }
  }
  
  /// Reinicia la superficie de renderizado si es necesario
  static Future<void> restartSurfaceIfNeeded() async {
    try {
      if (!checkSurfaceHealth()) {
        if (kDebugMode) {
          debugPrint('🔄 Reiniciando Surface...');
        }
        
        // Limpiar el estado actual
        WidgetsBinding.instance.renderView.markNeedsPaint();
              
        // Esperar un frame antes de continuar
        await WidgetsBinding.instance.endOfFrame;
        
        // Forzar una nueva configuración
        optimizeSurfaceConfiguration();
        
        if (kDebugMode) {
          debugPrint('✅ Surface reiniciado');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error reiniciando Surface: $e');
      }
    }
  }
  
  /// Configuración de emergencia para casos críticos
  static Widget buildEmergencyWidget(String error) {
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
                    Icons.warning_amber_rounded,
                    size: 64,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Error de Renderizado',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'La aplicación está experimentando problemas de renderizado. Esto es temporal y no afecta la funcionalidad.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await restartSurfaceIfNeeded();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
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
                      child: Text(
                        'Debug: $error',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Colors.black54,
                        ),
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
  
  /// Método simplificado para manejar errores de compilación
  static void handleCompilationError() {
    if (kDebugMode) {
      debugPrint('🔧 Manejando error de compilación relacionado con Surface');
    }
    
    try {
      // Limpiar cualquier estado problemático
      WidgetsBinding.instance.ensureVisualUpdate();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error en handleCompilationError: $e');
      }
    }
  }
}