import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:geolocator/geolocator.dart'; 
import '../../core/services/weather_service.dart'; 

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  String _userName = 'Viñador'; 
  final WeatherService _weatherService = WeatherService();
  
  Map<String, dynamic>? _weatherData; 
  String _currentLocationName = 'Cargando...';
  bool _isLoadingWeather = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadWeather(); 
  }

  // --- LÓGICA DE CARGA DE DATOS (Mantenida) ---

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name');
    
    if (name != null && name.isNotEmpty) {
      final firstName = name.split(' ')[0]; 
      if(mounted) {
        setState(() {
          _userName = firstName;
        });
      }
    }
  }

  Future<void> _loadWeather() async {
    setState(() {
      _isLoadingWeather = true;
      _weatherData = null; 
      _currentLocationName = 'Buscando ubicación...';
    });
    
    Map<String, dynamic>? location = await _weatherService.getLastSavedLocation();

    if (location == null) {
        location = await _getDeviceLocation();
    }
    
    if (location != null && mounted) {
      
      setState(() {
        _currentLocationName = location!['name']; 
      });
      
      try {
        final data = await _weatherService.fetchWeather(
          location['latitude'],
          location['longitude'],
          location['name'],
        );

        if (mounted) {
          setState(() {
            _weatherData = data;
            _currentLocationName = data['location']; 
          });
        }
      } catch (e) {
        print("Error cargando el clima: $e");
        if (mounted) {
           setState(() {
            _weatherData = null;
            _currentLocationName = 'Error de conexión API';
           });
        }
      }
    } else {
       if (mounted) {
         setState(() {
            _weatherData = null; 
            _currentLocationName = 'Ubicación no disponible';
         });
       }
    }

    if (mounted) {
      setState(() {
        _isLoadingWeather = false;
      });
    }
  }

  // --- MÉTODOS DE UBICACIÓN Y GPS (Mantenidos) ---
  
  Future<Map<String, dynamic>?> _getDeviceLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Servicios de ubicación deshabilitados.")),
            );
        }
        return null; 
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || 
            permission == LocationPermission.deniedForever) {
            if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Permiso de ubicación denegado.")),
                );
            }
            return null;
        }
    }

    try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
        );
        String tempName = "Lat: ${position.latitude.toStringAsFixed(2)}";

        return {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'name': tempName, 
        };
    } catch (e) {
        print("Error obteniendo ubicación por GPS: $e");
        return null;
    }
  }


  // --- WIDGET BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            // ELIMINADO: _buildStatusCards(context),
            _buildWeatherSection(context),
            // ELIMINADO: _buildAdviceSection(),
            // ELIMINADO: _buildNewsSection(context),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // 1. CABECERA (Hola Usuario, Logo, Ubicación)
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Muestra el nombre dinámico
              Text(
                '¡Hola, $_userName!',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              // User profile avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  image: const DecorationImage(
                    image: AssetImage('assets/user_avatar.png'), 
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
              const SizedBox(width: 5),
              Text(_currentLocationName, style: const TextStyle(fontSize: 14, color: Colors.black54)), 
              const Spacer(),
              const Icon(Icons.edit_outlined, size: 18, color: Colors.black54),
            ],
          ),
        ],
      ),
    );
  }

  // 2. SECCIÓN DEL TIEMPO (Mantenida)
  Widget _buildWeatherSection(BuildContext context) {
    // 1. Estado de Carga / Error
    if (_isLoadingWeather || _weatherData == null) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tiempo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: _loadWeather, child: Text(_isLoadingWeather ? 'Cargando...' : 'Reintentar')), 
                ],
              ),
            const SizedBox(height: 10),
            Center(
              child: (_isLoadingWeather && _weatherData == null)
                  ? const CircularProgressIndicator()
                  : Text(
                      'No se pudo cargar el clima para $_currentLocationName.', 
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
            ),
          ],
        ),
      );
    }
    
    // 2. Estado de Éxito
    final currentTemp = _weatherData!['current_temp'];
    final description = _weatherData!['description'];
    final tempMax = _weatherData!['temp_max'];
    final tempMin = _weatherData!['temp_min'];
    final forecast = _weatherData!['forecast'] as List<dynamic>;
    
    final dailyForecast = forecast.take(3).toList();


    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tiempo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              TextButton(onPressed: _loadWeather, child: const Text('Actualizar')), 
            ],
          ),
          const SizedBox(height: 10),
          // Main weather display
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$currentTemp°C', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      Text(_currentLocationName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Icon(Icons.arrow_drop_down, size: 24),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(description, style: const TextStyle(color: Colors.black87)),
                ],
              ),
              const Spacer(),
              Column(
                children: [
                  Text('↑ ${tempMax}°C', style: TextStyle(color: Colors.grey.shade600)),
                  Text('↓ ${tempMin}°C', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Weekly forecast 
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: dailyForecast.map((dayData) {
              final iconData = _getWeatherIcon(dayData['icon_code']);
              return _buildDailyForecast(dayData['day'], '${dayData['temp']}°C', iconData);
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- MÉTODOS AUXILIARES (Mantenidos) ---

  IconData _getWeatherIcon(int code) {
    if (code == 1000) return Icons.wb_sunny; 
    if (code >= 1003 && code <= 1009) return Icons.cloud; 
    if (code >= 1063 && code <= 1276) return Icons.cloudy_snowing; 
    return Icons.cloud; 
  }

  Widget _buildDailyForecast(String day, String temp, IconData icon) {
    return Column(
      children: [
        Text(day),
        Icon(icon, size: 20),
        Text(temp),
      ],
    );
  }
}