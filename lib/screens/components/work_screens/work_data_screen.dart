// ignore_for_file: deprecated_member_use

import 'package:cus_movil/screens/widgets/navigation_buttons.dart';
import 'package:cus_movil/screens/widgets/steap_header.dart';
import 'package:cus_movil/utils/curp_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class WorkDataScreen extends StatefulWidget {
  const WorkDataScreen({super.key});

  @override
  State<WorkDataScreen> createState() => _WorkDataScreenState();
}

class _WorkDataScreenState extends State<WorkDataScreen> {
  final _formKey = GlobalKey<FormState>();
  static const govBlue = Color(0xFF0B3B60);

  final _rfcCtrl = TextEditingController();
  final _razonSocialCtrl = TextEditingController();
  final _curpCtrl = TextEditingController();
  final _curpVerifyCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _apellidoPCtrl = TextEditingController();
  final _apellidoMCtrl = TextEditingController();
  final _fechaNacCtrl = TextEditingController();
  final _generoCtrl = TextEditingController();
  final _estadoNacCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  final _focusCurp = FocusNode();
  final _focusCurpVerify = FocusNode();
  final _focusRazonSocial = FocusNode();
  final _focusNombre = FocusNode();
  final _focusApellidoP = FocusNode();
  final _focusApellidoM = FocusNode();
  final _focusPass = FocusNode();
  final _focusConfirmPass = FocusNode();

  final bool _showPass = false;
  final bool _submitted = false;
  final _passwordRegex =
      RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[$&!¡¿?@]).{8,}$');

  @override
  void initState() {
    super.initState();
    for (var c in [
      _rfcCtrl,
      _razonSocialCtrl,
      _curpCtrl,
      _curpVerifyCtrl,
      _nombreCtrl,
      _apellidoPCtrl,
      _apellidoMCtrl,
      _passCtrl,
      _confirmPassCtrl,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (var c in [
      _rfcCtrl,
      _razonSocialCtrl,
      _curpCtrl,
      _curpVerifyCtrl,
      _nombreCtrl,
      _apellidoPCtrl,
      _apellidoMCtrl,
      _fechaNacCtrl,
      _generoCtrl,
      _estadoNacCtrl,
      _passCtrl,
      _confirmPassCtrl,
    ]) {
      c.dispose();
    }
    for (var f in [
      _focusCurp,
      _focusCurpVerify,
      _focusNombre,
      _focusApellidoP,
      _focusApellidoM,
      _focusPass,
      _focusConfirmPass,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  void _onCurpChanged(String v) {
    final curp = v.toUpperCase();
    if (curp.length == 18 && _validateCurp(curp) == null) {
      _fechaNacCtrl.text =
          (obtenerFechaNacimientoDeCurp(curp) ?? '').toUpperCase();
      _generoCtrl.text = (obtenerGeneroDeCurp(curp) ?? '').toUpperCase();
      _estadoNacCtrl.text = (obtenerEstadoDeCurp(curp) ?? '').toUpperCase();
      FocusScope.of(context).requestFocus(_focusCurpVerify);
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (!_passwordRegex.hasMatch(value)) {
      return 'Debe tener ≥8 caracteres, 1 mayúscula, 1 minúscula,\n'
          '1 número y 1 símbolo de \$&!¡¿?@';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma la contraseña';
    }
    if (value != _passCtrl.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  String? _validateCurp(String? v) {
    final curpRegExp = RegExp(
        r'^[A-Z]{4}\d{6}[HM][A-Z]{2}[B-DF-HJ-NP-TV-Z]{3}[A-Z\d]\d$',
        caseSensitive: false);
    if (v == null || v.length != 18) return 'Deben ser 18 caracteres';
    if (!curpRegExp.hasMatch(v)) return 'CURP no válida';
    return null;
  }

  String? _validateVerify(String? v) {
    if (v == null || v.isEmpty) return 'Requerido';
    return v.toUpperCase() != _curpCtrl.text.toUpperCase()
        ? 'No coincide con CURP'
        : null;
  }

  bool get _isFormValid => _formKey.currentState?.validate() == true;

  void _goNext() {
    if (_isFormValid) {
      List<String> datosPersonales = [
        _rfcCtrl.text,
        _razonSocialCtrl.text,
        _curpCtrl.text,
        _curpVerifyCtrl.text,
        _nombreCtrl.text,
        _apellidoPCtrl.text,
        _apellidoMCtrl.text,
        _fechaNacCtrl.text,
        _generoCtrl.text,
        _estadoNacCtrl.text,
        _passCtrl.text,
        _confirmPassCtrl.text,
      ];
      Navigator.pushNamed(context, '/direccion-work',
          arguments: datosPersonales);
    } else {
      setState(() {});
    }
  }

  InputDecoration _inputDecoration(String label, [IconData? icon]) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: govBlue) : null,
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: govBlue, width: 2),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: govBlue),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: govBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      body: Column(
        children: [
          const PasoHeader(
            pasoActual: 2,
            tituloPaso: 'Datos fiscales',
            tituloSiguiente: 'Dirección',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Form(
                key: _formKey,
                autovalidateMode: _submitted
                    ? AutovalidateMode.always
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(Icons.apartment, 'Datos de la empresa'),
                    _sectionCard(children: [
                      TextFormField(
                        controller: _rfcCtrl,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(13),
                          UpperCaseTextFormatter(),
                        ],
                        decoration: _inputDecoration('RFC', Icons.description),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        textInputAction: TextInputAction.next,
                        onChanged: (v) {
                          if (v.length == 13) {
                            FocusScope.of(context)
                                .requestFocus(_focusRazonSocial);
                          }
                        },
                        onFieldSubmitted: (_) => FocusScope.of(context)
                            .requestFocus(_focusRazonSocial),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _razonSocialCtrl,
                        focusNode: _focusRazonSocial,
                        inputFormatters: [UpperCaseTextFormatter()],
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        decoration: _inputDecoration(
                            'Razón Social', Icons.border_color),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_focusCurp),
                      ),
                    ]),
                    // ... (resto del contenido idéntico)
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationButtons(
        enabled: _isFormValid,
        onBack: () => Navigator.pop(context),
        onNext: _goNext,
      ),
    );
  }
}
