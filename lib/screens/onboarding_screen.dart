// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'dart:math';
import 'package:flutter/material.dart';
import 'components/help_button.dart';
import 'components/privacy_policy_screen.dart';
import 'components/bubble.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  final Random _random = Random();
  late List<BubbleConfig> _bubbles;

  final List<_PageData> _pages = [
    const _PageData(
      title: 'Bienvenido a la Clave Única San Juan del Río',
      subtitle: 'Genera tu expediente digital en tan solo 6 pasos.',
      imageAsset: 'assets/mejor_sanjuan.png',
    ),
    const _PageData(
      title: 'Único para ti',
      subtitle:
          'Este proceso es por única ocasión y servirá para trámites futuros.',
      imageAsset: 'assets/logo_claveunica_sinfondo.png',
    ),
    const _PageData(
      title: 'Seguro y confiable',
      subtitle: 'Tu información se guarda de forma segura.',
      imageAsset: 'assets/logo_sjr.png',
    ),
    const _PageData(
      title: 'Aviso de Privacidad',
      subtitle: 'Consulta nuestro Aviso de Privacidad completo.',
      isPrivacy: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _generateBubbles();
  }

  void _generateBubbles() {
    const alignments = [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ];

    _bubbles = List.generate(4, (i) {
      return BubbleConfig(
        alignment: alignments[i],
        size: 65 + _random.nextDouble() * 10,
        opacity: 0.25 + _random.nextDouble() * 0.15,
      );
    });
  }

  void _nextOrFinish() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  void _skip() {
    Navigator.pushReplacementNamed(context, '/auth');
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 80),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              const Positioned(
                top: 10,
                left: 10,
                child: HelpButton(
                  iconColor: Colors.white,
                  backgroundColor: Color(0xFF0B3B60),
                  supportEmail: 'sistemas@sanjuandelrio.gob.mx',
                  faqUrl: 'https://sanjuandelrio.gob.mx/faqs',
                  emailSubject: 'Soporte CUS',
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: _bubbles.map((b) {
                    return Align(
                      alignment: b.alignment,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 400),
                        builder: (_, value, child) => Transform.scale(
                          scale: value,
                          child: child,
                        ),
                        child: Transform.translate(
                          offset: Offset(
                            b.alignment.x * 30,
                            b.alignment.y * 30,
                          ),
                          child: Bubble(
                            size: b.size,
                            opacity: b.opacity,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: TextButton.icon(
                        onPressed: _skip,
                        icon: Icon(
                          Icons.skip_next,
                          size: 16,
                          color: const Color(0xFF0B3B60).withOpacity(0.7),
                        ),
                        label: Text(
                          'Saltar',
                          style: TextStyle(
                            color: const Color(0xFF0B3B60).withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF0B3B60).withOpacity(0.05),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 320,
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: _pages.length,
                        onPageChanged: (i) {
                          setState(() {
                            _currentPage = i;
                            _generateBubbles();
                          });
                        },
                        itemBuilder: (_, i) {
                          final page = _pages[i];
                          if (page.isPrivacy) {
                            return SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.privacy_tip,
                                      size: 100, color: Color(0xFF0B3B60)),
                                  const SizedBox(height: 24),
                                  Text(
                                    page.title,
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0B3B60)),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    page.subtitle,
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.black54),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const PrivacyPolicyScreen()));
                                    },
                                    child: const Text(
                                      'Ver Aviso de Privacidad',
                                      style: TextStyle(
                                          color: Color(0xFF0B3B60),
                                          decoration: TextDecoration.underline,
                                          fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final imageHeight =
                              screenHeight < 600 ? 120.0 : 180.0;

                          return SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  page.imageAsset!,
                                  width: 280,
                                  height: imageHeight,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  page.title,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0B3B60)),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  page.subtitle,
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.black54),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        final active = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: active ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF0B3B60)
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _nextOrFinish,
                      icon: Icon(
                          _currentPage == _pages.length - 1
                              ? Icons.check
                              : Icons.arrow_forward,
                          color: Colors.white),
                      label: Text(
                          _currentPage == _pages.length - 1
                              ? 'Listo'
                              : 'Siguiente',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B3B60),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageData {
  final String title;
  final String subtitle;
  final String? imageAsset;
  final bool isPrivacy;

  const _PageData({
    required this.title,
    required this.subtitle,
    this.imageAsset,
    this.isPrivacy = false,
  });
}

class BubbleConfig {
  final Alignment alignment;
  final double size;
  final double opacity;

  BubbleConfig({
    required this.alignment,
    required this.size,
    required this.opacity,
  });
}
