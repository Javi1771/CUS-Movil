import 'package:flutter/material.dart';
import 'package:cus_movil/widgets/alert_helper.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({Key? key}) : super(key: key);

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final idCtrl = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _headerFade, _cardFade, _footerFade;

  static const Color regal50 = Color(0xFFF0F8FF);
  static const Color regal700 = Color(0xFF045EA0);
  static const Color regal900 = Color(0xFF0B3B60);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _headerFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _cardFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
    );
    _footerFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
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
    final re = RegExp(r'^[\w\.\-]+@[a-zA-Z0-9\-]+\.[a-zA-Z]{2,}$');
    return re.hasMatch(v.trim()) ? null : 'Correo inválido';
  }

  String? _validateCurpOrRfc(String? v) {
    if (v == null || v.trim().isEmpty) return 'CURP o RFC es obligatorio';
    final curp =
        RegExp(r'^[A-Z]{4}\d{6}[HM][A-Z]{5}[A-Z0-9]\d$', caseSensitive: false);
    final rfc = RegExp(r'^[A-ZÑ&]{3,4}\d{6}[A-Z0-9]{3}$', caseSensitive: false);
    final input = v.trim().toUpperCase();
    if (curp.hasMatch(input) || rfc.hasMatch(input)) return null;
    return 'CURP o RFC inválido';
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      AlertHelper.showAlert(
        'Solicitud enviada con éxito',
        type: AlertType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: regal50,
      body: Stack(
        children: [
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
          Center(
            child: FadeTransition(
              opacity: _cardFade,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  elevation: 12,
                  margin: EdgeInsets.only(top: size.height * 0.18, bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(27),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              color: regal50,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                    offset: Offset(0, 10)),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: const Icon(Icons.lock_open,
                                size: 48, color: regal900),
                          ),
                          const SizedBox(height: 16),
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
                          TextFormField(
                            controller: idCtrl,
                            decoration: _inputDecoration(
                              hint: 'CURP o RFC',
                              prefix: Icons.perm_identity_outlined,
                            ),
                            validator: _validateCurpOrRfc,
                          ),
                          const SizedBox(height: 36),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: regal900,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32)),
                                elevation: 4,
                              ),
                              child: const Text('Enviar solicitud',
                                  style: TextStyle(fontSize: 16)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                                context, '/auth'),
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
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _footerFade,
              child: const Text(
                '© 2025 Municipio de San Juan del Río',
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
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(fontStyle: FontStyle.italic, color: Colors.black45),
      prefixIcon: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: regal700.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(prefix, color: regal700),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
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
      size.width * 0.5,
      size.height,
      size.width,
      size.height * 0.75,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> old) => false;
}
