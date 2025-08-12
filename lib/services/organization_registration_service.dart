// services/organization_registration_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class OrganizationRegistrationService {
  static const String _baseUrl =
      'https://www.sanjuandelrio.gob.mx/tramites-sjr/Api/principal';
  static const String _apiKey =
      '8f26cd375a2e57fde8052e127974779eace180135bb64d456176a6c7b399fa6e';

  /// Registra una organización en la API
  static Future<Map<String, dynamic>> registerOrganization({
    required String rfcOrganizacion,
    required String razonSocial,
    required String curpRepresentante,
    required String nombreRepresentante,
    required String primerApellidoRepresentante,
    required String segundoApellidoRepresentante,
    required String nombreCompletoRepresentante,
    required String fechaNacimientoRepresentante,
    required String sexoRepresentante,
    required String estadoRepresentante,
    required String password,
    required String asentamiento,
    required String calle,
    required String numeroExterior,
    required String numeroInterior,
    required String codigoPostal,
    required double latitud,
    required double longitud,
    required String telefono,
    required String email,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/insert_organizacion_mobile');

      // Construir el JSON según el formato requerido
      final requestBody = {
        "rfc_organizacion": rfcOrganizacion,
        "razon_social": razonSocial,
        "curp_representante": curpRepresentante,
        "nombre_representante": nombreRepresentante,
        "primer_apellido_representante": primerApellidoRepresentante,
        "segundo_apellido_representante": segundoApellidoRepresentante,
        "nombre_completo_representante": nombreCompletoRepresentante,
        "fecha_nacimiento_representante": fechaNacimientoRepresentante,
        "sexo_representante": sexoRepresentante,
        "estado_representante": estadoRepresentante,
        "password": password,
        "asentamiento": asentamiento,
        "calle": calle,
        "numero_exterior": numeroExterior,
        "numero_interior": numeroInterior,
        "codigo_postal": codigoPostal,
        "latitud": latitud,
        "longitud": longitud,
        "telefono": telefono,
        "email": email,
      };

      if (kDebugMode) {
        print('[OrganizationRegistrationService] 📤 Enviando datos a: $url');
        print(
            '[OrganizationRegistrationService] 📋 Datos: ${jsonEncode(requestBody)}');
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': _apiKey,
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (kDebugMode) {
        print(
            '[OrganizationRegistrationService] 📥 Status Code: ${response.statusCode}');
        print(
            '[OrganizationRegistrationService] 📥 Response: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
          'message': 'Organización registrada exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': 'Error del servidor: ${response.statusCode}',
          'message': 'No se pudo registrar la organización',
          'details': response.body,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('[OrganizationRegistrationService] ❌ Error: $e');
      }

      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error de conexión',
      };
    }
  }

  /// Convierte los datos del formulario al formato requerido por la API
  static Map<String, dynamic> formatDataForAPI(List<String> formData) {
    if (kDebugMode) {
      print(
          '[OrganizationRegistrationService] 🔍 Mapeando ${formData.length} elementos:');
      print('[OrganizationRegistrationService] === DATOS RECIBIDOS ===');
      for (int i = 0; i < formData.length; i++) {
        print('  [$i]: ${formData[i]}');
      }
      print('[OrganizationRegistrationService] ========================');
    }

    final mappedData = {
      // Datos de la organización
      'rfcOrganizacion': formData.isNotEmpty ? formData[0] : '',
      'razonSocial': formData.length > 1 ? formData[1] : '',

      // Datos del representante
      'curpRepresentante': formData.length > 2 ? formData[2] : '',
      'nombreRepresentante': formData.length > 3 ? formData[3] : '',
      'primerApellidoRepresentante': formData.length > 4 ? formData[4] : '',
      'segundoApellidoRepresentante': formData.length > 5 ? formData[5] : '',
      'fechaNacimientoRepresentante':
          formData.length > 6 ? _formatFechaNacimiento(formData[6]) : '',
      'sexoRepresentante': formData.length > 7 ? formData[7] : '',
      'estadoRepresentante': formData.length > 8 ? formData[8] : '',
      'password': formData.length > 9 ? formData[9] : '',

      // Dirección
      'codigoPostal': formData.length > 10 ? formData[10] : '',
      'asentamiento': formData.length > 11 ? formData[11] : '',
      'calle': formData.length > 12 ? formData[12] : '',
      'numeroExterior': formData.length > 13 ? formData[13] : '',
      'numeroInterior': formData.length > 14 ? formData[14] : 'S/N',
      'latitud':
          formData.length > 15 ? double.tryParse(formData[15]) ?? 0.0 : 0.0,
      'longitud':
          formData.length > 16 ? double.tryParse(formData[16]) ?? 0.0 : 0.0,

      // Contacto
      'telefono': formData.length > 17 ? formData[17] : '',
      'email': formData.length > 18 ? formData[18] : '',

      // Campos calculados
      'nombreCompletoRepresentante':
          _buildNombreCompletoRepresentante(formData),
    };

    if (kDebugMode) {
      print('[OrganizationRegistrationService] === DATOS MAPEADOS ===');
      mappedData.forEach((key, value) {
        if (kDebugMode) {
          print('  $key: $value');
        }
      });
      print('[OrganizationRegistrationService] ========================');
    }

    return mappedData;
  }

  /// Construye el nombre completo del representante a partir de los componentes
  static String _buildNombreCompletoRepresentante(List<String> formData) {
    final nombre = formData.length > 3 ? formData[3] : '';
    final apellidoP = formData.length > 4 ? formData[4] : '';
    final apellidoM = formData.length > 5 ? formData[5] : '';

    return '$nombre $apellidoP $apellidoM'.trim();
  }

  /// Formatea la fecha de nacimiento al formato requerido (YYYY-MM-DD)
  static String _formatFechaNacimiento(String fecha) {
    try {
      // Si ya está en formato YYYY-MM-DD, devolverla tal como está
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(fecha)) {
        return fecha;
      }

      // Si está en formato DD/MM/YYYY, convertirla
      if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(fecha)) {
        final parts = fecha.split('/');
        return '${parts[2]}-${parts[1]}-${parts[0]}';
      }

      // Si no coincide con ningún formato esperado, devolver tal como está
      return fecha;
    } catch (e) {
      if (kDebugMode) {
        print(
            '[OrganizationRegistrationService] ⚠️ Error formateando fecha: $e');
      }
      return fecha;
    }
  }

  /// Valida que todos los campos requeridos estén presentes
  static bool validateRequiredFields(Map<String, dynamic> data) {
    final requiredFields = [
      'rfcOrganizacion',
      'razonSocial',
      'curpRepresentante',
      'nombreRepresentante',
      'primerApellidoRepresentante',
      'fechaNacimientoRepresentante',
      'sexoRepresentante',
      'estadoRepresentante',
      'password',
      'codigoPostal',
      'asentamiento',
      'calle',
      'numeroExterior',
      'telefono',
      'email',
    ];

    for (final field in requiredFields) {
      if (!data.containsKey(field) ||
          data[field] == null ||
          data[field].toString().trim().isEmpty) {
        if (kDebugMode) {
          print(
              '[OrganizationRegistrationService] ❌ Campo requerido faltante: $field');
        }
        return false;
      }
    }

    return true;
  }

  /// Valida el formato del RFC
  static bool validateRFC(String rfc) {
    // RFC puede ser de persona moral (12 caracteres) o física (13 caracteres)
    if (rfc.length != 12 && rfc.length != 13) return false;

    // Patrón básico del RFC
    final rfcPattern = RegExp(r'^[A-Z&Ñ]{3,4}[0-9]{6}[A-Z0-9]{3}$');
    return rfcPattern.hasMatch(rfc.toUpperCase());
  }

  /// Valida el formato del CURP del representante
  static bool validateCURP(String curp) {
    // CURP debe tener 18 caracteres
    if (curp.length != 18) return false;

    // Patrón básico del CURP
    final curpPattern = RegExp(r'^[A-Z]{4}[0-9]{6}[HM][A-Z]{5}[0-9A-Z][0-9]$');
    return curpPattern.hasMatch(curp.toUpperCase());
  }

  /// Valida el formato del email
  static bool validateEmail(String email) {
    final emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailPattern.hasMatch(email);
  }

  /// Valida el formato del teléfono
  static bool validatePhone(String phone) {
    // Acepta números de 10 dígitos
    final phonePattern = RegExp(r'^[0-9]{10}$');
    return phonePattern.hasMatch(phone);
  }

  /// Valida el código postal
  static bool validatePostalCode(String postalCode) {
    // Código postal mexicano de 5 dígitos
    final postalPattern = RegExp(r'^[0-9]{5}$');
    return postalPattern.hasMatch(postalCode);
  }

  /// Valida las coordenadas de latitud y longitud
  static bool validateCoordinates(double latitud, double longitud) {
    // Validar rangos básicos para México
    // Latitud: aproximadamente entre 14° y 33° Norte
    // Longitud: aproximadamente entre -87° y -118° Oeste
    return latitud >= 14.0 &&
        latitud <= 33.0 &&
        longitud >= -118.0 &&
        longitud <= -87.0;
  }
}
