import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_config.dart';

class WeatherService {
  final Dio _dio = Dio();

  Future<Map<String, dynamic>?> getWeather(String location) async {
    // Si no hay API key configurada, retornamos null o lanzamos error
    if (weatherApiKey == 'YOUR_API_KEY_HERE') {
      debugPrint("⚠️ WeatherAPI Key no configurada.");
      return null;
    }

    try {
      // Endpoint forecast.json nos da clima actual y pronóstico días futuros
      // days=3 para obtener hoy, mañana y pasado (o más si se requiere para la UI)
      final String query =
          location.contains(',') ? location : '$location, Spain';
      debugPrint("🔍 WeatherService Query: '$query' (Input: '$location')");

      final response = await _dio.get(
        '$weatherBaseUrl/forecast.json',
        queryParameters: {
          'key': weatherApiKey,
          // Lógica para priorizar España si no se especifica país
          'q': query,
          'days': 3,
          'lang': 'es', // Español
          'aqi': 'no',
          'alerts': 'no',
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        debugPrint(
            "Error WeatherAPI: ${response.statusCode} - ${response.statusMessage}");
        return null;
      }
    } catch (e) {
      debugPrint("Excepción WeatherService: $e");
      return null;
    }
  }
}
