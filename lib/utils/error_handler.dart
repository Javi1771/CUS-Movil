import 'package:flutter/foundation.dart';

class ErrorHandler {
  
  /// Maneja errores de forma segura sin crashear la app
  static void handleError(dynamic error, {String? context, StackTrace? stackTrace}) {
    if (kDebugMode) {
      final contextStr = context != null ? ' [$context]' : '';
      debugPrint('❌ Error$contextStr: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  /// Maneja errores de red específicamente
  static void handleNetworkError(dynamic error, {String? operation}) {
    if (kDebugMode) {
      final operationStr = operation != null ? ' en $operation' : '';
      debugPrint('🌐 Error de red$operationStr: $error');
    }
  }

  /// Maneja errores de timeout
  static void handleTimeoutError(dynamic error, {String? operation, Duration? timeout}) {
    if (kDebugMode) {
      final operationStr = operation != null ? ' en $operation' : '';
      final timeoutStr = timeout != null ? ' (${timeout.inSeconds}s)' : '';
      debugPrint('⏰ Timeout$operationStr$timeoutStr: $error');
    }
  }

  /// Maneja errores de parsing/JSON
  static void handleParsingError(dynamic error, {String? data}) {
    if (kDebugMode) {
      debugPrint('📄 Error de parsing: $error');
      if (data != null) {
        debugPrint('Datos que causaron el error: $data');
      }
    }
  }

  /// Verifica si un error es recuperable
  static bool isRecoverableError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Errores de red que pueden ser temporales
    if (errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('socket')) {
      return true;
    }
    
    // Errores HTTP temporales
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504')) {
      return true;
    }
    
    return false;
  }

  /// Obtiene un mensaje de error amigable para el usuario
  static String getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('timeout')) {
      return 'La operación tardó demasiado. Intenta nuevamente.';
    }
    
    if (errorString.contains('connection') || errorString.contains('network')) {
      return 'Problema de conexión. Verifica tu internet.';
    }
    
    if (errorString.contains('404')) {
      return 'Servicio no disponible temporalmente.';
    }
    
    if (errorString.contains('500') || errorString.contains('502') || 
        errorString.contains('503') || errorString.contains('504')) {
      return 'Error del servidor. Intenta más tarde.';
    }
    
    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'Sesión expirada. Inicia sesión nuevamente.';
    }
    
    return 'Ocurrió un error inesperado. Intenta nuevamente.';
  }
}