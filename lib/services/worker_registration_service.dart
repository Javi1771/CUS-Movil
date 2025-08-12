// services/worker_registration_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class WorkerRegistrationService {
  static const String _baseUrl =
      'https://www.sanjuandelrio.gob.mx/tramites-sjr/Api/principal';
  static const String _apiKey =
      '8f26cd375a2e57fde8052e127974779eace180135bb64d456176a6c7b399fa6e';

  /// Registra un trabajador en la API
  static Future<Map<String, dynamic>> registerWorker({
    required String nomina,
    required String departamento,
    required String puesto,
    required String sexo,
    required String estado,
    required String nombre,
    required String primerApellido,
    required String segundoApellido,
    required String curpTrabajador,
    required String nombreCompleto,
    required String fechaNacimiento,
    required String password,
    required bool aceptoTerminosCondiciones,
    required bool tipoAsentamiento,
    required String asentamiento,
    required String calle,
    required String numeroExterior,
    required String numeroInterior,
    required String codigoPostal,
    required String latitud,
    required String longitud,
    required String telefono,
    required String email,
    required bool tipoTelefono,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/insert_full_trabajador_data_mobile');

      // Construir el JSON según el formato requerido
      final requestBody = {
        "no_nomina": nomina,
        "departamento": departamento,
        "puesto": puesto,
        "sexo": sexo,
        "estado": estado,
        "nombre": nombre,
        "primer_apellido": primerApellido,
        "segundo_apellido": segundoApellido,
        "curp_trabajador": curpTrabajador,
        "nombre_completo": nombreCompleto,
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
        print('[WorkerRegistrationService] 📤 Enviando datos a: $url');
        print(
            '[WorkerRegistrationService] 📋 Datos: ${jsonEncode(requestBody)}');
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
            '[WorkerRegistrationService] 📥 Status Code: ${response.statusCode}');
        print('[WorkerRegistrationService] 📥 Response: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
          'message': 'Trabajador registrado exitosamente',
        };
      } else {
        // Detectar errores de duplicado de correo o contraseña y estandarizar respuesta
        final body = response.body;
        final lower = body.toLowerCase();
        String? errorCode;
        String message = 'No se pudo registrar el trabajador';

        // Detección heurística por código de estado o texto en la respuesta
        final isDuplicateEmail =
            response.statusCode == 409 && lower.contains('email') ||
            lower.contains('ya existe') && (lower.contains('correo') || lower.contains('email')) ||
            lower.contains('duplic') && (lower.contains('correo') || lower.contains('email'));

        final isDuplicatePassword =
            response.statusCode == 409 && (lower.contains('password') || lower.contains('contrase')) ||
            lower.contains('ya existe') && (lower.contains('password') || lower.contains('contrase')) ||
            lower.contains('duplic') && (lower.contains('password') || lower.contains('contrase'));

        if (isDuplicateEmail) {
          errorCode = 'duplicate_email';
          message = 'El correo ya está registrado. Por favor usa otro correo.';
        } else if (isDuplicatePassword) {
          errorCode = 'duplicate_password';
          message = 'La contraseña ya está en uso. Elige una diferente.';
        } else {
          // Intentar extraer mensaje del JSON si está disponible
          try {
            final data = jsonDecode(body);
            if (data is Map && data['message'] is String) {
              message = data['message'];
            }
          } catch (_) {}
          errorCode = 'http_${response.statusCode}';
        }

        return {
          'success': false,
          'error': errorCode,
          'message': message,
          'details': body,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('[WorkerRegistrationService] ❌ Error: $e');
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
          '[WorkerRegistrationService] 🔍 Mapeando ${formData.length} elementos:');
      print('[WorkerRegistrationService] === DATOS RECIBIDOS ===');
      for (int i = 0; i < formData.length; i++) {
        print('  [$i]: ${formData[i]}');
      }
      print('[WorkerRegistrationService] ========================');
    }

    final mappedData = {
      // Datos del trabajador
      'nomina': formData.isNotEmpty ? formData[0] : '',
      'puesto': formData.length > 1 ? formData[1] : '',
      'departamento': formData.length > 2 ? formData[2] : '',

      // Datos personales
      'curpTrabajador': formData.length > 3 ? formData[3] : '',
      'nombre': formData.length > 5 ? formData[5] : '',
      'primerApellido': formData.length > 6 ? formData[6] : '',
      'segundoApellido': formData.length > 7 ? formData[7] : '',
      'fechaNacimiento':
          formData.length > 8 ? _formatFechaNacimiento(formData[8]) : '',
      'sexo': formData.length > 9 ? formData[9] : '',
      'estado': formData.length > 10 ? formData[10] : '',
      'password': formData.length > 11 ? formData[11] : '',

      // Dirección
      'codigoPostal': formData.length > 13 ? formData[13] : '',
      'asentamiento': formData.length > 14 ? formData[14] : '',
      'calle': formData.length > 15 ? formData[15] : '',
      'numeroExterior': formData.length > 16 ? formData[16] : '',
      'numeroInterior': formData.length > 17 ? formData[17] : 'S/N',
      'latitud': formData.length > 18 ? formData[18] : '0.0',
      'longitud': formData.length > 19 ? formData[19] : '0.0',

      // Contacto
      'email': formData.length > 20 ? formData[20] : '',
      'telefono': formData.length > 22 ? formData[22] : '',

      // Campos calculados/por defecto
      'nombreCompleto': _buildNombreCompleto(formData),
      'aceptoTerminosCondiciones': true,
      'tipoAsentamiento': false,
      'tipoTelefono': true,
    };

    if (kDebugMode) {
      print('[WorkerRegistrationService] === DATOS MAPEADOS ===');
      mappedData.forEach((key, value) {
        if (kDebugMode) {
          print('  $key: $value');
        }
      });
      print('[WorkerRegistrationService] ========================');
    }

    return mappedData;
  }

  /// Construye el nombre completo a partir de los componentes
  static String _buildNombreCompleto(List<String> formData) {
    final nombre = formData.length > 5 ? formData[5] : '';
    final apellidoP = formData.length > 6 ? formData[6] : '';
    final apellidoM = formData.length > 7 ? formData[7] : '';

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
        print('[WorkerRegistrationService] ⚠️ Error formateando fecha: $e');
      }
      return fecha;
    }
  }

  /// Valida que todos los campos requeridos estén presentes
  static bool validateRequiredFields(Map<String, dynamic> data) {
    final requiredFields = [
      'nomina',
      'departamento',
      'puesto',
      'nombre',
      'primerApellido',
      'curpTrabajador',
      'fechaNacimiento',
      'password',
      'codigoPostal',
      'asentamiento',
      'calle',
      'telefono',
    ];

    for (final field in requiredFields) {
      if (!data.containsKey(field) ||
          data[field] == null ||
          data[field].toString().trim().isEmpty) {
        if (kDebugMode) {
          print(
              '[WorkerRegistrationService] ❌ Campo requerido faltante: $field');
        }
        return false;
      }
    }

    return true;
  }
}
