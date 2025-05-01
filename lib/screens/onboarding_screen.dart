// lib/screens/onboarding_screen.dart
// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import 'components/privacy_policy_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  //* Definimos cuatro páginas
  final List<_PageData> _pages = [
    const _PageData(
      title: 'Bienvenido a CUS',
      subtitle: 'Genera tu expediente digital en tan solo 5 pasos.',
      imageAsset: 'assets/mejor_sanjuan.png',
    ),
    const _PageData(
      title: 'Único para ti',
      subtitle:
          'Este proceso es por única ocasión y servirá para trámites futuros.',
      imageAsset: 'assets/mejor_sanjuan.png',
    ),
    const _PageData(
      title: 'Seguro y confiable',
      subtitle: 'Tu información se guarda de forma segura.',
      imageAsset: 'assets/mejor_sanjuan.png',
    ),
    const _PageData(
      title: 'Aviso de Privacidad',
      subtitle: 'Consulta nuestro Aviso de Privacidad completo.',
      isPrivacy: true, //* detectamos que es la página de privacidad
    ),
  ];

  void _nextOrFinish() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/person-type');
    }
  }

  void _skip() {
    Navigator.pushReplacementNamed(context, '/person-type');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
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
              //* 🫧 Burbujas internas, sutiles y contenidas dentro de la card
              Positioned(
                top: -20,
                left: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x1A0E385D),
                  ),
                ),
              ),
              Positioned(
                bottom: -25,
                right: -25,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x1A0E385D),
                  ),
                ),
              ),
              Positioned(
                top: 60,
                right: -20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x120E385D), //! 7% opacidad
                  ),
                ),
              ),
              Positioned(
                bottom: 100,
                left: -15,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x0F0E385D), //! 6% opacidad
                  ),
                ),
              ),

              //* 🔄 Contenido principal de la tarjeta
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
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemBuilder: (_, i) {
                          final page = _pages[i];
                          if (page.isPrivacy) {
                            return Column(
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
                                    color: Color(0xFF0B3B60),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  page.subtitle,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const PrivacyPolicyScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Ver Aviso de Privacidad',
                                    style: TextStyle(
                                      color: Color(0xFF0B3B60),
                                      decoration: TextDecoration.underline,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                page.imageAsset!,
                                width: 280,
                                height: 180,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 15),
                              Text(
                                page.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0B3B60),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                page.subtitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
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
                        color: Colors.white,
                      ),
                      label: Text(
                        _currentPage == _pages.length - 1
                            ? 'Listo'
                            : 'Siguiente',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B3B60),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
