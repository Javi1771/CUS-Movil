import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class TramiteEstado {
  final int idCentralTram;
  final int idCatalogoTramite;
  final int idDependencia;
  final int idTramite;
  final int idSolicitante;
  final int idEstado;
  final DateTime fechaEntrada;
  final DateTime? fechaSalida;
  final String folio;
  final DateTime fechaCreacion;
  final int? idFirmante;
  final int? idRevisor;
  final DateTime ultimaFechaModificacion;
  final String nombreTramite;
  final String nombreDependencia;
  final String nombreEstado;

  TramiteEstado({
    required this.idCentralTram,
    required this.idCatalogoTramite,
    required this.idDependencia,
    required this.idTramite,
    required this.idSolicitante,
    required this.idEstado,
    required this.fechaEntrada,
    this.fechaSalida,
    required this.folio,
    required this.fechaCreacion,
    this.idFirmante,
    this.idRevisor,
    required this.ultimaFechaModificacion,
    required this.nombreTramite,
    required this.nombreDependencia,
    required this.nombreEstado,
  });

  factory TramiteEstado.fromJson(Map<String, dynamic> json) {
    try {
      return TramiteEstado(
        idCentralTram: json['id_central_tram'] ?? 0,
        idCatalogoTramite: json['id_catalogo_tramite'] ?? 0,
        idDependencia: json['id_dependencia'] ?? 0,
        idTramite: json['id_tramite'] ?? 0,
        idSolicitante: json['id_solicitante'] ?? 0,
        idEstado: json['id_estado'] ?? 0,
        fechaEntrada: _parseDateTime(json['fecha_entrada']),
        fechaSalida: json['fecha_salida'] != null
            ? _parseDateTime(json['fecha_salida'])
            : null,
        folio: json['folio']?.toString() ?? '',
        fechaCreacion: _parseDateTime(json['fecha_creacion']),
        idFirmante: json['id_firmante'],
        idRevisor: json['id_revisor'],
        ultimaFechaModificacion:
            _parseDateTime(json['ultima_fecha_modificacion']),
        nombreTramite: json['nombre_tramite']?.toString() ?? '',
        nombreDependencia: json['nombre_dependencia']?.toString() ?? '',
        nombreEstado: json['nombre_estado']?.toString() ?? '',
      );
    } catch (e) {
      debugPrint('[TramiteEstado] Error parsing JSON: $e');
      debugPrint('[TramiteEstado] JSON data: $json');
      rethrow;
    }
  }

  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();

    try {
      if (dateValue is String) {
        return DateTime.parse(dateValue);
      } else if (dateValue is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      } else {
        return DateTime.now();
      }
    } catch (e) {
      debugPrint('[TramiteEstado] Error parsing date: $dateValue, error: $e');
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id_central_tram': idCentralTram,
      'id_catalogo_tramite': idCatalogoTramite,
      'id_dependencia': idDependencia,
      'id_tramite': idTramite,
      'id_solicitante': idSolicitante,
      'id_estado': idEstado,
      'fecha_entrada': fechaEntrada.toIso8601String(),
      'fecha_salida': fechaSalida?.toIso8601String(),
      'folio': folio,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'id_firmante': idFirmante,
      'id_revisor': idRevisor,
      'ultima_fecha_modificacion': ultimaFechaModificacion.toIso8601String(),
      'nombre_tramite': nombreTramite,
      'nombre_dependencia': nombreDependencia,
      'nombre_estado': nombreEstado,
    };
  }

  // Getter para obtener el color del estado
  Color get colorEstado {
    switch (nombreEstado.toUpperCase()) {
      case 'POR REVISAR':
        return const Color(0xFFFAA21B); // Naranja
      case 'FIRMADO':
        return const Color(0xFF00AE6F); // Verde
      case 'RECHAZADO':
        return const Color(0xFFCE1D81); // Magenta/Rojo
      case 'CORREGIR':
        return const Color(0xFFE67425); // Naranja oscuro
      case 'REQUIERE PAGO':
        return const Color(0xFF00B2E2); // Azul claro
      case 'ENVIADO PARA FIRMAR':
        return const Color(0xFFDF1783); // Magenta
      default:
        return const Color(0xFF085184); // Azul oscuro
    }
  }

  // Getter para obtener el icono del estado
  IconData get iconoEstado {
    switch (nombreEstado.toUpperCase()) {
      case 'POR REVISAR':
        return Icons.pending_actions;
      case 'FIRMADO':
        return Icons.check_circle;
      case 'RECHAZADO':
        return Icons.cancel;
      case 'CORREGIR':
        return Icons.edit;
      case 'REQUIERE PAGO':
        return Icons.payment;
      case 'ENVIADO PARA FIRMAR':
        return Icons.send;
      default:
        return Icons.help_outline;
    }
  }

  // Getter para obtener una descripción del estado
  String get descripcionEstado {
    switch (nombreEstado.toUpperCase()) {
      case 'POR REVISAR':
        return 'Su trámite está en proceso de revisión';
      case 'FIRMADO':
        return 'Su trámite ha sido completado y firmado';
      case 'RECHAZADO':
        return 'Su trámite ha sido rechazado';
      case 'CORREGIR':
        return 'Su trámite requiere correcciones';
      case 'REQUIERE PAGO':
        return 'Su trámite requiere realizar el pago correspondiente';
      case 'ENVIADO PARA FIRMAR':
        return 'Su trámite ha sido enviado para firma';
      default:
        return 'Estado del trámite';
    }
  }
}

