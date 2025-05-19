// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, use_super_parameters

import 'package:flutter/material.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({Key? key}) : super(key: key);

  @override
  _PasswordRecoveryScreenState createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final idCtrl = TextEditingController();
  bool obscureId = true;

  late AnimationController _animController;
  late Animation<double> _headerFade, _cardFade, _footerFade;

  //? Paleta “Regal Blue”
  static const Color regal50  = Color(0xFFF0F8FF);
  static const Color regal700 = Color(0xFF045EA0);
  static const Color regal900 = Color(0xFF0B3B60);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _headerFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _cardFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
    );
    _footerFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.9, 1.0, curve: Curves.easeIn),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    emailCtrl.dispose();
    idCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'El correo es obligatorio';
    final re = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    return re.hasMatch(v.trim()) ? null : 'Correo inválido';
  }

  String? _validateCurpOrRfc(String? v) {
    if (v == null || v.trim().isEmpty) return 'CURP o RFC es obligatorio';
    final curp = RegExp(r'^[A-Z]{4}\d{6}[HM][A-Z]{5}[A-Z0-9]\d$');
    final rfc  = RegExp(r'^[A-ZÑ&]{3,4}\d{6}[A-Z0-9]{3}$');
    final input = v.trim().toUpperCase();
    if (curp.hasMatch(input) || rfc.hasMatch(input)) return null;
    return 'CURP/RFC inválido';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: regal50,
      body: Stack(
        children: [
          //? Fondo degradado
          AnimatedContainer(
            duration: const Duration(seconds: 5),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF0F8FF), Color(0xFFE0E8F5)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          //? Header animado
          FadeTransition(
            opacity: _headerFade,
            child: ClipPath(
              clipper: _HeaderClipper(),
              child: Container(
                height: size.height * 0.3,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/fondo.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),

          //? Tarjeta de formulario
          Center(
            child: FadeTransition(
              opacity: _cardFade,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 16,
                  margin: EdgeInsets.only(top: size.height * 0.18, bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(27),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          //? Icono de candado
                          Container(
                            decoration: const BoxDecoration(
                              color: regal50,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0,4)),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: const Icon(Icons.lock_open, size: 48, color: regal900),
                          ),
                          const SizedBox(height: 16),

                          //? Título y subtítulo
                          const Text(
                            'Recuperar Contraseña',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: regal900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ingresa tu correo y tu CURP o RFC',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: regal700.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 32),

                          //? Campo de correo
                          TextFormField(
                            controller: emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration(
                              hint: 'tu@correo.com',
                              prefix: Icons.email_outlined,
                            ),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 24),

                          //? Campo de CURP/RFC
                          TextFormField(
                            controller: idCtrl,
                            obscureText: obscureId,
                            decoration: _inputDecoration(
                              hint: 'CURP o RFC',
                              prefix: Icons.perm_identity_outlined,
                              suffix: obscureId ? Icons.visibility_off : Icons.visibility,
                              onSuffixTap: () => setState(() => obscureId = !obscureId),
                            ),
                            validator: _validateCurpOrRfc,
                          ),
                          const SizedBox(height: 36),

                          //? Botón de envío
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Solicitud enviada'),
                                      backgroundColor: regal700,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: regal900,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                                elevation: 6,
                              ),
                              child: const Text('Enviar solicitud', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/auth'),
                            child: const Text(
                              '¿Ya tienes cuenta? Iniciar sesión',
                              style: TextStyle(color: regal700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          //? Pie de página
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _footerFade,
              child: const Text(
                '© 2025 Gobierno de San Juan del Río',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefix,
    IconData? suffix,
    VoidCallback? onSuffixTap,
  }) {
    return InputDecoration(
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
              onPressed: onSuffixTap,
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
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height * 0.75);
    path.quadraticBezierTo(
      size.width * 0.5, size.height,
      size.width, size.height * 0.75,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> old) => false;
}
