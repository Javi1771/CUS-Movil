// services/citizen_registration_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CitizenRegistrationService {
  static const String _baseUrl =
      'https://www.sanjuandelrio.gob.mx/tramites-sjr/Api/principal';
  static const String _apiKey =
      '8f26cd375a2e57fde8052e127974779eace180135bb64d456176a6c7b399fa6e';

  /// Registra un ciudadano en la API
  static Future<Map<String, dynamic>> registerCitizen({
    required String nombre,
    required String primerApellido,
    required String segundoApellido,
    required String curpCiudadano,
    required String nombreCompleto,
    required String sexo,
    required String estado,
    required String fechaNacimiento,
    required String password,
    required bool aceptoTerminosCondiciones,
    required bool tipoAsentamiento,
    required String asentamiento,
    required String calle,
    required int numeroExterior,
    required int numeroInterior,
    required String codigoPostal,
    required String latitud,
    required String longitud,
    required String telefono,
    required String email,
    required bool tipoTelefono,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/insert_full_data_mobile');

      // Construir el JSON según el formato requerido
      final requestBody = {
        "nombre": nombre,
        "primer_apellido": primerApellido,
        "segundo_apellido": segundoApellido,
        "curp_ciudadano": curpCiudadano,
        "nombre_completo": nombreCompleto,
        "sexo": sexo,
        "estado": estado,
        "fecha_nacimiento": fechaNacimiento,
        "password": password,
        "acepto_terminos_condiciones": aceptoTerminosCondiciones ? 1 : 0,
        "tipo_asentamiento": tipoAsentamiento,
        "asentamiento": asentamiento,
        "calle": calle,
        "numero_exterior": numeroExterior,
        "numero_interior": numeroInterior,
        "codigo_postal": codigoPostal,
        "latitud": latitud,
        "longitud": longitud,
        "telefono": telefono,
        "email": email,
        "tipo_telefono": tipoTelefono,
      };

      if (kDebugMode) {
        print('[CitizenRegistrationService] 📤 Enviando datos a: $url');
        print(
            '[CitizenRegistrationService] 📋 Datos: ${jsonEncode(requestBody)}');
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
            '[CitizenRegistrationService] 📥 Status Code: ${response.statusCode}');
        print('[CitizenRegistrationService] 📥 Response: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
          'message': 'Ciudadano registrado exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': 'Error del servidor: ${response.statusCode}',
          'message': 'No se pudo registrar el ciudadano',
          'details': response.body,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('[CitizenRegistrationService] ❌ Error: $e');
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
          '[CitizenRegistrationService] 🔍 Mapeando ${formData.length} elementos:');
      print('[CitizenRegistrationService] === DATOS RECIBIDOS ===');
      for (int i = 0; i < formData.length; i++) {
        print('  [$i]: ${formData[i]}');
      }
      print('[CitizenRegistrationService] ========================');
    }

    final mappedData = {
      // Datos personales
      'curpCiudadano': formData.isNotEmpty ? formData[0] : '',
      'nombre': formData.length > 1 ? formData[2] : '',
      'primerApellido': formData.length > 2 ? formData[3] : '',
      'segundoApellido': formData.length > 3 ? formData[4] : '',
      'fechaNacimiento':
          formData.length > 4 ? _formatFechaNacimiento(formData[5]) : '',
      'sexo': formData.length > 5 ? formData[6] : '',
      'estado': formData.length > 6 ? formData[7] : '',
      'password': formData.length > 7 ? formData[8] : '',

      // Dirección
      'codigoPostal': formData.length > 8 ? formData[10] : '',
      'asentamiento': formData.length > 9 ? formData[11] : '',
      'calle': formData.length > 10 ? formData[12] : '',
      'numeroExterior':
          formData.length > 11 ? int.tryParse(formData[13]) ?? 0 : 0,
      'numeroInterior':
          formData.length > 12 ? int.tryParse(formData[14]) ?? 0 : 0,
      'latitud': formData.length > 13 ? formData[15] : '0.0',
      'longitud': formData.length > 14 ? formData[16] : '0.0',

      // Contacto
      'telefono': formData.length > 15 ? formData[20] : '',
      'email': formData.length > 16 ? formData[18] : '',

      // Campos calculados/por defecto
      'nombreCompleto': _buildNombreCompleto(formData),
      'aceptoTerminosCondiciones': true,
      'tipoAsentamiento': false,
      'tipoTelefono': true,
    };

    if (kDebugMode) {
      print('[CitizenRegistrationService] === DATOS MAPEADOS ===');
      mappedData.forEach((key, value) {
        if (kDebugMode) {
          print('  $key: $value');
        }
      });
      print('[CitizenRegistrationService] ========================');
    }

    return mappedData;
  }

  /// Construye el nombre completo a partir de los componentes
  static String _buildNombreCompleto(List<String> formData) {
    final nombre = formData.length > 1 ? formData[2] : '';
    final apellidoP = formData.length > 2 ? formData[3] : '';
    final apellidoM = formData.length > 3 ? formData[4] : '';

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
        print('[CitizenRegistrationService] ⚠️ Error formateando fecha: $e');
      }
      return fecha;
    }
  }

  /// Valida que todos los campos requeridos estén presentes
  static bool validateRequiredFields(Map<String, dynamic> data) {
    final requiredFields = [
      'nombre',
      'primerApellido',
      'curpCiudadano',
      'fechaNacimiento',
      'sexo',
      'estado',
      'password',
      'codigoPostal',
      'asentamiento',
      'calle',
      'telefono',
      'email',
    ];

    for (final field in requiredFields) {
      if (!data.containsKey(field) ||
          data[field] == null ||
          data[field].toString().trim().isEmpty) {
        if (kDebugMode) {
          print(
              '[CitizenRegistrationService] ❌ Campo requerido faltante: $field');
        }
        return false;
      }
    }

    return true;
  }

  /// Valida el formato del CURP
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
}
