// lib/screens/onboarding_screen.dart
// ignore_for_file: library_private_types_in_public_api

import 'dart:math';
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

  // Definimos cuatro páginas
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
                  color: Colors.black12, blurRadius: 12, offset: Offset(0, 6)),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -30,
                left: -30,
                child: Transform.rotate(
                  angle: -pi / 4,
                  child: Container(
                    width: 60,
                    height: 60,
                    color: const Color(0xFF0B3B60),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                right: -30,
                child: Transform.rotate(
                  angle: -pi / 4,
                  child: Container(
                    width: 60,
                    height: 60,
                    color: const Color(0xFF0B3B60),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //* SALTAR
                    Align(
                      alignment: Alignment.topRight,
                      child: TextButton(
                        onPressed: _skip,
                        child: const Text(
                          'Saltar',
                          style: TextStyle(color: Color(0xFF0B3B60)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    //* PAGEVIEW
                    SizedBox(
                      height: 320,
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: _pages.length,
                        onPageChanged: (i) =>
                            setState(() => _currentPage = i),
                        itemBuilder: (_, i) {
                          final page = _pages[i];
                          //* Si es la página de privacidad:
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

                          //* Páginas estándar con imagen
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Card(
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24)),
                                clipBehavior: Clip.antiAlias,
                                child: page.imageAsset != null
                                    ? Image.asset(
                                        page.imageAsset!,
                                        width: 180,
                                        height: 180,
                                        fit: BoxFit.cover,
                                      )
                                    : const SizedBox.shrink(),
                              ),
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
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    //* INDICADORES
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

                    //* BOTÓN SIGUIENTE / LISTO
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
