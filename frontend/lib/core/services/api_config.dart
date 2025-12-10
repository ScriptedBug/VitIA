// lib/core/services/api_config.dart
import 'package:flutter/foundation.dart';

// La dirección de desarrollo de tu servidor FastAPI/Uvicorn (localhost para Web/Desktop)
const String _localHostUrl = 'http://127.0.0.1:8000';

String getBaseUrl() {
  if (kIsWeb) {
    // Si corre en un navegador (Web), usa localhost
    return _localHostUrl;
  }
  /* 
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000'; 
  } 
  */
  // Para iOS o Android físico, la mejor opción sería usar la IP de red:
  // return 'http://192.168.1.5:8000'; // 🚨 ¡Reemplaza con tu IP real si es necesario!
  // Para iOS o Android físico, usamos la IP de red local del ordenador:
  // ASEGÚRATE DE QUE TU BACKEND ESTÉ CORRIENDO CON: uvicorn app.main:app --reload --host 0.0.0.0
  return 'http://192.168.1.118:8000';
}
