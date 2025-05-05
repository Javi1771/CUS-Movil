// lib/screens/auth_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  // Paleta Regal Blue
  static const Color regal50  = Color(0xFFF0F8FF);
  static const Color regal700 = Color(0xFF045EA0);
  static const Color regal900 = Color(0xFF0B3B60);

  @override
  Widget build(BuildContext context) {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool obscureText = true;

    return Scaffold(
      backgroundColor: regal50,
      body: Stack(
        children: [
          // ─── Header con logo ampliado ──────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: ClipPath(
              clipper: _BottomWaveClipper(),
              child: Container(
                height: 335,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/fondo.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Logo grande centrado
                      Positioned(
                        top: 15,
                        child: Image.asset(
                          'assets/logo_blanco.png',
                          height: 150,
                        ),
                      ),
                      // Textos
                      const Positioned(
                        top: 170,
                        child: Column(
                          children: [
                            Text(
                              'Bienvenido',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.1,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Inicia sesión con tu cuenta',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ─── Formulario ────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                margin: const EdgeInsets.only(top: 300),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 24, offset: Offset(0, -8)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _label('Correo o CURP'),
                    _pillInput(
                      controller: userCtrl,
                      hint: 'demo@mail.com', // placeholder más evidente
                      prefix: Icons.email_outlined,
                      keyboard: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),

                    _label('Contraseña'),
                    StatefulBuilder(
                      builder: (ctx, setState) {
                        return _pillInput(
                          controller: passCtrl,
                          hint: '••••••••',
                          prefix: Icons.lock_outline,
                          obscure: obscureText,
                          suffix: obscureText ? Icons.visibility_off : Icons.visibility,
                          onObscureToggle: () => setState(() => obscureText = !obscureText),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: regal900,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          elevation: 6,
                        ),
                        child: const Text('Iniciar sesión', style: TextStyle(fontSize: 16)),
                      ),
                    ),

                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {},
                      child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: regal700)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/person-type'),
                      child: const Text.rich(
                        TextSpan(
                          text: '¿No tienes cuenta? ',
                          style: TextStyle(color: regal900),
                          children: [
                            TextSpan(text: 'Regístrate', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ),
      );

  Widget _pillInput({
    required TextEditingController controller,
    required String hint,
    required IconData prefix,
    bool obscure = false,
    IconData? suffix,
    VoidCallback? onObscureToggle,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black45),
        prefixIcon: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: regal700.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(prefix, color: regal700),
        ),
        suffixIcon: suffix == null
            ? null
            : IconButton(
                icon: Icon(suffix, color: regal700),
                onPressed: onObscureToggle,
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: regal700, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: regal900, width: 2),
        ),
      ),
    );
  }
}

/// Clipper para la onda inferior del header
class _BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path()..lineTo(0, size.height - 80);
    p.quadraticBezierTo(
      size.width * 0.25, size.height, 
      size.width * 0.5, size.height - 40,
    );
    p.quadraticBezierTo(
      size.width * 0.75, size.height - 80, 
      size.width, size.height - 40,
    );
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }
  @override
  bool shouldReclip(covariant CustomClipper<Path> _) => false;
}
