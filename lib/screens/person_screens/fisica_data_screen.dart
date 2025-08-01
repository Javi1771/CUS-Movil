import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/curp_utils.dart';
import '../../widgets/steap_header.dart';
import '../../widgets/navigation_buttons.dart';

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
  final _estadoCivilCtrl = TextEditingController();
  final _ocupacionCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  final _focusCurp = FocusNode();
  final _focusCurpVerify = FocusNode();
  final _focusNombre = FocusNode();
  final _focusApellidoP = FocusNode();
  final _focusApellidoM = FocusNode();
  final _focusEstadoCivil = FocusNode();
  final _focusOcupacion = FocusNode();
  final _focusPass = FocusNode();
  final _focusConfirmPass = FocusNode();

  bool _showPass = false;
  final _passwordRegex =
      RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[$&!¡¿?@]).{8,}$');

  @override
  void initState() {
    super.initState();
    for (var c in [
      _curpCtrl,
      _curpVerifyCtrl,
      _nombreCtrl,
      _apellidoPCtrl,
      _estadoCivilCtrl,
      _ocupacionCtrl,
      _passCtrl,
      _confirmPassCtrl,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

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
      _estadoCivilCtrl,
      _ocupacionCtrl,
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
      _focusEstadoCivil,
      _focusOcupacion,
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

  String? _validateCurp(String? v) {
    final curpRegExp = RegExp(
        r'^[A-Z]{4}\d{6}[HM][A-Z]{2}[B-DF-HJ-NP-TV-Z]{3}[A-Z\d]\d$',
        caseSensitive: false);
    if (v == null || v.length != 18) return 'Deben ser 18 caracteres';
    if (!curpRegExp.hasMatch(v)) return 'CURP no válida';
    return null;
  }

  String? _validateVerify(String? v) {
    if (v == null || v.length < 18) return null;
    return v.toUpperCase() != _curpCtrl.text.toUpperCase()
        ? 'No coincide con CURP'
        : null;
  }

  String? _validateRequired(String? v) =>
      v != null && v.isNotEmpty ? null : 'Deben llenar este campo';

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

  InputDecoration _inputDecoration(String label, [IconData? icon]) =>
      InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: govBlue) : null,
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: govBlue, width: 2),
        ),
      );

  bool get _isFormValid => _formKey.currentState?.validate() == true;

  void _goNext() {
    if (_isFormValid) {
      //* Creamos un arreglo con los datos a enviar
      List<String> datosPersonales = [
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

      //* Navegamos a la siguiente pantalla con el arreglo
      Navigator.pushNamed(
        context,
        '/direccion-data',
        arguments: datosPersonales,
      );
    } else {
      setState(() {});
    }
  }

  Widget _sectionHeader(IconData icon, String title) => Padding(
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

  Widget _sectionCard({required List<Widget> children}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
          ],
        ),
        child: Column(children: children),
      );

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
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(Icons.folder_shared, 'CURP'),
                    _sectionCard(children: [
                      TextFormField(
                        controller: _curpCtrl,
                        focusNode: _focusCurp,
                        onChanged: (v) {
                          _onCurpChanged(v);
                          setState(() {});
                        },
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => FocusScope.of(context)
                            .requestFocus(_focusCurpVerify),
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
                        focusNode: _focusCurpVerify,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_focusNombre),
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
                        focusNode: _focusNombre,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => FocusScope.of(context)
                            .requestFocus(_focusApellidoP),
                        decoration:
                            _inputDecoration('Nombre(s)', Icons.account_circle),
                        validator: _validateRequired,
                        inputFormatters: [UpperCaseTextFormatter()],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _apellidoPCtrl,
                        focusNode: _focusApellidoP,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => FocusScope.of(context)
                            .requestFocus(_focusApellidoM),
                        decoration:
                            _inputDecoration('Apellido paterno', Icons.person),
                        validator: _validateRequired,
                        inputFormatters: [UpperCaseTextFormatter()],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _apellidoMCtrl,
                        focusNode: _focusApellidoM,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_focusPass),
                        decoration: _inputDecoration(
                            'Apellido materno (opcional)', Icons.person),
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
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _generoCtrl,
                              readOnly: true,
                              enabled: false,
                              decoration: _inputDecoration('Género', Icons.wc),
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
                            ),
                          ),
                        ],
                      ),
                    ]),
                    _sectionHeader(Icons.password, 'Contraseña'),
                    _sectionCard(children: [
                      TextFormField(
                        controller: _passCtrl,
                        focusNode: _focusPass,
                        obscureText: !_showPass,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => FocusScope.of(context)
                            .requestFocus(_focusConfirmPass),
                        decoration:
                            _inputDecoration('Contraseña', Icons.lock).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                                _showPass
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: govBlue),
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
                            'Confirmar contraseña', Icons.check_circle_outline),
                        validator: _validateConfirm,
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
