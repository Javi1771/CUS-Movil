import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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
        '[UserDataService] ID Usuario General: ${userData['id_general']}');
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
      'id_general',
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
      nombre_completo:
          _getField(data, ['nombre_completo', 'nombre_completo', 'fullName']),
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
        'id_general',
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
      'id_general',
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

  static Future<Map<String, dynamic>> uploadDocument(
      String tipo, String filePath) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Archivo no encontrado');
    }
    if (!filePath.toLowerCase().endsWith('.pdf')) {
      throw Exception('Solo se permiten archivos PDF');
    }

    try {
      final uri = Uri.parse(_apiUrl);
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'X-API-KEY': _apiKey,
        })
        ..fields['action'] = 'uploadUserDocument'
        ..fields['token'] = token
        ..fields['tipo'] = tipo;

      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : 'documento.pdf',
        contentType: MediaType('application', 'pdf'),
      );
      request.files.add(multipartFile);

      final streamed =
          await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final success = data['success'] == true || data['status'] == 'success';
        if (!success) {
          throw Exception(
              data['message']?.toString() ?? 'Error al subir documento');
        }

        // Intentar obtener la URL del documento desde varias claves comunes
        final url = (data['url']?.toString() ??
                data['secure_url']?.toString() ??
                data['urlDocumento']?.toString() ??
                data['public_url']?.toString() ??
                data['link']?.toString() ??
                data['file_url']?.toString() ??
                data['data']?['url']?.toString() ??
                data['data']?['secure_url']?.toString() ??
                '')
            .trim();

        if (url.isEmpty) {
          throw Exception('La API no devolvió una URL del documento');
        }

        final defaultName = file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : 'documento.pdf';
        final nombre = (data['nombre'] ??
                data['fileName'] ??
                data['original_filename'] ??
                defaultName)
            .toString();

        return {'success': true, 'url': url, 'name': nombre};
      } else if (response.statusCode == 401) {
        await _clearInvalidToken();
        throw Exception('Sesión expirada. Por favor inicia sesión nuevamente');
      } else {
        throw _handleErrorResponse(response);
      }
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado al subir el documento');
    } catch (e) {
      debugPrint('[UserDataService] Error en uploadDocument: $e');
      rethrow;
    }
  }

  /// MÉTODO MEJORADO PARA CLOUDINARY: Obtiene los documentos del usuario
  static Future<List<DocumentoCUS>> getUserDocuments() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      debugPrint('[UserDataService] 📄 Obteniendo documentos del usuario...');

      // Intentar primero con acción específica para documentos
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'X-API-KEY': _apiKey,
            },
            body: jsonEncode({
              'action': 'getUserDocuments',
              'token': token,
            }),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint(
          '[UserDataService] 📄 Documentos - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[UserDataService] 📄 Respuesta completa: $data');

        List<dynamic> documentosData = [];

        // Buscar documentos en múltiples ubicaciones posibles
        final possiblePaths = [
          data['documentos'],
          data['documents'],
          data['files'],
          data['data']?['documentos'],
          data['data']?['documents'],
          data['data']?['files'],
          data['result']?['documentos'],
          data['result']?['documents'],
          data['payload']?['documentos'],
          data['payload']?['documents'],
          data['cloudinary']?['resources'],
          data['resources'],
        ];

        for (final path in possiblePaths) {
          if (path != null && path is List && path.isNotEmpty) {
            documentosData = path;
            debugPrint(
                '[UserDataService] 📄 Documentos encontrados en ruta: ${path.length} documentos');
            break;
          }
        }

        // Si no se encontraron documentos con la acción específica, intentar getUserData
        if (documentosData.isEmpty) {
          debugPrint(
              '[UserDataService] 📄 No se encontraron documentos con getUserDocuments, intentando getUserData...');

          final userResponse = await http
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
              .timeout(const Duration(seconds: 15));

          if (userResponse.statusCode == 200) {
            final userData = jsonDecode(userResponse.body);
            debugPrint('[UserDataService] 📄 Respuesta getUserData: $userData');

            final extractedUserData = _extractUserData(userData);
            if (extractedUserData != null) {
              final userDocsPaths = [
                extractedUserData['documentos'],
                extractedUserData['documents'],
                extractedUserData['files'],
              ];

              for (final path in userDocsPaths) {
                if (path != null && path is List && path.isNotEmpty) {
                  documentosData = path;
                  debugPrint(
                      '[UserDataService] 📄 Documentos encontrados en userData: ${path.length} documentos');
                  break;
                }
              }
            }
          }
        }

        debugPrint(
            '[UserDataService] 📄 Total documentos encontrados: ${documentosData.length}');

        if (documentosData.isEmpty) {
          debugPrint(
              '[UserDataService] 📄 ⚠️ No se encontraron documentos en ninguna ubicación');
          return [];
        }

        // Procesar cada documento
        final documentosProcesados = <DocumentoCUS>[];

        for (int i = 0; i < documentosData.length; i++) {
          final doc = documentosData[i];
          debugPrint('[UserDataService] 📄 Procesando documento $i: $doc');

          try {
            final documentoProcesado =
                DocumentoCUS.fromJson(doc as Map<String, dynamic>);
            documentosProcesados.add(documentoProcesado);
            debugPrint(
                '[UserDataService] 📄 ✅ Documento procesado: ${documentoProcesado.nombreDocumento} -> ${documentoProcesado.urlDocumento}');
          } catch (e) {
            debugPrint(
                '[UserDataService] 📄 ❌ Error parseando documento $i: $e');
            debugPrint('[UserDataService] 📄 Documento problemático: $doc');

            // Intentar crear documento manualmente con campos básicos
            try {
              final documentoManual = DocumentoCUS(
                nombreDocumento: doc['nombre']?.toString() ??
                    doc['name']?.toString() ??
                    doc['nombreDocumento']?.toString() ??
                    doc['filename']?.toString() ??
                    doc['original_filename']?.toString() ??
                    'Documento ${i + 1}',
                urlDocumento: doc['url']?.toString() ??
                    doc['urlDocumento']?.toString() ??
                    doc['secure_url']?.toString() ??
                    doc['public_url']?.toString() ??
                    doc['link']?.toString() ??
                    doc['file_url']?.toString() ??
                    '',
                uploadDate: doc['fecha']?.toString() ??
                    doc['uploadDate']?.toString() ??
                    doc['created_at']?.toString() ??
                    doc['timestamp']?.toString(),
              );

              if (documentoManual.urlDocumento.isNotEmpty) {
                documentosProcesados.add(documentoManual);
                debugPrint(
                    '[UserDataService] 📄 ✅ Documento manual creado: ${documentoManual.nombreDocumento}');
              } else {
                debugPrint(
                    '[UserDataService] 📄 ❌ Documento sin URL válida, omitiendo');
              }
            } catch (e2) {
              debugPrint(
                  '[UserDataService] 📄 ❌ Error creando documento manual: $e2');
            }
          }
        }

        debugPrint(
            '[UserDataService] 📄 🎯 Total documentos procesados exitosamente: ${documentosProcesados.length}');
        return documentosProcesados;
      } else if (response.statusCode == 401) {
        await _clearInvalidToken();
        throw Exception('Sesión expirada. Por favor inicia sesión nuevamente');
      } else {
        debugPrint(
            '[UserDataService] 📄 ❌ Error HTTP: ${response.statusCode} - ${response.body}');
        throw _handleErrorResponse(response);
      }
    } on SocketException {
      throw Exception('Error de conexión. Verifica tu internet');
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Intenta nuevamente');
    } catch (e) {
      debugPrint('[UserDataService] 📄 ❌ Error obteniendo documentos: $e');
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

  static Future<void> deleteDocument(String tipo, {String? id}) async {}
}
