// lib/screens/fisica_data_screen.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/curp_utils.dart';
import '../widgets/steap_header.dart';

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

class FisicaDataScreen extends StatefulWidget {
  const FisicaDataScreen({super.key});

  @override
  State<FisicaDataScreen> createState() => _FisicaDataScreenState();
}

class _FisicaDataScreenState extends State<FisicaDataScreen> {
  final _formKey = GlobalKey<FormState>();
  static const govBlue = Color(0xFF0B3B60);

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

  bool _showPass = false;
  bool _submitted = false;

  @override
  void dispose() {
    for (var c in [
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
    super.dispose();
  }

  void _onCurpChanged(String v) {
    final curp = v.toUpperCase();
    if (curp.length == 18) {
      setState(() {
        _fechaNacCtrl.text =
            (obtenerFechaNacimientoDeCurp(curp) ?? '').toUpperCase();
        _generoCtrl.text = (obtenerGeneroDeCurp(curp) ?? '').toUpperCase();
        _estadoNacCtrl.text = (obtenerEstadoDeCurp(curp) ?? '').toUpperCase();
      });
    }
  }

  String? _validateCurp(String? v) =>
      v != null && v.length == 18 ? null : 'Deben ser 18 caracteres';

  String? _validateVerify(String? v) {
    if (v == null || v.isEmpty) return 'Requerido';
    return v.toUpperCase() != _curpCtrl.text.toUpperCase()
        ? 'No coincide con CURP'
        : null;
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

  bool get _isFormValid => _formKey.currentState?.validate() == true;

  void _goNext() {
    setState(() => _submitted = true);
    if (_isFormValid) {
      Navigator.pushNamed(context, '/direccion-data');
    }
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
            tituloPaso: 'Datos personales',
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
                    _sectionHeader(Icons.badge, 'CURP'),
                    _sectionCard(children: [
                      TextFormField(
                        controller: _curpCtrl,
                        onChanged: _onCurpChanged,
                        decoration: _inputDecoration('CURP', Icons.badge),
                        validator: _validateCurp,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(18),
                          UpperCaseTextFormatter(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _curpVerifyCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: _inputDecoration(
                            'Verificar CURP', Icons.check_circle_outline),
                        validator: _validateVerify,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(18),
                          UpperCaseTextFormatter(),
                        ],
                      ),
                    ]),
                    _sectionHeader(Icons.assignment_ind, 'Nombre completo'),
                    _sectionCard(children: [
                      TextFormField(
                        controller: _nombreCtrl,
                        decoration: _inputDecoration(
                            'Nombre(s)', Icons.account_circle),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        inputFormatters: [UpperCaseTextFormatter()],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _apellidoPCtrl,
                        decoration:
                            _inputDecoration('Apellido paterno', Icons.person),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        inputFormatters: [UpperCaseTextFormatter()],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _apellidoMCtrl,
                        decoration:
                            _inputDecoration('Apellido materno', Icons.person),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        inputFormatters: [UpperCaseTextFormatter()],
                      ),
                    ]),
                    _sectionHeader(Icons.cake, 'Nacimiento'),
                    _sectionCard(children: [
                      TextFormField(
                        controller: _fechaNacCtrl,
                        readOnly: true,
                        enabled: false,
                        style: const TextStyle(
                            color: Colors.black87, fontSize: 16),
                        decoration: _inputDecoration(
                            'Fecha de nacimiento', Icons.calendar_month),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _generoCtrl,
                              readOnly: true,
                              enabled: false,
                              decoration:
                                  _inputDecoration('Género', Icons.wc),
                              validator: (v) =>
                                  v!.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _estadoNacCtrl,
                              readOnly: true,
                              enabled: false,
                              decoration: _inputDecoration(
                                  'Estado nacimiento', Icons.public),
                              validator: (v) =>
                                  v!.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      ),
                    ]),
                    _sectionHeader(Icons.password, 'Contraseña'),
                    _sectionCard(children: [
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: !_showPass,
                        decoration:
                            _inputDecoration('Contraseña', Icons.lock)
                                .copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPass
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: govBlue,
                            ),
                            onPressed: () =>
                                setState(() => _showPass = !_showPass),
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPassCtrl,
                        obscureText: !_showPass,
                        decoration: _inputDecoration(
                            'Confirmar contraseña', Icons.check_circle_outline),
                        validator: (v) =>
                            v != _passCtrl.text ? 'No coinciden' : null,
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Anterior'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: govBlue,
                  side: const BorderSide(color: govBlue),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isFormValid ? _goNext : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Siguiente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: govBlue,
                  disabledBackgroundColor: govBlue.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
