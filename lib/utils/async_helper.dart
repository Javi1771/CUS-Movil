import 'dart:async';

/// Función helper para evitar warnings de unawaited futures
void unawaited(Future<void> future) {
  // Intencionalmente no esperamos el future
  // Esto es útil para operaciones fire-and-forget
}

/// Función helper para ejecutar operaciones con timeout
Future<T> withTimeout<T>(
  Future<T> future, {
  required Duration timeout,
  String? operation,
}) async {
  try {
    return await future.timeout(timeout);
  } catch (e) {
    if (operation != null) {}
    rethrow;
  }
}

/// Función helper para ejecutar operaciones de forma segura
Future<T?> safeExecute<T>(
  Future<T> Function() operation, {
  String? operationName,
  T? fallback,
}) async {
  try {
    return await operation();
  } catch (e) {
    if (operationName != null) {
      print('❌ Error en $operationName: $e');
    }
    return fallback;
  }
}
