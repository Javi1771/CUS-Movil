// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/curp_utils.dart';
import '../../widgets/navigation_buttons.dart';
import '../../widgets/steap_header.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
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

  // Controladores principales
  final _nominaCtrl = TextEditingController();
  final _puestoCtrl = TextEditingController();
  final _departamentoCtrl = TextEditingController();
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

  // Focus nodes
  final _focusNomina = FocusNode();
  final _focusPuesto = FocusNode();
  final _focusDepartamento = FocusNode();
  final _focusCurp = FocusNode();
  final _focusCurpVerify = FocusNode();
  final _focusRazonSocial = FocusNode();
  final _focusNombre = FocusNode();
  final _focusApellidoP = FocusNode();
  final _focusApellidoM = FocusNode();
  final _focusPass = FocusNode();
  final _focusConfirmPass = FocusNode();

  bool _showPass = false;
  bool _hasStartedTyping = false; // Para controlar cuándo empezar a validar
  final _passwordRegex = RegExp(
    r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[$&!¡¿?@]).{8,}$',
  );

  @override
  void initState() {
    super.initState();
    // Agregar listeners para detectar cuando el usuario empieza a escribir
    for (var c in [
      _nominaCtrl,
      _puestoCtrl,
      _departamentoCtrl,
      _curpCtrl,
      _curpVerifyCtrl,
      _nombreCtrl,
      _apellidoPCtrl,
      _apellidoMCtrl,
      _passCtrl,
      _confirmPassCtrl,
    ]) {
      c.addListener(() {
        if (!_hasStartedTyping && c.text.isNotEmpty) {
          setState(() {
            _hasStartedTyping = true;
          });
        } else if (_hasStartedTyping) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    // Dispose de todos los controladores
    for (var c in [
      _nominaCtrl,
      _puestoCtrl,
      _departamentoCtrl,
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

    // Dispose de focus nodes
    for (var f in [
      _focusNomina,
      _focusPuesto,
      _focusDepartamento,
      _focusCurp,
      _focusCurpVerify,
      _focusRazonSocial,
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
    // Solo validar si ya empezó a escribir o si hay contenido
    if (!_hasStartedTyping && (value == null || value.isEmpty)) {
      return null;
    }

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
    // Solo validar si ya empezó a escribir o si hay contenido
    if (!_hasStartedTyping && (value == null || value.isEmpty)) {
      return null;
    }

    if (value == null || value.isEmpty) {
      return 'Confirma la contraseña';
    }
    if (value != _passCtrl.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  String? _validateCurp(String? v) {
    // Solo validar si ya empezó a escribir o si hay contenido
    if (!_hasStartedTyping && (v == null || v.isEmpty)) {
      return null;
    }

    final curpRegExp = RegExp(
      r'^[A-Z]{4}\d{6}[HM][A-Z]{2}[B-DF-HJ-NP-TV-Z]{3}[A-Z\d]\d$',
      caseSensitive: false,
    );
    if (v == null || v.length != 18) return 'Deben ser 18 caracteres';
    if (!curpRegExp.hasMatch(v)) return 'CURP no válida';
    return null;
  }

  String? _validateVerify(String? v) {
    // Solo validar si ya empezó a escribir o si hay contenido
    if (!_hasStartedTyping && (v == null || v.isEmpty)) {
      return null;
    }

    if (v == null || v.isEmpty) return 'Requerido';
    return v.toUpperCase() != _curpCtrl.text.toUpperCase()
        ? 'No coincide con CURP'
        : null;
  }

  String? _validateRequired(String? value, String fieldName) {
    // Solo validar si ya empezó a escribir o si hay contenido
    if (!_hasStartedTyping && (value == null || value.isEmpty)) {
      return null;
    }

    return value == null || value.trim().isEmpty ? 'Requerido' : null;
  }

  // Getter para verificar si el formulario es válido
  bool get _isFormValid {
    // Solo verificar validez si el usuario ya empezó a interactuar
    if (!_hasStartedTyping) return false;

    return _formKey.currentState?.validate() == true;
  }

  void _goNext() {
    // Forzar validación cuando el usuario intenta continuar
    setState(() {
      _hasStartedTyping = true;
    });

    if (_formKey.currentState?.validate() == true) {
      List<String> datosPersonales = [
        _nominaCtrl.text,
        _puestoCtrl.text,
        _departamentoCtrl.text,
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

      Navigator.pushNamed(
        context,
        '/work-direccion',
        arguments: datosPersonales,
      );
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
            pasoActual: 2,
            tituloPaso: 'Datos trabajador',
            tituloSiguiente: 'Dirección',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Form(
                key: _formKey,
                // Cambiar a onUserInteraction para que solo valide después de que el usuario interactúe
                autovalidateMode: _hasStartedTyping
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Datos del trabajador
                    _sectionHeader(Icons.work, 'Datos del Trabajador'),
                    _sectionCard(
                      children: [
                        // Nómina
                        TextFormField(
                          controller: _nominaCtrl,
                          focusNode: _focusNomina,                  // <-- FALTA
                          decoration: _inputDecoration('Nómina', Icons.badge),
                          validator: (v) => _validateRequired(v, 'Nómina'),
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [UpperCaseTextFormatter()],
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_focusPuesto),
                        ),

                        // Puesto
                        TextFormField(
                          controller: _puestoCtrl,
                          focusNode: _focusPuesto,                  // <-- FALTA
                          decoration: _inputDecoration('Puesto', Icons.work),
                          validator: (v) => _validateRequired(v, 'Puesto'),
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [UpperCaseTextFormatter()],
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_focusDepartamento),
                        ),

                        // Departamento
                        TextFormField(
                          controller: _departamentoCtrl,
                          focusNode: _focusDepartamento,            // <-- FALTA
                          decoration: _inputDecoration('Departamento', Icons.apartment),
                          validator: (v) => _validateRequired(v, 'Departamento'),
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [UpperCaseTextFormatter()],
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_focusCurp),
                        ),
                      ],
                    ),

                    _sectionHeader(
                      Icons.person,
                      'Datos Personales',
                    ),
                    _sectionCard(
                      children: [
                        TextFormField(
                          controller: _curpCtrl,
                          focusNode: _focusCurp,
                          onChanged: _onCurpChanged,
                          decoration: _inputDecoration('CURP', Icons.badge),
                          validator: _validateCurp,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(18),
                            UpperCaseTextFormatter(),
                          ],
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => FocusScope.of(
                            context,
                          ).requestFocus(_focusCurpVerify),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _curpVerifyCtrl,
                          focusNode: _focusCurpVerify,
                          decoration: _inputDecoration(
                            'Verificar CURP',
                            Icons.verified,
                          ),
                          validator: _validateVerify,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(18),
                            UpperCaseTextFormatter(),
                          ],
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_focusNombre),
                        ),
                      ],
                    ),

                    _sectionHeader(Icons.assignment_ind, 'Nombre completo'),
                    _sectionCard(
                      children: [
                        TextFormField(
                          controller: _nombreCtrl,
                          focusNode: _focusNombre,
                          decoration: _inputDecoration(
                            'Nombre(s)',
                            Icons.account_circle,
                          ),
                          validator: (v) => _validateRequired(v, 'Nombre'),
                          inputFormatters: [UpperCaseTextFormatter()],
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => FocusScope.of(
                            context,
                          ).requestFocus(_focusApellidoP),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _apellidoPCtrl,
                          focusNode: _focusApellidoP,
                          decoration: _inputDecoration(
                            'Apellido paterno',
                            Icons.person,
                          ),
                          validator: (v) =>
                              _validateRequired(v, 'Apellido paterno'),
                          inputFormatters: [UpperCaseTextFormatter()],
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => FocusScope.of(
                            context,
                          ).requestFocus(_focusApellidoM),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _apellidoMCtrl,
                          focusNode: _focusApellidoM,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_focusPass),
                          decoration: _inputDecoration(
                            'Apellido materno (opcional)',
                            Icons.person,
                          ),
                          inputFormatters: [UpperCaseTextFormatter()],
                        ),
                      ],
                    ),

                    _sectionHeader(Icons.cake, 'Nacimiento'),
                    _sectionCard(
                      children: [
                        TextFormField(
                          controller: _fechaNacCtrl,
                          readOnly: true,
                          enabled: false,
                          decoration: _inputDecoration(
                            'Fecha de nacimiento',
                            Icons.calendar_month,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _generoCtrl,
                                readOnly: true,
                                enabled: false,
                                decoration: _inputDecoration(
                                  'Género',
                                  Icons.wc,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _estadoNacCtrl,
                                readOnly: true,
                                enabled: false,
                                decoration: _inputDecoration(
                                  'Estado nacimiento',
                                  Icons.public,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    _sectionHeader(Icons.password, 'Contraseña'),
                    _sectionCard(
                      children: [
                        TextFormField(
                          controller: _passCtrl,
                          focusNode: _focusPass,
                          obscureText: !_showPass,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => FocusScope.of(
                            context,
                          ).requestFocus(_focusConfirmPass),
                          decoration: _inputDecoration('Contraseña', Icons.lock)
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
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmPassCtrl,
                          focusNode: _focusConfirmPass,
                          obscureText: !_showPass,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _goNext(),
                          decoration: _inputDecoration(
                            'Confirmar contraseña',
                            Icons.check_circle_outline,
                          ),
                          validator: _validateConfirm,
                        ),
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
