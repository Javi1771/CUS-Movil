// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/steap_header.dart';
import '../widgets/navigation_buttons.dart';

class ContactMoralScreen extends StatefulWidget {
  const ContactMoralScreen({super.key});

  @override
  State<ContactMoralScreen> createState() => _ContactMoralScreenState();
}

class _ContactMoralScreenState extends State<ContactMoralScreen> {
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
            pasoActual: 3,
            tituloPaso: 'Contacto Empresarial',
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
                    // Sección Email
                    _sectionHeader(Icons.contact_mail, 'Correo electrónico empresarial'),
                    _sectionCard(children: [
                      TextFormField(
                        controller: _emailCtrl,
                        focusNode: _focusEmail,
                        decoration: _inputDecoration(
                            'Opcional: correo electrónico', Icons.email),
                        validator: _validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_focusEmailVerify),
                      ),
                      const SizedBox(height: 12),
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
                    ]),

                    // Sección Teléfono
                    _sectionHeader(Icons.phone_android, 'Teléfono'),
                    _sectionCard(children: [
                      TextFormField(
                        controller: _phoneCtrl,
                        focusNode: _focusPhone,
                        decoration:
                            _inputDecoration('Requerido: teléfono', Icons.phone),
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
                      ),
                      const SizedBox(height: 12),
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
                    ]),
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