class TramitesResponse {
  final bool success;
  final List<TramiteEstado> data;
  final int count;

  TramitesResponse({
    required this.success,
    required this.data,
    required this.count,
  });

  factory TramitesResponse.fromJson(Map<String, dynamic> json) {
    return TramitesResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => TramiteEstado.fromJson(item))
              .toList() ??
          [],
      count: json['count'] ?? 0,
    );
  }
}

class TramitesService {
  static const String _apiUrl =
      'https://sanjuandelrio.sytes.net:3023/api/external/estados_tramites';
  static const String _apiKey =
      '2437781c11461b35da0442057c708e39abf87c7860923fb9ab3ed73b6c6b3d05';

  /// Obtiene los estados de los trámites para un usuario específico
  static Future<TramitesResponse> getTramitesEstados() async {
    try {
      debugPrint('[TramitesService] Iniciando obtención de trámites...');

      // Obtener el id_general del usuario autenticado
      final userData = await _getUserData();
      final idGeneral = _extractIdGeneral(userData);

      if (idGeneral == null) {
        throw Exception(
            'No se pudo obtener el ID del usuario. Asegúrate de haber iniciado sesión correctamente.');
      }

      debugPrint('[TramitesService] Obteniendo trámites para ID: $idGeneral');
      debugPrint('[TramitesService] URL: $_apiUrl');
      debugPrint('[TramitesService] API Key: ${_apiKey.substring(0, 10)}...');

      final requestBody = jsonEncode({
        'id_solicitante': idGeneral,
      });

      debugPrint('[TramitesService] Request body: $requestBody');

      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-API-KEY': _apiKey,
            },
            body: requestBody,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Tiempo de espera agotado'),
          );

      debugPrint('[TramitesService] Status: ${response.statusCode}');
      debugPrint('[TramitesService] Response headers: ${response.headers}');
      debugPrint('[TramitesService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          debugPrint('[TramitesService] Parsed JSON: $data');
          return TramitesResponse.fromJson(data);
        } catch (e) {
          debugPrint('[TramitesService] Error parsing JSON: $e');
          throw Exception('Error al procesar la respuesta del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on SocketException catch (e) {
      debugPrint('[TramitesService] SocketException: $e');

      // Proporcionar información más detallada sobre el error de conexión
      if (e.message.contains('No route to host')) {
        throw Exception('No se puede conectar al servidor de trámites.\n\n'
            'Posibles causas:\n'
            '• El servidor no está disponible\n'
            '• No estás conectado a la red correcta\n'
            '• Problemas de conectividad\n\n'
            'Por favor, verifica tu conexión e intenta nuevamente.');
      } else if (e.message.contains('Connection refused')) {
        throw Exception('El servidor de trámites rechazó la conexión.\n'
            'El servicio podría estar temporalmente fuera de línea.');
      } else {
        throw Exception('Error de conexión: ${e.message}\n'
            'Verifica tu conexión a internet e intenta nuevamente.');
      }
    } on TimeoutException catch (e) {
      debugPrint('[TramitesService] TimeoutException: $e');
      throw Exception('Tiempo de espera agotado.\n'
          'El servidor está tardando mucho en responder.\n'
          'Intenta nuevamente en unos momentos.');
    } catch (e) {
      debugPrint('[TramitesService] Error general: $e');
      rethrow;
    }
  }

