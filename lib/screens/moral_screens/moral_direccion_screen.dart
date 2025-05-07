// lib/screens/direccion_data_screen.dart
// ignore_for_file: unused_local_variable, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/codigos_postales_loader.dart';
import '../widgets/steap_header.dart';
import '../widgets/navigation_buttons.dart';
import '../widgets/map_selector.dart';

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

class DireccionMoralScreen extends StatefulWidget {
  const DireccionMoralScreen({super.key});

  @override
  State<DireccionMoralScreen> createState() => _DireccionMoralScreenState();
}

class _DireccionMoralScreenState extends State<DireccionMoralScreen> {
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
  bool get _isManualCalle =>
      _calles.isEmpty || _selectedCalle == '__OTRA__';

  @override
  void initState() {
    super.initState();
    //* Pre-carga de XML sin bloquear UI
    _loader.cargarDesdeXML().catchError((e) {
      debugPrint('Error cargando CP XML: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error cargando datos de CP')),
      );
    });

    //* Escuchar cambios en los controladores para revalidar el formulario
    for (final ctrl in [
      _cpCtrl,
      _manualComunidadCtrl,
      _manualCalleCtrl,
      _numExtCtrl,
      _numIntCtrl,
    ]) {
      ctrl.addListener(() => setState(() {}));
    }
  }

  void _onCpChanged(String cp) {
    if (cp.length == 5) {
      _colonias = _loader.buscarColoniasPorCP(cp);
      _calles = _loader.buscarCallesPorCP(cp);
      _selectedColonia = null;
      _selectedCalle = null;
      _manualComunidadCtrl.clear();
      _manualCalleCtrl.clear();
      setState(() {});
      _tryUpdateLocationFromForm();
    }
  }

  Future<void> _tryUpdateLocationFromForm() async {
    final cp = _cpCtrl.text;
    final comunidad =
        _isManualColonia ? _manualComunidadCtrl.text : _selectedColonia;
    final calle = _isManualCalle ? _manualCalleCtrl.text : _selectedCalle;

    if (cp.length == 5 &&
        comunidad != null &&
        comunidad.isNotEmpty &&
        calle != null &&
        calle.isNotEmpty) {
      try {
        final locs = await locationFromAddress(
            '$calle, $comunidad, $cp, Querétaro, México');
        if (locs.isNotEmpty) {
          _pickedLocation =
              LatLng(locs.first.latitude, locs.first.longitude);
          setState(() {});
        }
      } catch (e) {
        debugPrint('Geocoding failed: $e');
      }
    }
  }

  Future<void> _populateFromCoordinates(LatLng latLng) async {
    try {
      final places =
          await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (places.isEmpty) return;
      final pl = places.first;

      //? 1) Código postal y repoblado
      final cp = pl.postalCode ?? '';
      _cpCtrl.text = cp;
      _onCpChanged(cp);

      //? 2) Colonia / comunidad
      final subRaw = pl.subLocality ?? pl.locality ?? '';
      final subUpper = subRaw.toUpperCase();
      final coloniasUpper =
          _colonias.map((c) => c.toUpperCase()).toList();
      if (coloniasUpper.contains(subUpper)) {
        final match = _colonias[coloniasUpper.indexOf(subUpper)];
        _selectedColonia = match;
        _manualComunidadCtrl.clear();
      } else {
        _selectedColonia = '__OTRA__';
        _manualComunidadCtrl.text = subRaw;
      }

      //? 3) Calle
      final streetRaw = pl.thoroughfare ?? '';
      final streetUpper = streetRaw.toUpperCase();
      final callesUpper =
          _calles.map((c) => c.toUpperCase()).toList();
      if (callesUpper.contains(streetUpper)) {
        final match = _calles[callesUpper.indexOf(streetUpper)];
        _selectedCalle = match;
        _manualCalleCtrl.clear();
      } else {
        _selectedCalle = '__OTRA__';
        _manualCalleCtrl.text = streetRaw;
      }

      //? 4) Número exterior
      _numExtCtrl.text = pl.subThoroughfare ?? '';

      //? 5) Guardar latLng
      _pickedLocation = latLng;

      setState(() {});
    } catch (e) {
      debugPrint('Reverse geocoding failed: $e');
    }
  }

  Future<void> _useCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activa tu GPS para continuar')),
      );
      return;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      perm = await Geolocator.requestPermission();
      if (perm != LocationPermission.always &&
          perm != LocationPermission.whileInUse) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de ubicación denegado')),
        );
        return;
      }
    }

    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    final latLng = LatLng(pos.latitude, pos.longitude);
    await _populateFromCoordinates(latLng);
  }

  bool get _isFormValid {
    final okColonia = _isManualColonia
        ? _manualComunidadCtrl.text.trim().isNotEmpty
        : (_selectedColonia?.isNotEmpty ?? false);
    final okCalle = _isManualCalle
        ? _manualCalleCtrl.text.trim().isNotEmpty
        : (_selectedCalle?.isNotEmpty ?? false);
    return _formKey.currentState?.validate() == true &&
        okColonia &&
        okCalle &&
        _pickedLocation != null;
  }

  void _goNext() {
    setState(() => _submitted = true);
    if (_isFormValid) Navigator.pushNamed(context, '/contact-moral');
  }

  InputDecoration _inputDecoration(String label, [IconData? icon]) {
    return InputDecoration(
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
                  fontSize: 16, fontWeight: FontWeight.bold, color: govBlue)),
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
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
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
            tituloPaso: 'Dirección Empresarial',
            tituloSiguiente: 'Contacto',
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
                    _sectionHeader(Icons.home_work, 'Dirección de la Empresa'),
                    _sectionCard(children: [
                      //? Botón “Usar mi ubicación”
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: govBlue,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _useCurrentLocation,
                              icon: const Icon(Icons.my_location,
                                  size: 20, color: Colors.white),
                              label: const Text(
                                'Usar mi ubicación',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                shadowColor: Colors.transparent,
                              ),
                            ),
                          ),
                        ),
                      ),

                      //? Código Postal
                      TextFormField(
                        controller: _cpCtrl,
                        decoration: _inputDecoration(
                            'Código Postal', Icons.location_on),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(5),
                        ],
                        validator: (v) =>
                            v != null && v.length == 5 ? null : '5 dígitos',
                        textInputAction: TextInputAction.next,
                        onChanged: _onCpChanged,
                      ),
                      const SizedBox(height: 12),

                      //? Colonia / Comunidad
                      if (_colonias.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<String>(
                              decoration: _inputDecoration('Comunidad'),
                              items: [
                                ..._colonias
                                    .map((col) => DropdownMenuItem(
                                          value: col,
                                          child: Text(col),
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
                              },
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Selecciona una'
                                  : null,
                            ),
                            if (_selectedColonia == '__OTRA__') ...[
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _manualComunidadCtrl,
                                decoration: _inputDecoration(
                                    'Escribe tu comunidad', Icons.edit),
                                inputFormatters: [UpperCaseTextFormatter()],
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Requerido'
                                    : null,
                              ),
                            ],
                          ],
                        )
                      else
                        TextFormField(
                          controller: _manualComunidadCtrl,
                          decoration: _inputDecoration(
                              'Comunidad (escríbela)', Icons.apartment),
                          inputFormatters: [UpperCaseTextFormatter()],
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Requerido'
                              : null,
                        ),

                      const SizedBox(height: 12),

                      //? Calle
                      if (_calles.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<String>(
                              decoration: _inputDecoration('Calle'),
                              items: [
                                ..._calles
                                    .map((cal) => DropdownMenuItem(
                                          value: cal,
                                          child: Text(cal),
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
                              },
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Selecciona una'
                                  : null,
                            ),
                            if (_selectedCalle == '__OTRA__') ...[
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _manualCalleCtrl,
                                decoration: _inputDecoration(
                                    'Escribe tu calle', Icons.edit_location),
                                inputFormatters: [UpperCaseTextFormatter()],
                                validator: (v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Requerido'
                                        : null,
                              ),
                            ],
                          ],
                        )
                      else
                        TextFormField(
                          controller: _manualCalleCtrl,
                          decoration: _inputDecoration(
                              'Calle (escríbela)', Icons.streetview),
                          inputFormatters: [UpperCaseTextFormatter()],
                          validator: (v) =>
                              v == null || v.trim().isEmpty
                                  ? 'Requerido'
                                  : null,
                        ),

                      const SizedBox(height: 12),

                      //? Núm. exterior / interior
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _numExtCtrl,
                              decoration: _inputDecoration(
                                  'Núm. exterior', Icons.confirmation_number),
                              keyboardType: TextInputType.number,
                              validator: (v) => v != null && v.isNotEmpty
                                  ? null
                                  : 'Requerido',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _numIntCtrl,
                              decoration: _inputDecoration(
                                  'Núm. interior (opcional)',
                                  Icons.confirmation_number_outlined),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      //? Mapa con callback al mover pin
                      MapSelector(
                        initialLocation: _pickedLocation,
                        onLocationSelected: (pos) async {
                          await _populateFromCoordinates(pos);
                        },
                      ),

                      const SizedBox(height: 8),
                      if (_pickedLocation != null)
                        Text(
                          'Ubicación: ${_pickedLocation!.latitude.toStringAsFixed(4)}, '
                          '${_pickedLocation!.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(color: govBlue),
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
