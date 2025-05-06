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
    //* Carga datos de CP en background
    _loader.cargarDesdeXML().catchError((e) {
      debugPrint('Error cargando CP XML: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error cargando CP')),
      );
    });
    _cpCtrl.addListener(_onCpChanged);
    for (final c in [
      _cpCtrl,
      _numExtCtrl,
      _numIntCtrl,
      _manualComunidadCtrl,
      _manualCalleCtrl,
    ]) {
      c.addListener(() {
        setState(() {}); //* refresca UI/validaciones
        _actualizarUbicacionDesdeFormulario();
      });
    }
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

    if (cp.length == 5 &&
        comunidad != null &&
        comunidad.isNotEmpty &&
        calle != null &&
        calle.isNotEmpty) {
      final direccion = '$calle, $comunidad, $cp, Querétaro, México';
      try {
        final locations = await locationFromAddress(direccion);
        if (locations.isNotEmpty) {
          setState(() {
            _pickedLocation = LatLng(
              locations.first.latitude,
              locations.first.longitude,
            );
          });
        }
      } catch (e) {
        debugPrint('No se pudo obtener la ubicación: $e');
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    //* Solicita permisos si es necesario
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

    //* Obtiene posición
    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _pickedLocation = LatLng(pos.latitude, pos.longitude);
    });

    //* Reverse geocoding
    final places = await placemarkFromCoordinates(pos.latitude, pos.longitude);
    if (places.isEmpty) return;
    final pl = places.first;

    //* Rellena CP y repuebla colonias/calles
    _cpCtrl.text = pl.postalCode ?? '';
    _onCpChanged();

    //* Asigna colonia
    final sub = pl.subLocality ?? pl.locality ?? '';
    if (_colonias.contains(sub)) {
      _selectedColonia = sub;
    } else {
      _selectedColonia = '__OTRA__';
      _manualComunidadCtrl.text = sub;
    }

    //* Asigna calle
    final street = pl.thoroughfare ?? '';
    if (_calles.contains(street)) {
      _selectedCalle = street;
      _manualCalleCtrl.clear();
    } else {
      _selectedCalle = null;
      _manualCalleCtrl.text = street;
    }

    _numExtCtrl.text = pl.subThoroughfare ?? '';
    setState(() {}); //* Actualiza UI
  }

  bool get _isFormValid {
    final okCol = _isManualColonia
        ? _manualComunidadCtrl.text.trim().isNotEmpty
        : (_selectedColonia?.isNotEmpty ?? false);
    final okCall = _isManualCalle
        ? _manualCalleCtrl.text.trim().isNotEmpty
        : (_selectedCalle?.isNotEmpty ?? false);
    return _formKey.currentState?.validate() == true &&
        okCol &&
        okCall &&
        _pickedLocation != null;
  }

  void _goNext() {
    setState(() => _submitted = true);
    if (!_isFormValid) return;
    Navigator.pushNamed(context, '/contact-moral');
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
            tituloSiguiente: 'Contacto',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Form(
                key: _formKey,
                autovalidateMode:
                    _submitted ? AutovalidateMode.always : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(Icons.corporate_fare, 'Dirección de la Empresa'),
                    _sectionCard(children: [
                      //? Botón "Usar mi ubicación" alineado a la izquierda
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
                              icon: const Icon(Icons.my_location, size: 20, color: Colors.white),
                              label: const Text(
                                'Usar mi ubicación',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                shadowColor: Colors.transparent,
                              ),
                            ),
                          ),
                        ),
                      ),

                      //? Código Postal
                      TextFormField(
                        controller: _cpCtrl,
                        decoration:
                            _inputDecoration('Código Postal', Icons.location_on),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(5),
                        ],
                        validator: (v) =>
                            v != null && v.length == 5 ? null : '5 dígitos',
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),

                      //? Colonia / Comunidad
                      _colonias.isNotEmpty
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<String>(
                                  decoration: _inputDecoration('Comunidad'),
                                  items: [
                                    ..._colonias.map((col) => DropdownMenuItem(
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
                                  validator: (v) =>
                                      v == null || v.isEmpty ? 'Selecciona una' : null,
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
                          : TextFormField(
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
                      _calles.isNotEmpty
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<String>(
                                  decoration: _inputDecoration('Calle'),
                                  items: [
                                    ..._calles.map((cal) => DropdownMenuItem(
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
                                  validator: (v) =>
                                      v == null || v.isEmpty ? 'Selecciona una' : null,
                                ),
                                if (_selectedCalle == '__OTRA__') ...[
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _manualCalleCtrl,
                                    decoration: _inputDecoration(
                                        'Escribe tu calle', Icons.edit_location),
                                    inputFormatters: [UpperCaseTextFormatter()],
                                    validator: (v) => v == null || v.trim().isEmpty
                                        ? 'Requerido'
                                        : null,
                                  ),
                                ],
                              ],
                            )
                          : TextFormField(
                              controller: _manualCalleCtrl,
                              decoration:
                                  _inputDecoration('Calle (escríbela)', Icons.streetview),
                              inputFormatters: [UpperCaseTextFormatter()],
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Requerido'
                                  : null,
                            ),
                      const SizedBox(height: 12),

                      //? Números
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _numExtCtrl,
                              decoration: _inputDecoration(
                                  'Número exterior', Icons.confirmation_number),
                              keyboardType: TextInputType.number,
                              validator: (v) =>
                                  v != null && v.isNotEmpty ? null : 'Requerido',
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
                        ],
                      ),
                      const SizedBox(height: 16),

                      //? Mapa
                      MapSelector(
                        initialLocation: _pickedLocation,
                        onLocationSelected: (pos) =>
                            setState(() => _pickedLocation = pos),
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
