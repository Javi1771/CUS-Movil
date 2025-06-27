import 'package:flutter/material.dart';
import 'package:cus_movil/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController userCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  bool obscureText = true;
  bool _isLoading = false;
  String? _loginError;

  static const Color regal50 = Color(0xFFF0F8FF);
  static const Color regal700 = Color(0xFF045EA0);
  static const Color regal900 = Color(0xFF0B3B60);

  String? _validateEmailOrCurp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    final input = value.trim().toUpperCase();
    final emailRegex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    final curpRegex = RegExp(r'^[A-Z]{4}\d{6}[HM][A-Z]{5}[A-Z0-9]\d$');
    if (!emailRegex.hasMatch(input) && !curpRegex.hasMatch(input)) {
      return 'Ingresa un correo o CURP válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null; // No se aplica ninguna validación de formato
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _loginError = null;
    });

    final user = userCtrl.text.trim();
    final pass = passCtrl.text;

    try {
      final authService = AuthService(user); // Pass the required argument
      final result = await authService.login(user, pass);

      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Bienvenido!')),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _loginError = 'Usuario o contraseña incorrectos.';
        });
      }
    } catch (e) {
      setState(() {
        _loginError = 'Error de red o servidor: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: regal50,
      body: Stack(
        children: [
          _buildHeader(),
          Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildLoginForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
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
                Positioned(
                  top: 15,
                  child: Image.asset(
                    'assets/logo_blanco.png',
                    height: 150,
                  ),
                ),
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
    );
  }

  Widget _buildLoginForm() {
    return Container(
      margin: const EdgeInsets.only(top: 300),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 24, offset: Offset(0, -8)),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _label('Correo o CURP'),
            TextFormField(
              controller: userCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(
                hint: 'tu@correo.com / CURP',
                prefix: Icons.email_outlined,
              ),
              validator: _validateEmailOrCurp,
            ),
            const SizedBox(height: 24),
            _label('Contraseña'),
            TextFormField(
              controller: passCtrl,
              obscureText: obscureText,
              decoration: _inputDecoration(
                hint: '••••••••',
                prefix: Icons.lock_outline,
                suffix: obscureText ? Icons.visibility_off : Icons.visibility,
                onSuffixTap: () {
                  setState(() => obscureText = !obscureText);
                },
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          _handleLogin();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: regal900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  elevation: 6,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Iniciar sesión',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
            if (_loginError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  _loginError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/password-recovery'),
              child: const Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(color: regal700),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/person-type'),
              child: const Text.rich(
                TextSpan(
                  text: '¿No tienes cuenta? ',
                  style: TextStyle(color: regal900),
                  children: [
                    TextSpan(
                        text: 'Regístrate',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(text,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ),
      );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefix,
    IconData? suffix,
    VoidCallback? onSuffixTap,
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

class _BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path()..lineTo(0, size.height - 80);
    p.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.5,
      size.height - 40,
    );
    p.quadraticBezierTo(
      size.width * 0.75,
      size.height - 80,
      size.width,
      size.height - 40,
    );
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> _) => false;
}
