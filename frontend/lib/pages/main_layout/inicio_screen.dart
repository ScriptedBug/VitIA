import 'package:flutter/material.dart';
import '../../core/services/weather_service.dart';
import '../../widgets/weather_section.dart';

class InicioScreen extends StatefulWidget {
  // Convert to Stateful
  final String userName;
  final String location;

  const InicioScreen({
    super.key,
    required this.userName,
    required this.location,
  });

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _weatherData;
  String? _weatherError;
  bool _isLoadingWeather = true;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    if (widget.location.isEmpty) {
      if (mounted)
        setState(() {
          _isLoadingWeather = false;
        });
      return;
    }

    // Limpiar ubicación para la API (quitar ", España" si molesta, o dejarlo)
    try {
      final data = await _weatherService.getWeather(widget.location);
      if (mounted) {
        setState(() {
          _weatherData = data;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _weatherError = "No se pudo cargar el tiempo";
          _isLoadingWeather = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),

              // 2. SALUDO + AVATAR
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '¡Hola, ${widget.userName}!',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight:
                            FontWeight.w400, // Fuente tipo serif elegante
                        fontFamily: 'Serif',
                        color: Color(0xFF142018),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 3. ILUSTRACIÓN VIÑEDO
              // El usuario dijo "he descargado la foto... assets/home/"
              // Asumimos 'assets/home/ilustracion_vinedo.png' (Yo la copié antes)
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Image.asset(
                    'assets/home/ilustracion_home.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 4. UBICACIÓN
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: Colors.black87),
                    const SizedBox(width: 8),
                    Text(
                      widget.location.isNotEmpty
                          ? "${widget.location}."
                          : "Sin ubicación definida.",
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(width: 8),
                    // Icono de edición eliminado
                  ],
                ),
              ),

              // 5. SECCIÓN TIEMPO (NUEVO)
              if (_weatherData != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: WeatherSection(weatherData: _weatherData),
                )
              else if (_weatherError != null)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(_weatherError!,
                      style: const TextStyle(color: Colors.red)),
                )
              else if (!_isLoadingWeather && widget.location.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("Información del tiempo no disponible."),
                ),

              const SizedBox(height: 30),

              // 5. DATOS ESTÁTICOS (MOCKUP) - Cepas / Hectáreas
              // El usuario dijo "obvia todo lo de estado del viñedo", pero quizás
              // quiera ver los datos inferiores. Los pondré como placeholder estático.
              // 5. DATOS ESTÁTICOS (Cepas / Hectáreas) ELIMINADO
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 24.0),
              //   child: Row(
              //     children: [
              //       Expanded(
              //         child: _buildInfoCard("300 Cepas", "4 Variedades"),
              //       ),
              //       const SizedBox(width: 15),
              //       Expanded(
              //         child: _buildInfoCard("1,6 hectáreas", "Desde 1982"),
              //       ),
              //     ],
              //   ),
              // ),

              const SizedBox(height: 100), // Espacio para el navbar
            ],
          ),
        ),
      ),
    );
  }
}
