// lib/core/services/api_config.dart
import 'package:flutter/foundation.dart';
import 'user_sesion.dart';

// La dirección de desarrollo de tu servidor FastAPI/Uvicorn (localhost para Web/Desktop)
const String _localHostUrl = 'http://127.0.0.1:8000';
const String _prodUrl = 'https://vitia.onrender.com';

// Configuración de WeatherAPI
const String weatherBaseUrl = 'http://api.weatherapi.com/v1';
const String weatherApiKey =
    '10d519f407934518a30132259252511'; // 🚨 REEMPLAZA ESTO CON TU CLAVE REAL

String getBaseUrl() {
  // 1. Si el usuario configuró una IP manual en el login, usamos esa.
  if (UserSession.baseUrl != null && UserSession.baseUrl!.isNotEmpty) {
    return UserSession.baseUrl!;
  }
  // 2. Default: Servidor de Producción (Render)
  return _prodUrl;
}
