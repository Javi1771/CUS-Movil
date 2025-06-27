import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';
import '../models/usuario_cus.dart';

class UserDataService {
  static final String _apiUrl = dotenv.env['API_URL']!;
  static final String _apiKey = dotenv.env['API_KEY']!;

  /// Obtiene los datos del usuario desde la API
  static Future<UsuarioCUS?> getUserData() async {
    final token = await AuthService.getToken();
    if (token == null) {
      debugPrint('[UserDataService] No hay token de autenticación');
      throw Exception('Usuario no autenticado');
    }

    try {
      debugPrint('[UserDataService] Obteniendo datos del usuario...');

      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'X-API-KEY': _apiKey,
            },
            body: jsonEncode({
              'action': 'getUserData',
              'token': token,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Tiempo de espera agotado'),
          );

      debugPrint('[UserDataService] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return _parseUserResponse(response.body);
      } else if (response.statusCode == 401) {
        await _clearInvalidToken();
        throw Exception('Sesión expirada. Por favor inicia sesión nuevamente');
      } else {
        throw _handleErrorResponse(response);
      }
    } on SocketException {
      throw Exception('Error de conexión. Verifica tu internet');
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Intenta nuevamente');
    } catch (e) {
      debugPrint('[UserDataService] Error: $e');
      throw Exception('Error al obtener datos del perfil');
    }
  }

  static UsuarioCUS _parseUserResponse(String responseBody) {
    final data = jsonDecode(responseBody);
    debugPrint('[UserDataService] Response data: $data');

    Map<String, dynamic>? userData = _extractUserData(data);
    if (userData == null) {
      throw Exception('Estructura de respuesta no válida');
    }

    _validateProfileData(userData);

    try {
      return UsuarioCUS.fromJson(userData);
    } catch (e) {
      debugPrint('[UserDataService] Error parsing user: $e');
      return _createMinimalUser(userData);
    }
  }

  static Map<String, dynamic>? _extractUserData(Map<String, dynamic> data) {
    final possibleKeys = ['data', 'user', 'usuario', 'result', 'payload'];

    // Caso 1: Datos directamente en el nivel raíz
    if (data.containsKey('nombre') ||
        data.containsKey('curp') ||
        data.containsKey('email')) {
      return data;
    }

    // Caso 2: Datos en una propiedad anidada
    for (final key in possibleKeys) {
      if (data[key] != null && data[key] is Map<String, dynamic>) {
        return data[key];
      }
    }

    return null;
  }

  static void _validateProfileData(Map<String, dynamic> userData) {
    final tipoPerfil = userData['tipoPerfil']?.toString().toLowerCase();

    if (tipoPerfil == 'ciudadano' && userData['folio'] == null) {
      debugPrint('[UserDataService] Advertencia: Ciudadano sin folio');
    }

    if (tipoPerfil == 'trabajador' && userData['nomina'] == null) {
      debugPrint('[UserDataService] Advertencia: Trabajador sin nómina');
    }
  }

  static Exception _handleErrorResponse(http.Response response) {
    debugPrint('[UserDataService] Error HTTP: ${response.statusCode}');

    try {
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['message'] ??
          errorData['error'] ??
          'Error del servidor (${response.statusCode})';
      return Exception(errorMessage);
    } catch (e) {
      return Exception('Error del servidor (${response.statusCode})');
    }
  }

  static UsuarioCUS _createMinimalUser(Map<String, dynamic> data) {
    debugPrint('[UserDataService] Creando usuario con datos mínimos');

    // Determinar tipo de perfil
    TipoPerfilCUS tipoPerfil = _determineProfileType(data);

    return UsuarioCUS(
      nombre: _getField(data, ['nombre', 'name', 'username'], 'Usuario') ??
          'Usuario',
      email: _getField(
              data, ['email', 'correo', 'mail'], 'sin-email@ejemplo.com') ??
          'sin-email@ejemplo.com',
      curp: _getField(data, ['curp', 'CURP'], 'Sin CURP') ?? 'Sin CURP',
      usuarioId: _getField(data, ['id', 'usuario_id', 'userId'], 'temp-id'),
      nombreCompleto:
          _getField(data, ['nombreCompleto', 'nombre_completo', 'fullName']),
      telefono: _getField(data, ['telefono', 'phone', 'celular']),
      fechaNacimiento:
          _getField(data, ['fechaNacimiento', 'fecha_nacimiento', 'birthDate']),
      estadoCivil:
          _getField(data, ['estadoCivil', 'estado_civil', 'maritalStatus']),
      calle: _getField(data, ['calle', 'direccion', 'address']),
      asentamiento:
          _getField(data, ['asentamiento', 'colonia', 'neighborhood']),
      codigoPostal:
          _getField(data, ['codigoPostal', 'codigo_postal', 'cp', 'zipCode']),
      ocupacion: _getField(data, ['ocupacion', 'trabajo', 'job']),
      razonSocial: _getField(
          data, ['razonSocial', 'razon_social', 'empresa', 'company']),
      tipoPerfil: tipoPerfil,
      folio: data['folio']?.toString(),
      nomina: data['nomina']?.toString(),
    );
  }

  static TipoPerfilCUS _determineProfileType(Map<String, dynamic> data) {
    if (data['tipoPerfil'] != null) {
      try {
        return TipoPerfilCUS.values.firstWhere(
          (e) =>
              e.toString().split('.').last.toLowerCase() ==
              data['tipoPerfil'].toString().toLowerCase(),
          orElse: () => TipoPerfilCUS.usuario,
        );
      } catch (e) {
        debugPrint('[UserDataService] Error al determinar tipoPerfil: $e');
      }
    }

    if (data['folio'] != null) return TipoPerfilCUS.ciudadano;
    if (data['nomina'] != null) return TipoPerfilCUS.trabajador;
    if (data['razonSocial'] != null) return TipoPerfilCUS.personaMoral;

    return TipoPerfilCUS.usuario;
  }

  static String? _getField(Map<String, dynamic> data, List<String> possibleKeys,
      [String? defaultValue]) {
    for (final key in possibleKeys) {
      if (data[key] != null && data[key].toString().isNotEmpty) {
        return data[key].toString();
      }
    }
    return defaultValue;
  }

  /// Actualiza los datos del usuario en la API
  static Future<bool> updateUserData(UsuarioCUS usuario) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'X-API-KEY': _apiKey,
            },
            body: jsonEncode({
              'action': 'updateUserData',
              'token': token,
              'data': usuario.toJson(),
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true || data['status'] == 'success') {
          return true;
        } else {
          throw Exception(data['message'] ?? 'Error al actualizar datos');
        }
      } else if (response.statusCode == 401) {
        await _clearInvalidToken();
        throw Exception('Sesión expirada. Por favor inicia sesión nuevamente');
      } else {
        throw _handleErrorResponse(response);
      }
    } catch (e) {
      debugPrint('[UserDataService] Error en updateUserData: $e');
      rethrow;
    }
  }

  /// Método helper para limpiar tokens inválidos
  static Future<void> _clearInvalidToken() async {
    try {
      final authService = AuthService('temp');
      await authService.logout();
      debugPrint('[UserDataService] Token inválido limpiado');
    } catch (e) {
      debugPrint('[UserDataService] Error al limpiar token: $e');
    }
  }

  static Future uploadDocument(String tipo, String s) async {}

  static Future getUserDocuments() async {}

  // ... (otros métodos como uploadDocument, getUserDocuments pueden permanecer igual)
}
