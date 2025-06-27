import 'dart:convert';
import 'package:flutter/material.dart';
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
    try {
      final response = await http.post(
        Uri.parse(_loginUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': _apiKey,
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['token'] != null) {
          final token = data['token'];
          final prefs = await SharedPreferences.getInstance();

          // Guardar token y datos del usuario
          await prefs.setString(_tokenKey, token);
          await prefs.setString(_userDataKey, jsonEncode(data));

          debugPrint('✅ Token guardado correctamente');
          return true;
        } else {
          debugPrint('⚠️ Error en login: ${data['message']}');
          return false;
        }
      } else {
        debugPrint('❌ Error HTTP ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error en AuthService.login(): $e');
      return false;
    }
  }

  // 🔓 Cierra sesión limpiando datos locales
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
  }

  // 🔍 Verifica si hay una sesión activa
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null;
  }

  // 👤 Obtiene los datos del usuario autenticado
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_userDataKey);
    if (jsonString != null) {
      return jsonDecode(jsonString);
    }
    return null;
  }

  // 📦 Obtiene el token JWT almacenado
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
}
