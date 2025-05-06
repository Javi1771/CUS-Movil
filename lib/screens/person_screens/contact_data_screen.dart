// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/steap_header.dart';
import '../widgets/navigation_buttons.dart';

class ContactDataScreen extends StatefulWidget {
  const ContactDataScreen({super.key});

  @override
  State<ContactDataScreen> createState() => _ContactDataScreenState();
}

class _ContactDataScreenState extends State<ContactDataScreen> {
  final _formKey = GlobalKey<FormState>();
  static const govBlue = Color(0xFF0B3B60);

  // controllers
  final _emailCtrl = TextEditingController();
  final _emailVerifyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _phoneVerifyCtrl = TextEditingController();

  // focus nodes
  final _focusEmail = FocusNode();
  final _focusEmailVerify = FocusNode();
  final _focusPhone = FocusNode();
  final _focusPhoneVerify = FocusNode();

  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    for (var c in [
      _emailCtrl,
      _emailVerifyCtrl,
      _phoneCtrl,
      _phoneVerifyCtrl,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (var c in [
      _emailCtrl,
      _emailVerifyCtrl,
      _phoneCtrl,
      _phoneVerifyCtrl,
    ]) {
      c.dispose();
    }
    for (var f in [
      _focusEmail,
      _focusEmailVerify,
      _focusPhone,
      _focusPhoneVerify,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return null; // optional
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(v)) return 'Email inválido';
    return null;
  }

  String? _validateEmailVerify(String? v) {
    if (_emailCtrl.text.isEmpty) return null;
    if (v == null || v.isEmpty) return 'Requerido';
    return v.trim() != _emailCtrl.text.trim() ? 'No coincide' : null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.length != 10) return 'Debe tener 10 dígitos';
    return null;
  }

  String? _validatePhoneVerify(String? v) {
    if (v == null || v.isEmpty) return 'Requerido';
    return v != _phoneCtrl.text ? 'No coincide' : null;
  }

  bool get _isFormValid => _formKey.currentState?.validate() == true;

  void _goNext() {
    setState(() => _submitted = true);
    if (_isFormValid) {
      Navigator.pushNamed(context, '/terms-and-conditions');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      body: Column(
        children: [
          const PasoHeader(
            pasoActual: 3,
            tituloPaso: 'Contacto',
            tituloSiguiente: 'Términos y Condiciones',
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
                    // Email (optional)
                    TextFormField(
                      controller: _emailCtrl,
                      focusNode: _focusEmail,
                      decoration: _inputDecoration(
                          'Correo electrónico (opcional)', Icons.email),
                      validator: _validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_focusEmailVerify),
                    ),
                    const SizedBox(height: 12),
                    // Verify Email
                    TextFormField(
                      controller: _emailVerifyCtrl,
                      focusNode: _focusEmailVerify,
                      decoration: _inputDecoration(
                          'Verificar correo', Icons.verified_user),
                      validator: _validateEmailVerify,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_focusPhone),
                    ),
                    const SizedBox(height: 24),
                    // Phone (required)
                    TextFormField(
                      controller: _phoneCtrl,
                      focusNode: _focusPhone,
                      decoration:
                          _inputDecoration('Teléfono', Icons.phone_android),
                      validator: _validatePhone,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      textInputAction: TextInputAction.next,
                      onChanged: (v) {
                        if (v.length == 10) {
                          FocusScope.of(context)
                              .requestFocus(_focusPhoneVerify);
                        }
                      },
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_focusPhoneVerify),
                    ),
                    const SizedBox(height: 12),
                    // Verify Phone
                    TextFormField(
                      controller: _phoneVerifyCtrl,
                      focusNode: _focusPhoneVerify,
                      decoration:
                          _inputDecoration('Verificar teléfono', Icons.check),
                      validator: _validatePhoneVerify,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _goNext(),
                    ),
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
