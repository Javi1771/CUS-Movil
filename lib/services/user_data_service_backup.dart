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
            const Duration(seconds: 8), // Reduced timeout to prevent ANR
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

    debugPrint('[UserDataService] User data extracted: $userData');
    debugPrint('[UserDataService] Folio: ${userData['folio']}');
    debugPrint('[UserDataService] ID Ciudadano: ${userData['id_ciudadano']}');
    debugPrint(
        '[UserDataService] ID Usuario General: ${userData['id_usuario_general']}');
    debugPrint('[UserDataService] SubGeneral: ${userData['subGeneral']}');
    debugPrint('[UserDataService] Sub: ${userData['sub']}');
    debugPrint('[UserDataService] Nómina: ${userData['nomina']}');
    debugPrint('[UserDataService] no_nomina: ${userData['no_nomina']}');

    // Buscar todos los campos que podrían contener la nómina
    final nominaFields = ['no_nomina', 'nomina', 'nómina', 'numeroNomina'];
    for (final field in nominaFields) {
      if (userData[field] != null) {
        debugPrint(
            '[UserDataService] ✅ Campo nómina $field encontrado: ${userData[field]}');
      }
    }

    // Verificar el resultado final de _getField para nómina
    final nominaFinal =
        _getField(userData, ['no_nomina', 'nomina', 'nómina', 'numeroNomina']);
    debugPrint('[UserDataService] 🎯 Nómina final obtenida: $nominaFinal');

    // Buscar ID ciudadano en todos los campos posibles
    final possibleIdFields = [
      'id_ciudadano',
      'idCiudadano',
      'ciudadano_id',
      'id_usuario_general',
      'idUsuarioGeneral',
      'usuario_general_id',
      'subGeneral',
      'sub'
    ];

    for (final field in possibleIdFields) {
      if (userData[field] != null) {
        debugPrint(
            '[UserDataService] Campo $field encontrado: ${userData[field]}');
      }
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
      folio: _getField(data, ['folio', 'folioCUS', 'folio_cus']),
      nomina:
          _getField(data, ['no_nomina', 'nomina', 'nómina', 'numeroNomina']),
      idCiudadano: _getField(data, [
        'id_ciudadano',
        'idCiudadano',
        'ciudadano_id',
        'id_usuario_general',
        'idUsuarioGeneral',
        'usuario_general_id',
        'subGeneral',
        'sub'
      ]),
    );
  }

  static TipoPerfilCUS _determineProfileType(Map<String, dynamic> data) {
    // Buscar tipo de perfil explícito
    final tipoPerfilExplicito = _getField(data, [
      'tipoPerfil',
      'tipo_perfil',
      'tipoUsuario',
      'tipo_usuario',
      'userType',
      'user_type'
    ]);

    if (tipoPerfilExplicito != null) {
      try {
        switch (tipoPerfilExplicito.toLowerCase()) {
          case 'ciudadano':
          case 'persona_fisica':
          case 'fisica':
          case 'citizen':
            return TipoPerfilCUS.ciudadano;
          case 'trabajador':
          case 'employee':
          case 'worker':
            return TipoPerfilCUS.trabajador;
          case 'persona_moral':
          case 'moral':
          case 'empresa':
          case 'company':
            return TipoPerfilCUS.personaMoral;
          default:
            return TipoPerfilCUS.usuario;
        }
      } catch (e) {
        debugPrint('[UserDataService] Error al determinar tipoPerfil: $e');
      }
    }

    // Determinar por identificadores
    final folio = _getField(data, ['folio', 'folioCUS', 'folio_cus']);
    final nomina =
        _getField(data, ['no_nomina', 'nomina', 'nómina', 'numeroNomina']);

    if (folio != null) return TipoPerfilCUS.ciudadano;
    if (nomina != null) return TipoPerfilCUS.trabajador;

    // Verificar ID ciudadano
    final idCiudadano = _getField(data, [
      'id_ciudadano',
      'idCiudadano',
      'ciudadano_id',
      'id_usuario_general',
      'idUsuarioGeneral',
      'usuario_general_id',
      'subGeneral',
      'sub'
    ]);

    if (idCiudadano != null) return TipoPerfilCUS.ciudadano;

    // Verificar otros indicadores
    if (data['razonSocial'] != null) return TipoPerfilCUS.personaMoral;

    // Si tiene CURP, es persona física
    final curp = _getField(data, ['curp', 'CURP']);
    if (curp != null && curp.isNotEmpty && curp != 'Sin CURP') {
      return TipoPerfilCUS.ciudadano;
    }

    // Por defecto, asumir ciudadano
    return TipoPerfilCUS.ciudadano;
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

  static Future<List<DocumentoCUS>> getUserDocuments() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-API-KEY': _apiKey,
        },
        body: jsonEncode({
          // Ajusta el body según lo que espera tu API
          'action': 'getUserData',
          'token': token,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Ajusta la ruta según la estructura de tu respuesta
        final documentos = (data['data']?['documentos'] ?? []) as List;
        return documentos.map((doc) => DocumentoCUS.fromJson(doc)).toList();
      } else if (response.statusCode == 401) {
        await _clearInvalidToken();
        throw Exception('Sesión expirada. Por favor inicia sesión nuevamente');
      } else {
        throw _handleErrorResponse(response);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el resumen general del usuario (estadísticas y actividad reciente)
  static Future<Map<String, dynamic>> getResumenGeneral() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      debugPrint('[UserDataService] Obteniendo resumen general...');

      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'X-API-KEY': _apiKey,
            },
            body: jsonEncode({
              'action': 'getResumenGeneral',
              'token': token,
            }),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Tiempo de espera agotado'),
          );

      debugPrint(
          '[UserDataService] Resumen general - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[UserDataService] Resumen general obtenido: $data');

        // Validar estructura de respuesta
        if (data is Map<String, dynamic>) {
          return {
            'estadisticas': data['estadisticas'] ??
                {
                  'tramitesActivos': 0,
                  'pendientes': 0,
                  'porcentajeCompletados': 0.0,
                },
            'actividadReciente': data['actividadReciente'] ?? [],
          };
        } else {
          throw Exception('Estructura de respuesta no válida');
        }
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
      debugPrint('[UserDataService] Error obteniendo resumen general: $e');
      throw Exception('Error al obtener resumen general: $e');
    }
  }
}
