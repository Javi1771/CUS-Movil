import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  Timer? _frameMonitorTimer;
  int _frameCount = 0;
  DateTime _lastFrameTime = DateTime.now();
  bool _isMonitoring = false;

  static const int _targetFPS = 60;
  static const Duration _monitorInterval = Duration(seconds: 5);

  void startMonitoring() {
    if (kDebugMode && !_isMonitoring) {
      _isMonitoring = true;
      _lastFrameTime = DateTime.now();
      _frameCount = 0;

      try {
        _frameMonitorTimer = Timer.periodic(_monitorInterval, (_) {
          _checkFrameRate();
        });

        SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);
        debugPrint('🚀 Performance Monitor iniciado');
      } catch (e) {
        debugPrint('⚠️ Error iniciando Performance Monitor: $e');
        _isMonitoring = false;
      }
    }
  }

  void stopMonitoring() {
    if (_isMonitoring) {
      _frameMonitorTimer?.cancel();
      _frameMonitorTimer = null;
      _isMonitoring = false;
      debugPrint('🛑 Performance Monitor detenido');
    }
  }

  void _onFrame(Duration timestamp) {
    if (_isMonitoring) {
      _frameCount++;
    }
  }

  void _checkFrameRate() {
    if (!_isMonitoring) return;

    try {
      final now = DateTime.now();
      final elapsed = now.difference(_lastFrameTime).inMilliseconds;

      if (elapsed >= _monitorInterval.inMilliseconds && elapsed > 0) {
        final fps = (_frameCount * 1000) / elapsed;

        // Solo reportar si el FPS es significativamente bajo
        if (fps < _targetFPS * 0.5) {
          // Si FPS cae por debajo del 50% del objetivo
          _logPerformanceIssue(fps);
        }

        _frameCount = 0;
        _lastFrameTime = now;
      }
    } catch (e) {
      debugPrint('⚠️ Error en _checkFrameRate: $e');
    }
  }

  void _logPerformanceIssue(double fps) {
    if (!kDebugMode) return;

    try {
      debugPrint(
          '! Performance Warning: FPS dropped to ${fps.toStringAsFixed(1)}');
      debugPrint('🔍 Performance Analysis:');
      debugPrint('   - Current FPS: ${fps.toStringAsFixed(1)}');
      debugPrint('   - Target FPS: $_targetFPS');
      debugPrint(
          '   - Performance drop: ${((_targetFPS - fps) / _targetFPS * 100).toStringAsFixed(1)}%');
      debugPrint('💡 Suggestions:');
      debugPrint('   - Check for heavy operations on main thread');
      debugPrint('   - Reduce widget rebuilds');
      debugPrint('   - Optimize image loading and caching');
    } catch (e) {
      debugPrint('⚠️ Error en _logPerformanceIssue: $e');
    }
  }

  static Future<T> measureOperation<T>(
      String operationName, Future<T> Function() operation) async {
    if (kDebugMode) {
      final stopwatch = Stopwatch()..start();

      try {
        final result = await operation();
        stopwatch.stop();
        final duration = stopwatch.elapsedMilliseconds;

        // Solo log operaciones que toman más de 200ms para reducir spam
        if (duration > 200) {
          debugPrint('⏱️ Slow Operation: $operationName took ${duration}ms');
        }

        return result;
      } catch (e) {
        stopwatch.stop();
        debugPrint(
            '❌ Failed Operation: $operationName failed after ${stopwatch.elapsedMilliseconds}ms - $e');
        rethrow;
      }
    } else {
      return await operation();
    }
  }

  static void measureSyncOperation(String operationName, Function operation) {
    if (kDebugMode) {
      final stopwatch = Stopwatch()..start();

      try {
        operation();
        stopwatch.stop();
        final duration = stopwatch.elapsedMilliseconds;

        // Solo log operaciones síncronas que toman más de 50ms
        if (duration > 50) {
          debugPrint(
              '⏱️ Slow Sync Operation: $operationName took ${duration}ms');
        }
      } catch (e) {
        stopwatch.stop();
        debugPrint(
            '❌ Failed Sync Operation: $operationName failed after ${stopwatch.elapsedMilliseconds}ms - $e');
        rethrow;
      }
    } else {
      operation();
    }
  }

  static void logMemoryUsage([String? context]) {
    if (kDebugMode) {
      try {
        // Log básico de memoria disponible
        final contextStr = context != null ? ' ($context)' : '';
        debugPrint('📊 Memory Check$contextStr');

        // En Android/iOS, esto requeriría implementación específica de plataforma
        // Por ahora, solo loggeamos que se está monitoreando
        if (Platform.isAndroid || Platform.isIOS) {
          debugPrint('   - Platform: ${Platform.operatingSystem}');
          debugPrint('   - Memory monitoring available on native platforms');
        }
      } catch (e) {
        debugPrint('⚠️ Error en logMemoryUsage: $e');
      }
    }
  }

  // Método para verificar si el dispositivo está bajo presión de memoria
  static bool isLowMemory() {
    // Esta sería una implementación básica
    // En producción, se podría integrar con plugins específicos de plataforma
    return false;
  }

  // Método para limpiar recursos cuando hay poca memoria
  static void handleLowMemory() {
    if (kDebugMode) {
      debugPrint('🧹 Handling low memory situation');
    }

    try {
      // Limpiar cache de imágenes

      // Forzar garbage collection (solo en debug)
      if (kDebugMode) {
        // En Dart, no hay forma directa de forzar GC, pero podemos sugerir
        debugPrint('🗑️ Suggesting garbage collection');
      }
    } catch (e) {
      debugPrint('⚠️ Error en handleLowMemory: $e');
    }
  }

  // Método para obtener estadísticas básicas
  Map<String, dynamic> getStats() {
    return {
      'isMonitoring': _isMonitoring,
      'targetFPS': _targetFPS,
      'monitorInterval': _monitorInterval.inSeconds,
      'frameCount': _frameCount,
    };
  }
}
