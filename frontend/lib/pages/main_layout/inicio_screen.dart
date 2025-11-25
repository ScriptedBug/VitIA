import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // 🚨 IMPORTANTE: Necesario para la función de edición
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

  // --- MÉTODOS DE UBICACIÓN Y EDICIÓN ---

  // 1. Obtener ubicación del dispositivo (GPS)
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

  // 2. Diálogo para editar y guardar nueva ubicación
  Future<void> _editLocation() async {
    final TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        // Estado local para las sugerencias dentro del diálogo
        List<Placemark> suggestions = [];
        String searchError = '';

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            
            void searchAddress(String query) async {
              if (query.length < 3) {
                setStateDialog(() {
                  suggestions = [];
                  searchError = '';
                });
                return;
              }

              setStateDialog(() {
                searchError = 'Buscando...';
              });

              try {
                // 🚨 CORRECCIÓN CLAVE: Usamos locationFromAddress sin prefijo si se importa directamente.
                final placemarks = await placemarkFromAddress(query); 
                
                setStateDialog(() {
                  suggestions = placemarks;
                  searchError = placemarks.isEmpty ? 'No se encontraron resultados.' : '';
                });

              } catch (e) {
                setStateDialog(() {
                  suggestions = [];
                  searchError = 'Error de búsqueda. Intente un formato más simple.';
                });
              }
            }

            return AlertDialog(
              title: const Text("Editar Ubicación"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: "Ej: Valencia, España",
                        labelText: "Buscar Ciudad",
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () => searchAddress(controller.text),
                        ),
                      ),
                      onSubmitted: searchAddress,
                    ),
                    
                    if (searchError.isNotEmpty) 
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(searchError, style: TextStyle(color: searchError.contains('Error') ? Colors.red : Colors.orange)),
                      ),
                    
                    // Lista de sugerencias
                    if (suggestions.isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: suggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion = suggestions[index];
                            
                            // Construye un nombre legible a partir de los campos del Placemark
                            final readableName = '${suggestion.street ?? ''}, ${suggestion.locality ?? suggestion.subAdministrativeArea ?? ''}, ${suggestion.country ?? ''}'
                                                  .replaceAll(RegExp(r'(^, )|(, , )|(,$)'), '').trim();

                            return ListTile(
                              title: Text(readableName, maxLines: 1, overflow: TextOverflow.ellipsis),
                              // 🚨 CORRECCIÓN CLAVE 2: Acceso directo a Latitud/Longitud
                              subtitle: Text('Coord: ${suggestion.latitude.toStringAsFixed(2)}, Lon: ${suggestion.longitude.toStringAsFixed(2)}'),
                              onTap: () async {
                                
                                await _weatherService.saveLocation(
                                  suggestion.latitude, 
                                  suggestion.longitude, 
                                  readableName, 
                                );
                                
                                if (mounted) {
                                  Navigator.pop(ctx); 
                                  _loadWeather(); 
                                }
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Cancelar"),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            );
          },
        );
      },
    );
  }


  // 3. Función principal de carga (Prioridad: Guardado > GPS > Error)
  Future<void> _loadWeather() async {
    setState(() {
      _isLoadingWeather = true;
      _weatherData = null;
      _currentLocationName = 'Buscando ubicación...';
    });
    
    Map<String, dynamic>? location = await _weatherService.getLastSavedLocation();

    // PASO 1: Si no hay ubicación guardada, intentar obtener la ubicación actual (GPS).
    if (location == null) {
        location = await _getDeviceLocation();
    }
    
    // PASO 2: Si encontramos una ubicación (guardada o por GPS), llamamos a la API.
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
            // Usamos el nombre oficial devuelto por la API
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
        // PASO 3: Fallo total
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

  // --- LÓGICA DE CARGA DE NOMBRE ---

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

  // --- WIDGET BUILDERS (Simplificados) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildWeatherSection(context),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // 1. CABECERA (Hola Usuario, Logo, Ubicación EDITABLE)
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
              // Hola, Usuario!
              Text(
                '¡Hola, $_userName!',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              // Avatar
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
          // Ícono del Viñedo / Gráfico
          Image.asset(
            'assets/vineyard_graphic.png',
            height: 100,
            width: double.infinity,
            fit: BoxFit.fitWidth,
          ),
          const SizedBox(height: 10),
          // Ubicación actual y Botón de Editar
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
              const SizedBox(width: 5),
              Text(_currentLocationName, style: const TextStyle(fontSize: 14, color: Colors.black54)),
              const Spacer(),
              // 🚨 BOTÓN DE EDITAR UBICACIÓN CON GESTURE DETECTOR
              GestureDetector(
                  onTap: _editLocation,
                  child: const Icon(Icons.edit_outlined, size: 18, color: Colors.black54)
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. SECCIÓN DEL TIEMPO
  Widget _buildWeatherSection(BuildContext context) {
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

  // --- MÉTODOS AUXILIARES ---

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