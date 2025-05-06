// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../../utils/codigos_postales_loader.dart';
import '../widgets/steap_header.dart';
import '../widgets/navigation_buttons.dart';
import '../widgets/map_selector.dart';

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

class DireccionDataScreen extends StatefulWidget {
  const DireccionDataScreen({super.key});

  @override
  State<DireccionDataScreen> createState() => _DireccionDataScreenState();
}

class _DireccionDataScreenState extends State<DireccionDataScreen> {
  final _formKey = GlobalKey<FormState>();
  static const govBlue = Color(0xFF0B3B60);

  final _cpCtrl = TextEditingController();
  final _numExtCtrl = TextEditingController();
  final _numIntCtrl = TextEditingController();
  final _manualComunidadCtrl = TextEditingController();
  final _manualCalleCtrl = TextEditingController();

  String? _selectedColonia;
  String? _selectedCalle;
  List<String> _colonias = [];
  List<String> _calles = [];
  LatLng? _pickedLocation;
  final _loader = CodigoPostalLoader();
  bool _submitted = false;

  bool get _isManualColonia =>
      _colonias.isEmpty || _selectedColonia == '__OTRA__';
  bool get _isManualCalle => _calles.isEmpty || _selectedCalle == '__OTRA__';

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
    for (final c in [
      _cpCtrl,
      _numExtCtrl,
      _numIntCtrl,
      _manualComunidadCtrl,
      _manualCalleCtrl
    ]) {
      c.addListener(() {
        setState(() {});
        _actualizarUbicacionDesdeFormulario();
      });
    }
  }

  Future<void> _inicializarDatos() async {
    await _loader.cargarDesdeXML();
    _cpCtrl.addListener(_onCpChanged);
  }

  void _onCpChanged() {
    final cp = _cpCtrl.text;
    if (cp.length == 5) {
      final colonias = _loader.buscarColoniasPorCP(cp);
      final calles = _loader.buscarCallesPorCP(cp);
      setState(() {
        _colonias = colonias;
        _calles = calles;
        _selectedColonia = null;
        _selectedCalle = null;
        _manualComunidadCtrl.clear();
        _manualCalleCtrl.clear();
      });
    }
  }

  Future<void> _actualizarUbicacionDesdeFormulario() async {
    final cp = _cpCtrl.text;
    final comunidad =
        _isManualColonia ? _manualComunidadCtrl.text : _selectedColonia;
    final calle = _isManualCalle ? _manualCalleCtrl.text : _selectedCalle;
    final numero = _numExtCtrl.text;

    if (cp.length == 5 &&
        comunidad != null &&
        comunidad.isNotEmpty &&
        calle != null &&
        calle.isNotEmpty) {
      final direccion = '$calle, $comunidad, $cp, Querétaro, México';
      try {
        final locations = await locationFromAddress(direccion);
        if (locations.isNotEmpty) {
          final newLocation =
              LatLng(locations.first.latitude, locations.first.longitude);
          setState(() => _pickedLocation = newLocation);
        }
      } catch (e) {
        debugPrint('No se pudo obtener la ubicación: $e');
      }
    }
  }

  bool get _isFormValid {
    final validColonia = _isManualColonia
        ? _manualComunidadCtrl.text.trim().isNotEmpty
        : _selectedColonia != null && _selectedColonia!.isNotEmpty;

    final validCalle = _isManualCalle
        ? _manualCalleCtrl.text.trim().isNotEmpty
        : _selectedCalle != null && _selectedCalle!.isNotEmpty;

    return _formKey.currentState?.validate() == true &&
        validColonia &&
        validCalle &&
        _pickedLocation != null;
  }

  void _goNext() {
    setState(() => _submitted = true);
    if (!_isFormValid) return;
    Navigator.pushNamed(context, '/contacto-data');
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
          Text(title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: govBlue,
              )),
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
              tituloPaso: 'Dirección',
              tituloSiguiente: 'Contacto'),
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
                    _sectionHeader(
                        Icons.travel_explore, 'Dirección del Ciudadano'),
                    _sectionCard(children: [
                      TextFormField(
                        controller: _cpCtrl,
                        decoration: _inputDecoration(
                            'Código Postal', Icons.location_on),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(5)
                        ],
                        validator: (v) =>
                            v != null && v.length == 5 ? null : '5 dígitos',
                      ),
                      const SizedBox(height: 12),
                      _colonias.isEmpty
                          ? TextFormField(
                              controller: _manualComunidadCtrl,
                              decoration: _inputDecoration(
                                  'Comunidad (escríbela)', Icons.home_work),
                              inputFormatters: [UpperCaseTextFormatter()],
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Requerido'
                                  : null,
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<String>(
                                  decoration: _inputDecoration(
                                      'Selecciona tu comunidad'),
                                  items: [
                                    ..._colonias
                                        .map((colonia) => DropdownMenuItem(
                                              value: colonia,
                                              child: Text(colonia),
                                            )),
                                    const DropdownMenuItem(
                                      value: '__OTRA__',
                                      child: Text('Otra...'),
                                    ),
                                  ],
                                  value: _selectedColonia,
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedColonia = val;
                                      if (val != '__OTRA__') {
                                        _manualComunidadCtrl.clear();
                                      }
                                    });
                                    _actualizarUbicacionDesdeFormulario();
                                  },
                                  validator: (val) => val == null || val.isEmpty
                                      ? 'Selecciona una'
                                      : null,
                                ),
                                if (_selectedColonia == '__OTRA__') ...[
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _manualComunidadCtrl,
                                    decoration: _inputDecoration(
                                        'Escribe tu comunidad'),
                                    inputFormatters: [UpperCaseTextFormatter()],
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                            ? 'Requerido'
                                            : null,
                                  ),
                                ],
                              ],
                            ),
                      const SizedBox(height: 12),
                      _calles.isEmpty
                          ? TextFormField(
                              controller: _manualCalleCtrl,
                              decoration: _inputDecoration(
                                  'Calle (escríbela)', Icons.streetview),
                              inputFormatters: [UpperCaseTextFormatter()],
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Requerido'
                                  : null,
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<String>(
                                  decoration:
                                      _inputDecoration('Selecciona tu calle'),
                                  items: [
                                    ..._calles.map((calle) => DropdownMenuItem(
                                          value: calle,
                                          child: Text(calle),
                                        )),
                                    const DropdownMenuItem(
                                      value: '__OTRA__',
                                      child: Text('Otra...'),
                                    ),
                                  ],
                                  value: _selectedCalle,
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedCalle = val;
                                      if (val != '__OTRA__') {
                                        _manualCalleCtrl.clear();
                                      }
                                    });
                                    _actualizarUbicacionDesdeFormulario();
                                  },
                                  validator: (val) => val == null || val.isEmpty
                                      ? 'Selecciona una'
                                      : null,
                                ),
                                if (_selectedCalle == '__OTRA__') ...[
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _manualCalleCtrl,
                                    decoration:
                                        _inputDecoration('Escribe tu calle'),
                                    inputFormatters: [UpperCaseTextFormatter()],
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                            ? 'Requerido'
                                            : null,
                                  ),
                                ],
                              ],
                            ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: TextFormField(
                            controller: _numExtCtrl,
                            decoration: _inputDecoration(
                                'Número exterior', Icons.confirmation_number),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v!.isNotEmpty ? null : 'Requerido',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _numIntCtrl,
                            decoration: _inputDecoration(
                                'Número interior (opcional)',
                                Icons.confirmation_number_outlined),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      MapSelector(
                        initialLocation: _pickedLocation,
                        onLocationSelected: (pos) =>
                            setState(() => _pickedLocation = pos),
                      ),
                      const SizedBox(height: 8),
                      if (_pickedLocation != null)
                        Text(
                          'Ubicación: ${_pickedLocation!.latitude.toStringAsFixed(4)}, ${_pickedLocation!.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(color: Color(0xFF0B3B60)),
                        ),
                    ])
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
