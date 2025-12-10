import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static String? _token;
  static int? _userId;

  // Clave para guardar en disco
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'auth_user_id';

  // Getters
  static String? get token => _token;
  static int? get userId => _userId;

  // --- MÉTODOS ASÍNCRONOS PARA PERSISTENCIA ---

  /// Carga la sesión desde SharedPreferences al iniciar la app
  static Future<bool> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _userId = prefs.getInt(_userIdKey);

    // Devolvemos true si hay token válido
    return _token != null && _token!.isNotEmpty;
  }

  /// Guarda el token y el ID en memoria y disco
  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> setUserId(int id) async {
    _userId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, id);
  }

  /// Borra la sesión de memoria y disco (Logout)
  static Future<void> clearSession() async {
    _token = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
  }
}
