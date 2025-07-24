import 'dart:async';
import 'package:flutter/material.dart';

class SimpleCarousel extends StatefulWidget {
  final List<String> images;
  final double height;

  const SimpleCarousel({
    super.key,
    required this.images,
    this.height = 160,
  });

  @override
  State<SimpleCarousel> createState() => _SimpleCarouselState();
}

class _SimpleCarouselState extends State<SimpleCarousel> 
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  
  @override
  bool get wantKeepAlive => true;

  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Iniciar auto-play después de que el widget esté construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        _startAutoPlay();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    if (widget.images.length <= 1 || _isDisposed) {
      return;
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_isDisposed || !mounted || !_pageController.hasClients) {
        timer.cancel();
        return;
      }

      _currentPage = (_currentPage + 1) % widget.images.length;
      
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoPlay() {
    _timer?.cancel();
  }

  void _resumeAutoPlay() {
    if (!_isDisposed && mounted) {
      _startAutoPlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (widget.images.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text('No hay imágenes disponibles'),
          ),
        ),
      );
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onPanStart: (_) => _stopAutoPlay(),
          onPanEnd: (_) => _resumeAutoPlay(),
          child: Stack(
            children: [
              // PageView principal
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  if (mounted && !_isDisposed) {
                    setState(() {
                      _currentPage = index;
                    });
                  }
                },
                itemCount: widget.images.length,
                itemBuilder: (context, index) {
                  return _buildImageItem(index);
                },
              ),
              
              // Indicadores de página
              if (widget.images.length > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: _buildPageIndicators(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageItem(int index) {
    return Image.asset(
      widget.images[index],
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child;
        }
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) {
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
                'Imagen no disponible',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageIndicators() {
    return Row(
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
                ? Colors.white
                : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}