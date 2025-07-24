import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AuthServiceDebug {
  // URLs alternativas para probar
  static const List<String> _rfcValidationUrls = [
    'https://www.sanjuandelrio.gob.mx/tramites-sjr/Api/principal/validar_rfc',
    'https://sanjuandelrio.gob.mx/tramites-sjr/Api/principal/validar_rfc',
    'https://www.sanjuandelrio.gob.mx/tramites-sjr/api/principal/validar_rfc',
    'https://sanjuandelrio.gob.mx/tramites-sjr/api/principal/validar_rfc',
  ];
  
  static const String _loginUrl =
      'https://sanjuandelrio.gob.mx/tramites-sjr/Api/principal/login';
  static const String _apiKey =
      '27dcb99e08e3f400ca1cae39c145dafa1e8dbac1b70cc2005c666c16b4485a18';

  // Prueba diferentes URLs para validar RFC
  static Future<Map<String, dynamic>?> testRFCValidation(String rfc, String password) async {
    debugPrint('���� INICIANDO PRUEBAS DE VALIDACIÓN RFC');
    debugPrint('🧪 RFC: $rfc');
    
    for (int i = 0; i < _rfcValidationUrls.length; i++) {
      final url = _rfcValidationUrls[i];
      debugPrint('\n🧪 Probando URL ${i + 1}/${_rfcValidationUrls.length}: $url');
      
      try {
        final result = await _testSingleRFCUrl(url, rfc, password);
        if (result != null) {
          debugPrint('✅ URL exitosa: $url');
          return result;
        }
      } catch (e) {
        debugPrint('❌ Error con URL $url: $e');
      }
    }
    
    debugPrint('❌ Todas las URLs fallaron');
    return null;
  }
  
  static Future<Map<String, dynamic>?> _testSingleRFCUrl(String url, String rfc, String password) async {
    try {
      // Probar diferentes formatos de request body
      final requestBodies = [
        {'rfc': rfc, 'password': password},
        {'RFC': rfc, 'PASSWORD': password},
        {'usuario': rfc, 'password': password},
        {'username': rfc, 'password': password},
      ];
      
      for (int i = 0; i < requestBodies.length; i++) {
        final requestBody = requestBodies[i];
        debugPrint('  📤 Probando formato ${i + 1}: ${jsonEncode(requestBody)}');
        
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'X-API-KEY': _apiKey,
            'Accept': 'application/json',
            'User-Agent': 'CUS-Movil-App/1.0',
          },
          body: jsonEncode(requestBody),
        ).timeout(const Duration(seconds: 10));

        debugPrint('  📥 Status: ${response.statusCode}');
        debugPrint('  📥 Headers: ${response.headers}');
        debugPrint('  📥 Body: ${response.body}');

        if (response.statusCode == 200) {
          try {
            final data = jsonDecode(response.body);
            if (data['success'] == true || 
                data['status'] == 'success' || 
                data['valid'] == true ||
                data['resultado'] == 'exitoso') {
              debugPrint('  ✅ Validación exitosa con formato ${i + 1}');
              return data;
            }
          } catch (jsonError) {
            // Si no es JSON válido, verificar si contiene palabras clave de éxito
            final bodyLower = response.body.toLowerCase();
            if (bodyLower.contains('success') || 
                bodyLower.contains('valid') ||
                bodyLower.contains('exitoso') ||
                bodyLower.contains('correcto')) {
              debugPrint('  ✅ Validación exitosa (respuesta en texto)');
              return {'success': true, 'message': 'RFC validado', 'raw_response': response.body};
            }
          }
        } else if (response.statusCode == 404) {
          debugPrint('  ❌ Endpoint no encontrado (404)');
          break; // No probar más formatos para esta URL
        } else if (response.statusCode == 405) {
          debugPrint('  ❌ Método no permitido (405)');
          break; // No probar más formatos para esta URL
        }
      }
    } catch (e) {
      debugPrint('  ❌ Error: $e');
    }
    
    return null;
  }
  
  // Función para probar la conectividad básica
  static Future<bool> testConnectivity() async {
    debugPrint('🌐 Probando conectividad básica...');
    
    try {
      final response = await http.get(
        Uri.parse('https://www.sanjuandelrio.gob.mx'),
        headers: {'User-Agent': 'CUS-Movil-App/1.0'},
      ).timeout(const Duration(seconds: 10));
      
      debugPrint('🌐 Conectividad OK - Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('🌐 Error de conectividad: $e');
      return false;
    }
  }
  
  // Función para probar el endpoint de login normal
  static Future<bool> testLoginEndpoint() async {
    debugPrint('🔐 Probando endpoint de login...');
    
    try {
      final response = await http.post(
        Uri.parse(_loginUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': _apiKey,
          'Accept': 'application/json',
        },
        body: jsonEncode({'username': 'test', 'password': 'test'}),
      ).timeout(const Duration(seconds: 10));
      
      debugPrint('🔐 Login endpoint - Status: ${response.statusCode}');
      debugPrint('🔐 Login endpoint - Body: ${response.body}');
      
      return response.statusCode != 404 && response.statusCode != 405;
    } catch (e) {
      debugPrint('🔐 Error en login endpoint: $e');
      return false;
    }
  }
}