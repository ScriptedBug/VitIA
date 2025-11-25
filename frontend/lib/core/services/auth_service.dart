import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart'; // Asegúrate de que este import sea correcto

class AuthService {
  final String _baseUrl = getBaseUrl();
  static const _tokenKey = 'access_token';
  static const _nameKey = 'user_name';

  // --- 1. Obtiene y guarda el Token ---
  Future<String> getToken(String email, String password) async {
    final url = Uri.parse("$_baseUrl/auth/token");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {
        "username": email,
        "password": password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data["access_token"] as String;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token); // Guardar el token inmediatamente
      
      return token;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData["detail"] ?? "Error de autenticación");
    }
  }

  // --- 2. Obtiene los Datos del Usuario y guarda el Nombre ---
  Future<String> fetchAndSaveUserName(String token, String email) async {
    final url = Uri.parse("$_baseUrl/users/me");
    final prefs = await SharedPreferences.getInstance();
    
    // Fallback: usar parte del email si todo falla
    final fallbackName = email.split('@')[0];

    try {
      final response = await http.get(
        url,
        headers: {
          // 🚨 CRÍTICO: La cabecera de autorización es OBLIGATORIA
          "Authorization": "Bearer $token", 
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? userName = data["nombre"];
        
        // Usar el nombre real o el fallback si viene vacío por alguna razón
        final finalName = (userName != null && userName.isNotEmpty) ? userName.split(' ')[0] : fallbackName;
        
        await prefs.setString(_nameKey, finalName);
        return finalName;

      } else {
        // Fallo de autenticación o de red, usar fallback
        await prefs.setString(_nameKey, fallbackName);
        return fallbackName;
      }
    } catch (e) {
      // Fallo de red (ClientException)
      print("Error al obtener /users/me: $e");
      await prefs.setString(_nameKey, fallbackName);
      return fallbackName;
    }
  }
  
  // --- Función para la pantalla de inicio ---
  Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    // Devuelve el nombre guardado o un valor por defecto
    return prefs.getString(_nameKey) ?? 'Viñador'; 
  }
}