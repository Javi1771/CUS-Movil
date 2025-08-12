// ignore_for_file: unused_local_variable, use_build_context_synchronously, deprecated_member_use

import 'package:cus_movil/widgets/alert_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/location_service.dart';
import '../../utils/codigos_postales_loader.dart';
import '../../widgets/steap_header.dart';
import '../../widgets/navigation_buttons.dart';
import '../../widgets/map_selector.dart';

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
  bool get _isManualCalle => _calles.isEmpty || _selectedCalle == '__OTRA__';

  @override
  void initState() {
    super.initState();

    //* Carga inicial del XML de colonias/calles
    _loader.cargarDesdeXML().catchError((e) {
      debugPrint('Error cargando CP XML: $e');
      AlertHelper.showAlert(
        'Error cargando datos de CP',
        type: AlertType.error,
      );
    });

    //* Listeners de validación y UI
    for (final ctrl in [
      _cpCtrl,
      _manualComunidadCtrl,
      _manualCalleCtrl,
      _numExtCtrl,
      _numIntCtrl,
    ]) {
      ctrl.addListener(() {
        setState(() {}); //! revalida formulario, refresca UI
      });
    }

    //* Listener especial para CP: limpia todo y recarga colonias/calles
    _cpCtrl.addListener(() {
      _onCpChanged(_cpCtrl.text);
    });

    //* Listener para comunidad manual: actualiza mapa
    _manualComunidadCtrl.addListener(() {
      _pickedLocation = null;
      setState(() {});
      _updateMapFromForm();
    });

    //* Listener para calle manual: limpia numExt y actualiza mapa
    _manualCalleCtrl.addListener(() {
      _numExtCtrl.clear();
      _pickedLocation = null;
      setState(() {});
      _updateMapFromForm();
    });

    //* Listener para número exterior: actualiza mapa
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
      //! Si CP no es válido, limpiamos todo
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

  //* Construye la dirección desde los campos y hace forward‐geocoding
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
      //? Aseguramos XML cargado
      await _loader.cargarDesdeXML().catchError((e) {
        debugPrint('Reintento de carga XML falló: $e');
      });

      final places =
          await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (places.isEmpty) return;
      final pl = places.first;

      //* Código Postal
      _cpCtrl.text = pl.postalCode ?? '';
      _onCpChanged(_cpCtrl.text);

      //* Colonia / Comunidad
      final subLocality = pl.subLocality ?? pl.locality ?? '';
      if (_colonias.contains(subLocality)) {
        _selectedColonia = subLocality;
        _manualComunidadCtrl.clear();
      } else {
        _selectedColonia = '__OTRA__';
        _manualComunidadCtrl.text = subLocality;
      }

      //* Calle
      final streetName = pl.thoroughfare ?? '';
      if (_calles.contains(streetName)) {
        _selectedCalle = streetName;
        _manualCalleCtrl.clear();
      } else {
        _selectedCalle = '__OTRA__';
        _manualCalleCtrl.text = streetName;
      }

      //* Número exterior
      _numExtCtrl.text = pl.subThoroughfare ?? '';

      //* Guardar LatLng y refrescar
      _pickedLocation = latLng;
      setState(() {});
    } catch (e) {
      debugPrint('Geocoding failed: $e');
    }
  }

  final _locationService = LocationService();
  bool _isLocationLoading = false;

  Future<void> _useCurrentLocation() async {
    if (_isLocationLoading) return;

    setState(() {
      _isLocationLoading = true;
    });

    try {
      final isReady = await _locationService.isReady();
      if (!isReady) {
        final permission = await _locationService.requestPermission();
        if (permission != LocationPermission.always &&
            permission != LocationPermission.whileInUse) {
          if (mounted) {
            AlertHelper.showAlert(
              'Activa tu GPS y otorga permisos para continuar',
              type: AlertType.warning,
              duration: const Duration(seconds: 3),
            );
          }
          return;
        }
      }

      final latLng = await _locationService.getCurrentLocation(
        timeout: const Duration(seconds: 8),
      );

      if (latLng != null && mounted) {
        await _populateFromCoordinates(latLng);
      } else if (mounted) {
        AlertHelper.showAlert(
          'No se pudo obtener la ubicación. Intenta nuevamente.',
          type: AlertType.error,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
      if (mounted) {
        AlertHelper.showAlert(
          'Error obteniendo ubicación. Verifica tu conexión.',
          type: AlertType.error,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
      }
    }
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
    if (!_isFormValid) return;

    //* debug prints…
    // debugPrint('──> _selectedCalle:      $_selectedCalle');
    // debugPrint('──> _manualCalleCtrl.text: "${_manualCalleCtrl.text}"');
    // debugPrint('──> isManualCalle:       $_isManualCalle');

    //* Usa el getter _isManualCalle en lugar de comparar con '__OTRA__'
    final String calleFinal = _isManualCalle
        ? _manualCalleCtrl.text.trim()
        : (_selectedCalle!.trim());

    final datosDireccion = [
      _cpCtrl.text.trim(),
      _isManualColonia
          ? _manualComunidadCtrl.text.trim()
          : (_selectedColonia!.trim()),
      calleFinal,
      _numExtCtrl.text.trim(),
      _numIntCtrl.text.trim(),
      _pickedLocation?.latitude.toString() ?? '',
      _pickedLocation?.longitude.toString() ?? '',
    ];

    debugPrint('→ calle a enviar (datosDireccion[2]): "$calleFinal"');

    final datosPersonales =
        ModalRoute.of(context)!.settings.arguments as List<String>;
    final datosCompletos = [...datosPersonales, ...datosDireccion];

    Navigator.pushNamed(
      context,
      '/contact-moral',
      arguments: datosCompletos,
    );
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
                    _sectionHeader(
                        Icons.corporate_fare, 'Dirección de la Empresa'),
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
                            'Código Postal', Icons.markunread_mailbox),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(5),
                        ],
                        validator: (v) =>
                            v != null && v.length == 5 ? null : '5 dígitos',
                        textInputAction: TextInputAction.next,
                        onChanged: (val) => _onCpChanged(val),
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
                                _pickedLocation = null;
                                _updateMapFromForm();
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
                                _numExtCtrl.clear();
                                _pickedLocation = null;
                                _updateMapFromForm();
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
                                validator: (v) => v == null || v.trim().isEmpty
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
                          validator: (v) => v == null || v.trim().isEmpty
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
                                  'Núm. ext.', Icons.confirmation_number),
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
                                  'Núm. int. (opcional)',
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
