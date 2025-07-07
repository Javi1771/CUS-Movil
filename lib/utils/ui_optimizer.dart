import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class UIOptimizer {
  static final UIOptimizer _instance = UIOptimizer._internal();
  factory UIOptimizer() => _instance;
  UIOptimizer._internal();

  // Control de rebuilds
  final Map<String, DateTime> _lastRebuildTimes = {};
  static const Duration _rebuildThrottle = Duration(milliseconds: 16); // 60 FPS

  // Control de animaciones
  bool _animationsEnabled = true;
  
  // Control de renderizado
  Timer? _frameThrottleTimer;
  bool _isFrameThrottled = false;

  /// Optimiza el renderizado reduciendo la frecuencia de rebuilds
  bool shouldRebuild(String widgetKey) {
    final now = DateTime.now();
    final lastRebuild = _lastRebuildTimes[widgetKey];
    
    if (lastRebuild == null || 
        now.difference(lastRebuild) >= _rebuildThrottle) {
      _lastRebuildTimes[widgetKey] = now;
      return true;
    }
    
    return false;
  }

  /// Optimiza widgets con overflow automático
  Widget optimizeOverflow({
    required Widget child,
    bool enableClipping = true,
    bool enableScrolling = false,
  }) {
    if (enableScrolling) {
      return SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: child,
      );
    }
    
    if (enableClipping) {
      return ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          child: child,
        ),
      );
    }
    
    return child;
  }

  /// Optimiza listas largas con lazy loading
  Widget optimizeListView({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      physics: physics ?? const ClampingScrollPhysics(),
      padding: padding,
      cacheExtent: 200, // Limitar cache para mejorar memoria
      addAutomaticKeepAlives: false, // Reducir memoria
      addRepaintBoundaries: true, // Optimizar repaint
    );
  }

  /// Optimiza imágenes para reducir memoria
  Widget optimizeImage({
    required String assetPath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Widget? errorWidget,
  }) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width?.round(),
      cacheHeight: height?.round(),
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? Container(
          width: width ?? 50,
          height: height ?? 50,
          color: Colors.grey.shade200,
          child: const Icon(Icons.error_outline),
        );
      },
    );
  }

  /// Optimiza animaciones basado en el rendimiento
  Duration getOptimizedAnimationDuration(Duration original) {
    if (!_animationsEnabled) {
      return Duration.zero;
    }
    
    // Reducir duración si el rendimiento es bajo
    final binding = SchedulerBinding.instance;
    if (binding.hasScheduledFrame) {
      return Duration(milliseconds: (original.inMilliseconds * 0.7).round());
    }
    
    return original;
  }

  /// Deshabilita animaciones temporalmente para mejorar rendimiento
  void disableAnimations() {
    _animationsEnabled = false;
    Timer(const Duration(seconds: 2), () {
      _animationsEnabled = true;
    });
  }

  /// Optimiza el renderizado de widgets complejos
  Widget optimizeComplexWidget({
    required Widget child,
    String? cacheKey,
  }) {
    return RepaintBoundary(
      child: child,
    );
  }

  /// Throttle para operaciones de frame
  void throttleFrame(VoidCallback callback) {
    if (_isFrameThrottled) return;
    
    _isFrameThrottled = true;
    _frameThrottleTimer?.cancel();
    
    _frameThrottleTimer = Timer(const Duration(milliseconds: 16), () {
      _isFrameThrottled = false;
      callback();
    });
  }

  /// Optimiza el layout para prevenir overflow
  Widget preventOverflow({
    required Widget child,
    Axis direction = Axis.horizontal,
  }) {
    if (direction == Axis.horizontal) {
      return Flexible(
        child: child,
      );
    } else {
      return Expanded(
        child: SingleChildScrollView(
          child: child,
        ),
      );
    }
  }

  /// Optimiza el rendimiento de setState
  void optimizedSetState(State state, VoidCallback fn) {
    if (state.mounted) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (state.mounted) {
          fn();
        }
      });
    }
  }

  /// Limpia recursos para liberar memoria
  void dispose() {
    _frameThrottleTimer?.cancel();
    _lastRebuildTimes.clear();
  }
}

/// Mixin para optimizar widgets automáticamente
mixin UIOptimizationMixin<T extends StatefulWidget> on State<T> {
  final UIOptimizer _optimizer = UIOptimizer();
  final Map<String, Widget> _widgetCache = {};
  
  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      _optimizer.throttleFrame(() {
        if (mounted) {
          super.setState(fn);
        }
      });
    }
  }

  /// Wrapper optimizado para builds pesados
  Widget optimizedBuild(String key, Widget Function() builder) {
    if (_optimizer.shouldRebuild(key)) {
      final widget = _optimizer.optimizeComplexWidget(
        child: builder(),
        cacheKey: key,
      );
      _widgetCache[key] = widget;
      return widget;
    }
    
    // Retornar widget cached si existe, sino construir uno nuevo
    return _widgetCache[key] ?? builder();
  }

  @override
  void dispose() {
    _widgetCache.clear();
    _optimizer.dispose();
    super.dispose();
  }
}