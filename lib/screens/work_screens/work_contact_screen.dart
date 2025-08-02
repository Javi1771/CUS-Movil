// ignore_for_file: deprecated_member_use

import '../../widgets/navigation_buttons.dart';
import '../../widgets/steap_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContactWorkScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool modoPerfil;

  const ContactWorkScreen({
    super.key,
    this.userData = const {}, // 👈 valor por defecto
    this.modoPerfil = false, // 👈 valor por defecto
  });

  @override
  State<ContactWorkScreen> createState() => _ContactWorkScreenState();
}

class _ContactWorkScreenState extends State<ContactWorkScreen> {
  final _formKey = GlobalKey<FormState>();
  static const govBlue = Color(0xFF0B3B60);

  final _emailCtrl = TextEditingController();
  final _emailVerifyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _phoneVerifyCtrl = TextEditingController();
  final _smsCodeCtrl = TextEditingController();

  final _focusEmail = FocusNode();
  final _focusEmailVerify = FocusNode();
  final _focusPhone = FocusNode();
  final _focusPhoneVerify = FocusNode();
  final _focusSmsCode = FocusNode();

  bool _submitted = false;
  bool _isPhoneVerified = false;
  bool _codeSent = false;

  @override
  void initState() {
    super.initState();
    for (var c in [
      _emailCtrl,
      _emailVerifyCtrl,
      _phoneCtrl,
      _phoneVerifyCtrl,
      _smsCodeCtrl,
    ]) {
      c.addListener(() {
        setState(() {
          _isPhoneVerified =
              _phoneCtrl.text.length == 10 &&
              _phoneVerifyCtrl.text == _phoneCtrl.text;
          if (!_isPhoneVerified) _codeSent = false;
        });
      });
    }
  }

  @override
  void dispose() {
    for (var c in [
      _emailCtrl,
      _emailVerifyCtrl,
      _phoneCtrl,
      _phoneVerifyCtrl,
      _smsCodeCtrl,
    ]) {
      c.dispose();
    }
    for (var f in [
      _focusEmail,
      _focusEmailVerify,
      _focusPhone,
      _focusPhoneVerify,
      _focusSmsCode,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return null;
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

  String? _validateSmsCode(String? v) {
    if (!_codeSent) return null;
    if (v == null || v.isEmpty) return 'Requerido';
    return null;
  }

  bool get _isFormValid {
    final baseValid = _formKey.currentState?.validate() == true;
    if (!_isPhoneVerified) return baseValid;
    if (_codeSent) return baseValid && _smsCodeCtrl.text.isNotEmpty;
    return baseValid;
  }

  void _goNext() {
    setState(() => _submitted = true);
    if (_isFormValid) {
      List<String> datosContacto = [
        _emailCtrl.text,
        _emailVerifyCtrl.text,
        _phoneCtrl.text,
        _phoneVerifyCtrl.text,
        _smsCodeCtrl.text,
      ];
      final List<String> datosCompletos =
          ModalRoute.of(context)!.settings.arguments as List<String>;
      final List<String> datosFinales = [...datosCompletos, ...datosContacto];
      Navigator.pushNamed(context, '/work-terms', arguments: datosFinales);
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
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
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
            pasoActual: 4,
            tituloPaso: 'Contacto del Trabajo',
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
                    _sectionHeader(Icons.contact_mail, 'Correo electrónico'),
                    _sectionCard(
                      children: [
                        TextFormField(
                          controller: _emailCtrl,
                          focusNode: _focusEmail,
                          decoration: _inputDecoration(
                            'Opcional: correo electrónico',
                            Icons.email,
                          ),
                          validator: _validateEmail,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => FocusScope.of(
                            context,
                          ).requestFocus(_focusEmailVerify),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailVerifyCtrl,
                          focusNode: _focusEmailVerify,
                          decoration: _inputDecoration(
                            'Verificar correo',
                            Icons.verified_user,
                          ),
                          validator: _validateEmailVerify,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_focusPhone),
                        ),
                      ],
                    ),
                    _sectionHeader(Icons.phone_android, 'Contacto Telefónico'),
                    _sectionCard(
                      children: [
                        TextFormField(
                          controller: _phoneCtrl,
                          focusNode: _focusPhone,
                          decoration: _inputDecoration(
                            'Requerido: número de teléfono',
                            Icons.phone,
                          ),
                          validator: _validatePhone,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          textInputAction: TextInputAction.next,
                          onChanged: (v) {
                            if (v.length == 10) {
                              FocusScope.of(
                                context,
                              ).requestFocus(_focusPhoneVerify);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneVerifyCtrl,
                          focusNode: _focusPhoneVerify,
                          decoration: _inputDecoration(
                            'Verificar teléfono',
                            Icons.check,
                          ),
                          validator: _validatePhoneVerify,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _goNext(),
                        ),
                        if (_isPhoneVerified) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => setState(() => _codeSent = true),
                            icon: const Icon(Icons.send, color: Colors.white),
                            label: const Text(
                              'Enviar código de verificación',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: govBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          if (_codeSent) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _smsCodeCtrl,
                              focusNode: _focusSmsCode,
                              decoration: _inputDecoration(
                                'Código de verificación',
                                Icons.sms,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              validator: _validateSmsCode,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _goNext(),
                            ),
                          ],
                        ],
                      ],
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
