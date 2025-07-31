// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _loginUrl =
      'https://sanjuandelrio.gob.mx/tramites-sjr/Api/principal/login';
  static const String _apiKey =
      '27dcb99e08e3f400ca1cae39c145dafa1e8dbac1b70cc2005c666c16b4485a18';

  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';

  AuthService(String user);

  // 🔐 Inicia sesión y guarda el token si es exitoso
  Future<bool> login(String username, String password) async {
    print('[AuthService] 🚀 INICIANDO LOGIN DEBUG');
    print('[AuthService] 📡 URL: $_loginUrl');
    print('[AuthService] 🔑 API Key: ${_apiKey.substring(0, 10)}...');
    print('[AuthService] 👤 Username: "$username"');
    print('[AuthService] 🔒 Password length: ${password.length}');
    
    try {
      final requestBody = {
        'username': username,
        'password': password,
      };
      
      print('[AuthService] 📤 Request body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse(_loginUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': _apiKey,
        },
        body: jsonEncode(requestBody),
      );

      print('[AuthService] 📥 Response status: ${response.statusCode}');
      print('[AuthService] 📥 Response headers: ${response.headers}');
      print('[AuthService] 📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[AuthService] 📊 Parsed data: $data');
        
        if (data['success'] == true && data['token'] != null) {
          final token = data['token'];
          final prefs = await SharedPreferences.getInstance();

          // Guardar token y datos del usuario
          await prefs.setString(_tokenKey, token);
          await prefs.setString(_userDataKey, jsonEncode(data));

          print('[AuthService] ✅ Token guardado correctamente: ${token.substring(0, 20)}...');
          print('[AuthService] ✅ Datos de usuario guardados');
          return true;
        } else {
          print('[AuthService] ❌ Login falló - success: ${data['success']}, token: ${data['token']}');
          print('[AuthService] ❌ Mensaje de error: ${data['message']}');
          return false;
        }
      } else {
        print('[AuthService] ❌ Error HTTP ${response.statusCode}');
        print('[AuthService] ❌ Response body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      print('[AuthService] ❌ EXCEPCIÓN en login: $e');
      print('[AuthService] ❌ Stack trace: $stackTrace');
      return false;
    }
  }

  // 🔓 Cierra sesión limpiando datos locales
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
    print('[AuthService] 🚪 Sesión cerrada - datos eliminados');
  }

  // 🔍 Verifica si hay una sesión activa
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final isLogged = token != null;
    print('[AuthService] 🔍 ¿Sesión activa? $isLogged');
    return isLogged;
  }

  // 👤 Obtiene los datos del usuario autenticado
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_userDataKey);
    if (jsonString != null) {
      final userData = jsonDecode(jsonString);
      print('[AuthService] 👤 Datos de usuario obtenidos: ${userData.keys}');
      return userData;
    }
    print('[AuthService] ❌ No hay datos de usuario guardados');
    return null;
  }

  // 📦 Obtiene el token JWT almacenado
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    print('[AuthService] 📦 Token obtenido: ${token != null ? '${token.substring(0, 20)}...' : 'null'}');
    return token;
  }
}