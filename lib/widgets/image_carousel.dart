import 'dart:async';
import 'package:flutter/material.dart';

/// Carrusel horizontal simple con PageView.
/// - Se mueve automáticamente cada 4 segundos.
/// - Muestra indicadores de página.
class ImageCarousel extends StatefulWidget {
  const ImageCarousel({
    super.key,
    required this.images,
    this.height = 180,
    this.aspectRatio = 16 / 9,
    this.viewportFraction = 0.85,
    this.borderRadius = 12,
    this.autoPlayInterval = const Duration(seconds: 4),
  });

  final List<String> images;
  final double height;
  final double aspectRatio;
  final double viewportFraction;
  final double borderRadius;
  final Duration autoPlayInterval;

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: widget.viewportFraction,
      initialPage: 0,
    );
    _startAutoPlay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    if (widget.images.length <= 1) return;

    _timer = Timer.periodic(widget.autoPlayInterval, (timer) {
      if (mounted && _pageController.hasClients) {
        _currentPage = (_currentPage + 1) % widget.images.length;
        
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopAutoPlay() {
    _timer?.cancel();
  }

  void _resumeAutoPlay() {
    _stopAutoPlay();
    _startAutoPlay();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: const Center(
            child: Text('No hay imágenes disponibles'),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Carrusel principal
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  // Opcional: agregar funcionalidad al tocar la imagen
                  debugPrint('Imagen ${index + 1} tocada');
                },
                onPanStart: (_) => _stopAutoPlay(),
                onPanEnd: (_) => _resumeAutoPlay(),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    child: AspectRatio(
                      aspectRatio: widget.aspectRatio,
                      child: Image.asset(
                        widget.images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Error cargando imagen: ${widget.images[index]}');
                          return Container(
                            color: Colors.grey[300],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Imagen no encontrada',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Indicadores de página (solo si hay más de una imagen)
        if (widget.images.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.images.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? const Color(0xFF0B3B60)
                      : Colors.grey[400],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}