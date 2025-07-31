// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cus_movil/services/auth_service.dart';
import 'package:cus_movil/utils/rfc_test_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cus_movil/widgets/alert_helper.dart';

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

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _testRFCValidation();
      });
    }
  }

  void _testRFCValidation() {
    debugPrint('\n=== INICIO DE PRUEBAS DE VALIDACIÓN ===');

    // Prueba del RFC especial
    const specialRFC = 'ORG1213456789';
    final result = RFCTestHelper.analyzeRFC(specialRFC);
    debugPrint('RFC especial: $specialRFC');
    debugPrint('Válido: ${result['valid']}');
    debugPrint('Es excepción: ${result['isExcepcion']}');
    debugPrint('Tipo: ${result['type']}');

    // Ejecutar pruebas del helper
    RFCTestHelper.testRFCValidation();
  }

  String? _validateEmailCurpOrRfc(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }

    final input = value.trim();
    final inputUpper = input.toUpperCase();

    if (kDebugMode) {
      debugPrint('\n🔍 Validando input: "$input" (${input.length} chars)');
    }

    // Validación de email
    if (input.contains('@')) {
      final emailRegex =
          RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (emailRegex.hasMatch(input)) {
        if (kDebugMode) debugPrint('✅ Email válido detectado');
        return null;
      }
      return 'Formato de email incorrecto';
    }

    // Validación de CURP
    if (inputUpper.length == 18) {
      final curpRegex = RegExp(r'^[A-Z]{4}[0-9]{6}[HM][A-Z]{5}[A-Z0-9][0-9]$');
      if (curpRegex.hasMatch(inputUpper)) {
        if (kDebugMode) debugPrint('✅ CURP válido detectado');
        return null;
      }
      return 'Formato de CURP incorrecto';
    }

    // Validación especial para RFC de excepción (comparación exacta)
    if (inputUpper == 'ORG1213456789') {
      debugPrint('✅ RFC de excepción aceptado exactamente');
      return null;
    }

    // Validación estándar de RFC para otros casos
    if (inputUpper.length >= 9 && inputUpper.length <= 13) {
      final rfcAnalysis = RFCTestHelper.analyzeRFC(inputUpper);

      if (kDebugMode) {
        debugPrint('🔍 Análisis RFC:');
        debugPrint('- Válido: ${rfcAnalysis['valid']}');
        debugPrint('- Excepción: ${rfcAnalysis['isExcepcion']}');
        debugPrint('- Tipo: ${rfcAnalysis['type']}');
      }

      if (rfcAnalysis['valid'] == true) {
        if (kDebugMode) debugPrint('✅ RFC válido detectado');
        return null;
      }

      return 'Formato de RFC incorrecto\n'
          'Ejemplos válidos:\n'
          '- Persona Física: ABCD123456 o ABCD123456EFG\n'
          '- Persona Moral: ABC123456 o ABC123456789\n'
          '- Caso especial exacto: ORG1213456789';
    }

    if (kDebugMode) debugPrint('❌ Formato no reconocido');
    return 'Ingresa un correo, CURP (18 chars) o RFC (9-13 chars) válido';
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    if (value.length < 3) {
      return 'La contraseña debe tener al menos 3 caracteres';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _loginError = null;
    });

    String user = userCtrl.text.trim();
    final pass = passCtrl.text;

    // Convertir a mayúsculas si es CURP/RFC
    if (!user.contains('@')) {
      user = user.toUpperCase();
    }

    debugPrint('🚀 Iniciando proceso de login...');
    debugPrint('🚀 Usuario: "$user" (${user.length} chars)');
    debugPrint('🚀 Password length: ${pass.length}');
    debugPrint('🔐 Tipo de credencial detectado: ${_getCredentialType(user)}');

    try {
      final authService = AuthService(user);
      final result = await authService.login(user, pass);

      if (result == true) {
        debugPrint('✅ Login exitoso, navegando a home');
        if (mounted) {
          AlertHelper.showAlert(
            '¡Bienvenido!',
            type: AlertType.success,
          );

          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        debugPrint('❌ Login falló');
        if (mounted) {
          setState(() {
            _loginError = _getSpecificErrorMessage(user);
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error en login: $e');
      if (mounted) {
        setState(() {
          _loginError =
              'Error de conexión.\nVerifica tu internet e intenta nuevamente.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getCredentialType(String input) {
    if (input.contains('@')) return 'Email';
    if (input.length == 18) return 'CURP';
    if (input == 'ORG1213456789') return 'RFC Excepción';
    if (input.length >= 9 && input.length <= 13) return 'RFC';
    return 'Desconocido';
  }

  String _getSpecificErrorMessage(String user) {
    if (user.contains('@')) {
      return 'Email o contraseña incorrectos.\nVerifica tus credenciales.';
    } else if (user.length == 18) {
      return 'CURP o contraseña incorrectos.\nVerifica tus credenciales.';
    } else if (user == 'ORG1213456789') {
      return 'RFC o contraseña incorrectos.\nVerifica que tu RFC esté registrado en el sistema.';
    } else if (user.length >= 9 && user.length <= 13) {
      return 'RFC o contraseña incorrectos.\nVerifica que tu RFC esté registrado en el sistema.';
    } else {
      return 'Usuario o contraseña incorrectos.\nVerifica tus credenciales e intenta nuevamente.';
    }
  }

  Future<void> _launchPasswordRecovery() async {
    const urlString =
        'https://cus.sanjuandelrio.gob.mx/tramites-sjr/public/forgot-password.html';

    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        AlertHelper.showAlert(
          'No se pudo abrir el enlace. Verifica tu conexión a internet.',
          type: AlertType.error,
        );
      }
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
            _label('Correo, CURP o RFC'),
            TextFormField(
              controller: userCtrl,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.none,
              decoration: _inputDecoration(
                hint: 'ejemplo@correo.com / CURP / RFC',
                prefix: Icons.account_circle_outlined,
              ),
              validator: _validateEmailCurpOrRfc,
              onChanged: (value) {
                // Mostrar información en tiempo real sobre el tipo detectado
                if (kDebugMode && value.length >= 9) {
                  _showCredentialTypeInfo(value);
                }
              },
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
                padding: const EdgeInsets.only(top: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    _loginError!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _launchPasswordRecovery,
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

  void _showCredentialTypeInfo(String value) {
    final cleanValue = value.trim().toUpperCase();
    String type = 'Desconocido';

    if (cleanValue.contains('@')) {
      type = 'Email';
    } else if (cleanValue.length == 18) {
      type = 'CURP';
    } else if (cleanValue == 'ORG1213456789') {
      type = 'RFC (Excepción)';
    } else if (cleanValue.length >= 9 && cleanValue.length <= 13) {
      final analysis = RFCTestHelper.analyzeRFC(cleanValue);
      if (analysis['valid'] == true || analysis['isExcepcion'] == true) {
        type = 'RFC ${analysis['type']}';
        if (analysis['isExcepcion'] == true) {
          type += ' (Excepción)';
        }
      } else {
        type = 'RFC (formato incorrecto)';
      }
    }

    debugPrint('🎯 Tipo detectado: $type para "$cleanValue"');
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.red, width: 2),
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
