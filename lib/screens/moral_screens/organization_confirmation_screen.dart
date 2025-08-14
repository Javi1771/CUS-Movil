// screens/organization_screens/organization_confirmation_screen.dart

import 'package:flutter/material.dart';
import '../../services/organization_registration_service.dart';
import '../../widgets/steap_header.dart';

class OrganizationConfirmationScreen extends StatefulWidget {
  const OrganizationConfirmationScreen({super.key});

  @override
  State<OrganizationConfirmationScreen> createState() =>
      _OrganizationConfirmationScreenState();
}

class _OrganizationConfirmationScreenState
    extends State<OrganizationConfirmationScreen>
    with SingleTickerProviderStateMixin {
  static const successColor = Color(0xFF059669);
  static const errorColor = Color(0xFFDC2626);
  static const organizationColor =
      Color(0xFF7C3AED); // Púrpura para organizaciones

  bool _isLoading = false;
  bool _isSuccess = false;
  String _message = '';
  String _errorDetails = '';

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    // Iniciar el registro automáticamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _submitRegistration();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    setState(() {
      _isLoading = true;
      _isSuccess = false;
    });

    try {
      // Obtener los datos del formulario
      final List<String> formData =
          ModalRoute.of(context)!.settings.arguments as List<String>;

      // Formatear los datos para la API
      final apiData =
          OrganizationRegistrationService.formatDataForAPI(formData);

      // Validar campos requeridos
      if (!OrganizationRegistrationService.validateRequiredFields(apiData)) {
        throw Exception('Faltan campos requeridos para el registro');
      }

      // Validaciones adicionales específicas para organizaciones
      if (!OrganizationRegistrationService.validateRFC(
          apiData['rfcOrganizacion'])) {
        throw Exception('El RFC de la organización no tiene un formato válido');
      }

      if (!OrganizationRegistrationService.validateCURP(
          apiData['curpRepresentante'])) {
        throw Exception('El CURP del representante no tiene un formato válido');
      }

      if (!OrganizationRegistrationService.validateEmail(apiData['email'])) {
        throw Exception('El email ingresado no tiene un formato válido');
      }

      if (!OrganizationRegistrationService.validatePhone(apiData['telefono'])) {
        throw Exception('El teléfono debe tener 10 dígitos');
      }

      if (!OrganizationRegistrationService.validatePostalCode(
          apiData['codigoPostal'])) {
        throw Exception('El código postal debe tener 5 dígitos');
      }

      // Validar coordenadas si están disponibles
      final latitud = apiData['latitud'] as double;
      final longitud = apiData['longitud'] as double;
      if (latitud != 0.0 && longitud != 0.0) {
        if (!OrganizationRegistrationService.validateCoordinates(
            latitud, longitud)) {
          throw Exception(
              'Las coordenadas proporcionadas no son válidas para México');
        }
      }

      // Enviar el registro
      final result = await OrganizationRegistrationService.registerOrganization(
        rfcOrganizacion: apiData['rfcOrganizacion'],
        razonSocial: apiData['razonSocial'],
        curpRepresentante: apiData['curpRepresentante'],
        nombreRepresentante: apiData['nombreRepresentante'],
        primerApellidoRepresentante: apiData['primerApellidoRepresentante'],
        segundoApellidoRepresentante: apiData['segundoApellidoRepresentante'],
        nombreCompletoRepresentante: apiData['nombreCompletoRepresentante'],
        fechaNacimientoRepresentante: apiData['fechaNacimientoRepresentante'],
        sexoRepresentante: apiData['sexoRepresentante'],
        estadoRepresentante: apiData['estadoRepresentante'],
        password: apiData['password'],
        asentamiento: apiData['asentamiento'],
        calle: apiData['calle'],
        numeroExterior: apiData['numeroExterior'],
        numeroInterior: apiData['numeroInterior'],
        codigoPostal: apiData['codigoPostal'],
        latitud: apiData['latitud'],
        longitud: apiData['longitud'],
        telefono: apiData['telefono'],
        email: apiData['email'],
      );

      setState(() {
        _isLoading = false;
        if (result['success']) {
          _isSuccess = true;
          _message =
              result['message'] ?? 'Organización registrada exitosamente';
        } else {
          _message =
              result['message'] ?? 'Error en el registro de la organización';
          _errorDetails = result['error'] ?? '';
          if (result['details'] != null) {
            _errorDetails += '\n\nDetalles: ${result['details']}';
          }
        }
      });

      // Iniciar animación
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Error inesperado durante el registro';
        _errorDetails = e.toString();
      });

      _animationController.forward();
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: organizationColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: organizationColor,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Registrando organización...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: organizationColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Por favor espera mientras procesamos la información de tu organización',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: successColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '¡Organización Registrada!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: successColor,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Tu organización ya puede acceder a los servicios gubernamentales usando el RFC y contraseña registrados.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                // Navegar al login específico para organizaciones
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/organization-auth',
                  (route) => false,
                );
              },
              icon: const Icon(Icons.business, color: Colors.white),
              label: const Text(
                'Acceder como Organización',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: organizationColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: errorColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Error en el Registro',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: errorColor,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (_errorDetails.isNotEmpty) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text(
                  'Ver detalles del error',
                  style: TextStyle(fontSize: 14),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _errorDetails,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text(
                    'Volver',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _submitRegistration,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'Reintentar',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: organizationColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      body: Column(
        children: [
          const PasoHeader(
            pasoActual: 7,
            tituloPaso: 'Confirmación',
            tituloSiguiente: 'Completado',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _isLoading
                  ? _buildLoadingState()
                  : _isSuccess
                      ? _buildSuccessState()
                      : _buildErrorState(),
            ),
          ),
        ],
      ),
    );
  }
}
