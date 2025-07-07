import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  Timer? _frameMonitorTimer;
  int _frameCount = 0;
  DateTime _lastFrameTime = DateTime.now();
  
  static const int _targetFPS = 60;
  static const Duration _monitorInterval = Duration(seconds: 5);

  void startMonitoring() {
    if (kDebugMode) {
      _frameMonitorTimer = Timer.periodic(_monitorInterval, (_) {
        _checkFrameRate();
      });
      
      SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);
    }
  }

  void stopMonitoring() {
    _frameMonitorTimer?.cancel();
    _frameMonitorTimer = null;
  }

  void _onFrame(Duration timestamp) {
    _frameCount++;
  }

  void _checkFrameRate() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastFrameTime).inMilliseconds;
    
    if (elapsed >= _monitorInterval.inMilliseconds) {
      final fps = (_frameCount * 1000) / elapsed;
      
      if (fps < _targetFPS * 0.8) { // If FPS drops below 80% of target
        debugPrint('⚠️ Performance Warning: FPS dropped to ${fps.toStringAsFixed(1)}');
        _logPerformanceIssue(fps);
      }
      
      _frameCount = 0;
      _lastFrameTime = now;
    }
  }

  void _logPerformanceIssue(double fps) {
    debugPrint('🔍 Performance Analysis:');
    debugPrint('   - Current FPS: ${fps.toStringAsFixed(1)}');
    debugPrint('   - Target FPS: $_targetFPS');
    debugPrint('   - Performance drop: ${((_targetFPS - fps) / _targetFPS * 100).toStringAsFixed(1)}%');
    debugPrint('💡 Suggestions:');
    debugPrint('   - Check for heavy operations on main thread');
    debugPrint('   - Reduce widget rebuilds');
    debugPrint('   - Optimize image loading and caching');
  }

  static void measureOperation(String operationName, Function operation) async {
    if (kDebugMode) {
      final stopwatch = Stopwatch()..start();
      
      try {
        await operation();
      } finally {
        stopwatch.stop();
        final duration = stopwatch.elapsedMilliseconds;
        
        if (duration > 100) { // Log operations taking more than 100ms
          debugPrint('⏱️ Slow Operation: $operationName took ${duration}ms');
        }
      }
    } else {
      await operation();
    }
  }

  static void logMemoryUsage() {
    if (kDebugMode) {
      // This would require additional platform-specific implementation
      debugPrint('📊 Memory monitoring would be implemented here');
    }
  }
}