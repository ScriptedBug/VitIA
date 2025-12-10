class UserSession {
  static String? _token;
  
  // Getter y Setter estáticos
  static String? get token => _token;
  static void setToken(String token) => _token = token;
  
  // 🔑 FIX: Método para limpiar el token localmente
  static void clearToken() => _token = null; 
}