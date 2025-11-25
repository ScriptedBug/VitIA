import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// 🚨 REEMPLAZA ESTA CLAVE CON TU CLAVE DE WEATHERAPI.COM 🚨
const String _WEATHER_API_KEY = "10d519f407934518a30132259252511"; 
const String _API_BASE_URL = "https://api.weatherapi.com/v1";

class WeatherService {
    
    // Clave usada en SharedPreferences para guardar la ubicación
    static const _locationKey = 'last_known_location';

    Future<Map<String, dynamic>> fetchWeather(double lat, double lon, String locationName) async {
        
        // Usamos el endpoint de forecast para obtener todo (clima actual + pronóstico)
        final uri = Uri.parse(
            '$_API_BASE_URL/forecast.json?key=$_WEATHER_API_KEY&q=$lat,$lon&days=3'
        );

        try {
            final response = await http.get(uri);

            if (response.statusCode == 200) {
                final Map<String, dynamic> rawData = jsonDecode(response.body);
                
                return _mapApiDataToUi(rawData);
            } else {
                throw Exception(
                    'Fallo al cargar datos del clima. Status: ${response.statusCode}'
                );
            }
        } catch (e) {
            throw Exception('Error de conexión con la API externa: $e');
        }
    }
    
    // --- Función para mapear datos de la API a la estructura que espera InicioScreen ---
    Map<String, dynamic> _mapApiDataToUi(Map<String, dynamic> rawData) {
        final todayForecast = rawData['forecast']['forecastday'][0]['day'];
        final current = rawData['current'];
        final location = rawData['location'];
        
        final List<Map<String, dynamic>> forecastList = rawData['forecast']['forecastday'].map<Map<String, dynamic>>((dayData) {
            final dateTime = DateTime.fromMillisecondsSinceEpoch(dayData['date_epoch'] * 1000);
            // Esto asume que el día 1 es Lunes. Si quieres que Domingo sea 0, cambia el índice.
            final dayName = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'][dateTime.weekday % 7];
            
            return {
                'day': dayName,
                'temp': dayData['day']['avgtemp_c'].round(),
                'icon_code': dayData['day']['condition']['code'], 
            };
        }).toList();


        return {
            'location': '${location['name']}, ${location['region']}',
            'current_temp': current['temp_c'].round(),
            'description': current['condition']['text'],
            'temp_max': todayForecast['maxtemp_c'].round(),
            'temp_min': todayForecast['mintemp_c'].round(),
            'forecast': forecastList,
        };
    }

    // --- Función para obtener la ubicación guardada (Devuelve null si no hay) ---
    Future<Map<String, dynamic>?> getLastSavedLocation() async {
        final prefs = await SharedPreferences.getInstance();
        final data = prefs.getString(_locationKey); 
        
        if (data != null) {
            final parts = data.split(',');
            if (parts.length == 3) {
                try {
                    return {
                        'latitude': double.parse(parts[0]),
                        'longitude': double.parse(parts[1]),
                        'name': parts[2],
                    };
                } catch (_) {
                    return null;
                }
            }
        }
        
        // 🚨 CAMBIO CLAVE: Devuelve null si no hay datos válidos guardados.
        return null; 
    }

    // --- FUNCIÓN NUEVA: Guarda la ubicación seleccionada por el usuario ---
    Future<void> saveLocation(double lat, double lon, String name) async {
        final prefs = await SharedPreferences.getInstance();
        // Guardar en el formato: "lat,lon,name"
        await prefs.setString(_locationKey, '$lat,$lon,$name'); 
    }
}