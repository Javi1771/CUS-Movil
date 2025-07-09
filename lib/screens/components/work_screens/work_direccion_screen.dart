// 📄 work_direccion_screen.dart
// ignore_for_file: unused_local_variable, use_build_context_synchronously, deprecated_member_use

import 'package:cus_movil/screens/widgets/map_selector.dart';
import 'package:cus_movil/screens/widgets/navigation_buttons.dart';
import 'package:cus_movil/screens/widgets/steap_header.dart';
import 'package:cus_movil/utils/codigos_postales_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class WorkDireccionScreen extends StatefulWidget {
  const WorkDireccionScreen({super.key});

  @override
  State<WorkDireccionScreen> createState() => _WorkDireccionScreenState();
}

class _WorkDireccionScreenState extends State<WorkDireccionScreen> {
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

    _loader.cargarDesdeXML().catchError((e) {
      debugPrint('Error cargando CP XML: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error cargando datos de CP')),
      );
    });

    for (final ctrl in [
      _cpCtrl,
      _manualComunidadCtrl,
      _manualCalleCtrl,
      _numExtCtrl,
      _numIntCtrl,
    ]) {
      ctrl.addListener(() {
        setState(() {});
      });
    }

    _cpCtrl.addListener(() {
      _onCpChanged(_cpCtrl.text);
    });

    _manualComunidadCtrl.addListener(() {
      _pickedLocation = null;
      setState(() {});
      _updateMapFromForm();
    });

    _manualCalleCtrl.addListener(() {
      _numExtCtrl.clear();
      _pickedLocation = null;
      setState(() {});
      _updateMapFromForm();
    });

    _numExtCtrl.addListener(() {
      _pickedLocation = null;
      setState(() {});
      _updateMapFromForm();
    });
  }

  void _onCpChanged(String cp) {
    if (cp.length == 5) {
      _colonias = _loader.buscarColoniasPorCP(cp);
      _calles = _loader.buscarCallesPorCP(cp);
      _selectedColonia = null;
      _selectedCalle = null;
      _manualComunidadCtrl.clear();
      _manualCalleCtrl.clear();
      _numExtCtrl.clear();
      _numIntCtrl.clear();
      _pickedLocation = null;
      setState(() {});
    } else {
      _colonias = [];
      _calles = [];
      _selectedColonia = null;
      _selectedCalle = null;
      _manualComunidadCtrl.clear();
      _manualCalleCtrl.clear();
      _numExtCtrl.clear();
      _numIntCtrl.clear();
      _pickedLocation = null;
      setState(() {});
    }
  }

  Future<void> _updateMapFromForm() async {
    if (_cpCtrl.text.length != 5) return;
    final colonia = _isManualColonia
        ? _manualComunidadCtrl.text.trim()
        : (_selectedColonia ?? '');
    final calle =
        _isManualCalle ? _manualCalleCtrl.text.trim() : (_selectedCalle ?? '');
    final numExt = _numExtCtrl.text.trim();
    if (colonia.isEmpty || calle.isEmpty || numExt.isEmpty) return;

    final address = '$numExt $calle, $colonia, CP ${_cpCtrl.text}, México';
    try {
      final results = await locationFromAddress(address);
      if (results.isNotEmpty) {
        final loc = results.first;
        _pickedLocation = LatLng(loc.latitude, loc.longitude);
        setState(() {});
      }
    } catch (e) {
      debugPrint('Forward geocoding failed: $e');
    }
  }

  Future<void> _populateFromCoordinates(LatLng latLng) async {
    try {
      await _loader.cargarDesdeXML().catchError((e) {
        debugPrint('Reintento de carga XML falló: $e');
      });

      final places =
          await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (places.isEmpty) return;
      final pl = places.first;

      _cpCtrl.text = pl.postalCode ?? '';
      _onCpChanged(_cpCtrl.text);

      final subLocality = pl.subLocality ?? pl.locality ?? '';
      if (_colonias.contains(subLocality)) {
        _selectedColonia = subLocality;
        _manualComunidadCtrl.clear();
      } else {
        _selectedColonia = '__OTRA__';
        _manualComunidadCtrl.text = subLocality;
      }

      final streetName = pl.thoroughfare ?? '';
      if (_calles.contains(streetName)) {
        _selectedCalle = streetName;
        _manualCalleCtrl.clear();
      } else {
        _selectedCalle = '__OTRA__';
        _manualCalleCtrl.text = streetName;
      }

      _numExtCtrl.text = pl.subThoroughfare ?? '';

      _pickedLocation = latLng;
      setState(() {});
    } catch (e) {
      debugPrint('Geocoding failed: $e');
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
        _numExtCtrl.text.isNotEmpty;
  }

  void _goNext() {
    setState(() => _submitted = true);
    if (_isFormValid) {
      final datosDireccion = [
        _cpCtrl.text,
        _selectedColonia == '__OTRA__'
            ? _manualComunidadCtrl.text
            : _selectedColonia ?? '',
        _selectedCalle == '__OTRA__'
            ? _manualCalleCtrl.text
            : _selectedCalle ?? '',
        _numExtCtrl.text,
        _numIntCtrl.text,
        _pickedLocation?.latitude.toString() ?? '',
        _pickedLocation?.longitude.toString() ?? '',
      ];

      final datosPersonales =
          ModalRoute.of(context)!.settings.arguments as List<String>;
      final datosCompletos = [...datosPersonales, ...datosDireccion];

      // 🔹 Ruta corregida a /work-contact
      Navigator.pushNamed(context, '/work-contact', arguments: datosCompletos);
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
                fontSize: 16, fontWeight: FontWeight.bold, color: govBlue),
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
            tituloPaso: 'Dirección del Trabajo',
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
                    _sectionHeader(Icons.work, 'Dirección del Trabajo'),
                    _sectionCard(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Align(
                            alignment: Alignment.centerLeft,
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
                                backgroundColor: govBlue,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ),
                        // Aquí continúa el resto del formulario (CP, colonia, calle, etc.)
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