  /// Obtiene los datos del usuario autenticado
  static Future<Map<String, dynamic>> _getUserData() async {
    final authService = AuthService('temp');
    final userData = await authService.getUserData();

    if (userData == null) {
      throw Exception('Usuario no autenticado');
    }

    return userData;
  }

  /// Extrae el id_general de los datos del usuario basado en el tipo de perfil
  static String? _extractIdGeneral(Map<String, dynamic> userData) {
    debugPrint('[TramitesService] ===== EXTRAYENDO ID PARA TRÁMITES =====');
    debugPrint('[TramitesService] Datos del usuario completos: $userData');

    // Primero determinar el tipo de perfil del usuario
    final tipoPerfilExplicito = _getStringValue(userData, [
      'tipoPerfil', 
      'tipo_perfil', 
      'tipoUsuario', 
      'tipo_usuario',
      'userType',
      'user_type'
    ]);

    final folio = _getStringValue(userData, ['folio', 'folioCUS', 'folio_cus']);
    final nomina = _getStringValue(userData, ['no_nomina', 'nomina', 'nómina', 'numeroNomina']);

    debugPrint('[TramitesService] Tipo de perfil: $tipoPerfilExplicito');
    debugPrint('[TramitesService] Folio encontrado: $folio');
    debugPrint('[TramitesService] Nómina encontrada: $nomina');

    // Determinar si es trabajador
    bool esTrabajador = false;
    
    if (tipoPerfilExplicito != null) {
      esTrabajador = tipoPerfilExplicito.toLowerCase() == 'trabajador' ||
                     tipoPerfilExplicito.toLowerCase() == 'employee' ||
                     tipoPerfilExplicito.toLowerCase() == 'worker';
    } else if (nomina != null && nomina.isNotEmpty) {
      esTrabajador = true;
      debugPrint('[TramitesService] Detectado como trabajador por presencia de nómina');
    }

    debugPrint('[TramitesService] Es trabajador: $esTrabajador');

    // Si es trabajador, usar nómina como ID
    if (esTrabajador && nomina != null && nomina.isNotEmpty) {
      debugPrint('[TramitesService] ✅ USANDO NÓMINA COMO ID PARA TRABAJADOR: $nomina');
      return nomina;
    }

    // Si no es trabajador o no tiene nómina, buscar id_general tradicional
    debugPrint('[TramitesService] Buscando ID tradicional para ciudadano...');
    
    final possibleKeys = [
      'id_usuario_general', // ✅ Agregado: este es el campo que viene en la respuesta
      'id_general',
      'idGeneral',
      'subGeneral', // ✅ Agregado: también viene en el JWT
      'sub', // ✅ Agregado: campo del JWT
      'id',
      'user_id',
      'userId',
      'id_ciudadano',
      'idCiudadano',
      'folio',
    ];

    // Buscar en el nivel raíz
    for (final key in possibleKeys) {
      final value = userData[key];
      if (value != null &&
          value.toString().isNotEmpty &&
          value.toString() != 'null') {
        debugPrint('[TramitesService] ✅ ID encontrado en $key: $value');
        return value.toString();
      }
    }

    // Si no se encuentra en el nivel raíz, buscar en data anidada
    final data = userData['data'];
    if (data != null && data is Map<String, dynamic>) {
      debugPrint('[TramitesService] Buscando en data anidada: $data');
      for (final key in possibleKeys) {
        final value = data[key];
        if (value != null &&
            value.toString().isNotEmpty &&
            value.toString() != 'null') {
          debugPrint('[TramitesService] ✅ ID encontrado en data.$key: $value');
          return value.toString();
        }
      }
    }

    // Buscar en user anidado
    final user = userData['user'];
    if (user != null && user is Map<String, dynamic>) {
      debugPrint('[TramitesService] Buscando en user anidado: $user');
      for (final key in possibleKeys) {
        final value = user[key];
        if (value != null &&
            value.toString().isNotEmpty &&
            value.toString() != 'null') {
          debugPrint('[TramitesService] ✅ ID encontrado en user.$key: $value');
          return value.toString();
        }
      }
    }

    // No se encontró el ID del usuario
    debugPrint('[TramitesService] ❌ No se pudo encontrar ID en los datos del usuario');
    return null;
  }

