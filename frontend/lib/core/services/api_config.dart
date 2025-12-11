// lib/core/services/api_config.dart
import 'package:flutter/foundation.dart';
import 'user_sesion.dart';

// La dirección de desarrollo de tu servidor FastAPI/Uvicorn (localhost para Web/Desktop)
// La dirección de desarrollo de tu servidor FastAPI/Uvicorn (localhost para Web/Desktop)
const String _localHostUrl = 'http://127.0.0.1:8000';

// Configuración de WeatherAPI
const String weatherBaseUrl = 'http://api.weatherapi.com/v1';
const String weatherApiKey =
    '10d519f407934518a30132259252511'; // 🚨 REEMPLAZA ESTO CON TU CLAVE REAL

String getBaseUrl() {
  if (kIsWeb) {
    return _localHostUrl;
  }

  // 1. Si el usuario configuró una IP manual en el login, usamos esa.
  if (UserSession.baseUrl != null && UserSession.baseUrl!.isNotEmpty) {
    return UserSession.baseUrl!;
  }

  // 2. Fallback: IP harcodeada (útil para primera vez o si se borran datos)
  return 'http://192.168.0.105:8000';
}
