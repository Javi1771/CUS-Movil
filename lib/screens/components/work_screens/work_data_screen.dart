// ignore_for_file: deprecated_member_use

import 'package:cus_movil/screens/widgets/navigation_buttons.dart';
import 'package:cus_movil/screens/widgets/steap_header.dart';
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

  final bool _submitted = false;

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