  /// Función helper para obtener valores de múltiples claves posibles
  static String? _getStringValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null &&
          value.toString().trim().isNotEmpty &&
          value.toString() != 'null') {
        return value.toString().trim();
      }
    }

    // También buscar en data anidada
    final data = json['data'];
    if (data != null && data is Map<String, dynamic>) {
      for (final key in keys) {
        final value = data[key];
        if (value != null &&
            value.toString().trim().isNotEmpty &&
            value.toString() != 'null') {
          return value.toString().trim();
        }
      }
    }

    // También buscar en user anidado
    final user = json['user'];
    if (user != null && user is Map<String, dynamic>) {
      for (final key in keys) {
        final value = user[key];
        if (value != null &&
            value.toString().trim().isNotEmpty &&
            value.toString() != 'null') {
          return value.toString().trim();
        }
      }
    }

    return null;
  }

  /// Maneja las respuestas de error de la API
  static Exception _handleErrorResponse(http.Response response) {
    debugPrint('[TramitesService] Error HTTP: ${response.statusCode}');

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

  /// Obtiene trámites filtrados por estado
  static Future<List<TramiteEstado>> getTramitesPorEstado(String estado) async {
    final response = await getTramitesEstados();
    return response.data
        .where((tramite) =>
            tramite.nombreEstado.toUpperCase() == estado.toUpperCase())
        .toList();
  }

  /// Obtiene trámites filtrados por dependencia
  static Future<List<TramiteEstado>> getTramitesPorDependencia(
      String dependencia) async {
    final response = await getTramitesEstados();
    return response.data
        .where((tramite) => tramite.nombreDependencia
            .toLowerCase()
            .contains(dependencia.toLowerCase()))
        .toList();
  }

  /// Obtiene estadísticas de los trámites
  static Future<Map<String, int>> getEstadisticasTramites() async {
    final response = await getTramitesEstados();
    final estadisticas = <String, int>{};

    for (final tramite in response.data) {
      final estado = tramite.nombreEstado;
      estadisticas[estado] = (estadisticas[estado] ?? 0) + 1;
    }

    return estadisticas;
  }

  /// Verifica si el servidor de trámites está disponible
  static Future<bool> checkServerAvailability() async {
    try {
      debugPrint(
          '[TramitesService] Verificando disponibilidad del servidor...');

      final response = await http.get(
        Uri.parse(_apiUrl.replaceAll('/api/external/', '/health')),
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': _apiKey,
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Timeout verificando servidor'),
      );

      debugPrint(
          '[TramitesService] Server check status: ${response.statusCode}');
      return response.statusCode == 200 ||
          response.statusCode ==
              404; // 404 también indica que el servidor responde
    } catch (e) {
      debugPrint('[TramitesService] Server check failed: $e');
      return false;
    }
  }

  /// Obtiene información de diagnóstico de red
  static Future<Map<String, dynamic>> getDiagnosticInfo() async {
    final diagnostics = <String, dynamic>{};

    try {
      // Verificar conectividad básica
      final userData = await _getUserData();
      diagnostics['user_authenticated'] = userData.isNotEmpty;
      diagnostics['user_id'] = _extractIdGeneral(userData);

      // Verificar disponibilidad del servidor
      diagnostics['server_reachable'] = await checkServerAvailability();

      // Información de la API
      diagnostics['api_url'] = _apiUrl;
      diagnostics['api_configured'] = _apiKey.isNotEmpty;
    } catch (e) {
      diagnostics['error'] = e.toString();
    }

    return diagnostics;
  }
}