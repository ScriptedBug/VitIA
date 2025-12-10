class UserSession {
  static String? _token;
  static int? _userId;
  
  // Getter y Setter estáticos
  static String? get token => _token;
  static void setToken(String token) => _token = token;

  static int? get userId => _userId;
  static void setUserId(int id) => _userId = id;
  
  // 🔑 FIX: Método para limpiar el token localmente
  static void clearToken() {
    _token = null;
    _userId = null;
  }
}