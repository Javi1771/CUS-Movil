import 'package:flutter/material.dart';

/// Reusable full-screen loading overlay that fades in/out over any child.
/// - Blocks interactions while visible
/// - Semi-transparent dark backdrop
/// - Centers the Carga CUS image
/// - Precaches the image to avoid flicker
class LoadingOverlay extends StatefulWidget {
  /// When true, shows the overlay and blocks interactions.
  final bool isLoading;

  /// The underlying content to display.
  final Widget child;

  /// Optional message below the image.
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> {
  // Confirmed asset path based on pubspec.yaml (assets/ is included) and file found in repo
  static const String _assetPath = 'assets/Carga CUS.jpg';
  late final ImageProvider _imageProvider;

  @override
  void initState() {
    super.initState();
    _imageProvider = const AssetImage(_assetPath);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache to avoid initial flicker when overlay shows
    precacheImage(_imageProvider, context);
  }

  @override
  Widget build(BuildContext context) {
    // Keep layout untouched: just stack overlay above the provided child
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        // Fade the overlay and block interactions only when loading
        AnimatedOpacity(
          opacity: widget.isLoading ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOut,
          child: AbsorbPointer(
            absorbing: widget.isLoading,
            child: Container(
              color: Colors.black.withOpacity(0.30), // 30% as requested (25–35%)
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // High quality rendering for crisp display on all DPIs
                    Image(
                      image: _imageProvider,
                      width: 180,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                    if (widget.message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        widget.message!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
