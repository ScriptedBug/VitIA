import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/weather_service.dart';
import '../../widgets/weather_section.dart';
import '../../widgets/vitia_header.dart';
import '../tutorial/tutorial_page.dart';
import '../../core/api_client.dart';

class InicioScreen extends StatefulWidget {
  // Convert to Stateful
  final String userName;
  final String location;
  final String? userPhotoUrl; // Nuevo campo
  final VoidCallback? onProfileTap;
  final ApiClient apiClient;

  const InicioScreen({
    super.key,
    required this.userName,
    required this.location,
    this.userPhotoUrl,
    this.onProfileTap,
    required this.apiClient,
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
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Column(
          children: [
            // 2. HEADER UNIFICADO (FIJO)
            VitiaHeader(
              title: '', // Título vaciado para moverlo al body
              leading: IconButton(
                icon: const Icon(Icons.menu_book_outlined, color: Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TutorialPage(
                        apiClient: widget.apiClient,
                        isCompulsory: false,
                        onFinished: () => Navigator.pop(context),
                      ),
                    ),
                  );
                },
                tooltip: "Tutorial",
              ),
              userPhotoUrl: widget.userPhotoUrl, // Pasamos la URL
              onProfileTap: widget.onProfileTap,
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),

                    // TEXTO HOLA (Movido aquí)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        '¡Hola, ${widget.userName.split(' ')[0]}!',
                        style: GoogleFonts.lora(
                          fontSize: 32,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF1E2623),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 3. ILUSTRACIÓN VIÑEDO
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
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
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black87),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),

                    // 5. SECCIÓN TIEMPO
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

                    const SizedBox(
                        height:
                            140), // Espacio aumentado para el navbar flotante
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
