import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:dio/dio.dart'; // Para manejar errores de Dio

// 🚨 Importaciones de páginas y servicios (Asegúrate que las rutas sean correctas)
import '../gallery/catalogo_page.dart'; 
import '../capture/foto_page.dart';
import '../library/foro_page.dart'; 
import 'inicio_screen.dart'; 
import 'perfil_page.dart';
import '../../core/api_client.dart'; 
import '../../core/services/api_config.dart'; // Para getBaseUrl()
import '../../core/services/user_sesion.dart'; // ⬅️ Tu clase UserSession
import '../tutorial/tutorial_page.dart'; // ⬅️ Tu widget TutorialPage

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomepageState();
}

class _HomepageState extends State<HomePage> {
  int currentIndex = 0;
  
  // ESTADO AÑADIDO PARA EL TUTORIAL Y LA CARGA
  bool _tutorialSuperado = true;
  bool _isLoadingStatus = true;
  late ApiClient _apiClient; 

  // Función Helper que verifica si hay un token válido
  bool _checkIsAuthenticated() {
      // Verifica directamente el getter estático 'token'
      return UserSession.token != null && UserSession.token!.isNotEmpty;
  }

  // 1. LISTA DE PANTALLAS: [Home, Foto, Catálogo, Foro]
  final List<Widget> _screens = [
    const InicioScreen(),                          
    const FotoPage(),                                
    const CatalogoPage(initialTab: 0),             
    const ForoPage(),
  ];

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(getBaseUrl());
    
    if (_checkIsAuthenticated()) { 
        // 1. Configura el token del ApiClient (CRUCIAL para /users/me)
        _apiClient.setToken(UserSession.token!);
        // 2. Inicia la comprobación del tutorial
        _checkTutorialStatus();
    } else {
        // Si no hay token, asumimos el estado normal (para evitar bucle)
        _isLoadingStatus = false;
        _tutorialSuperado = true; 
    }
  }
  
  // Lógica para comprobar el estado del tutorial desde el backend
  Future<void> _checkTutorialStatus() async {
      if (!mounted) return;
      setState(() => _isLoadingStatus = true);

      try {
          // LLAMADA AL API PARA OBTENER EL ESTADO REAL (GET /users/me)
          final bool tutorialStatus = await _apiClient.getTutorialStatus(); 
          
          if (!tutorialStatus) {
              // Si NO está superado, lo lanzamos en el siguiente frame
              WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showTutorialPage(isInitial: true);
              });
          }
          
          if (mounted) setState(() => _tutorialSuperado = tutorialStatus);

      } on DioException catch (e) {
          debugPrint("Error al cargar estado del tutorial: ${e.message}");
          // Fallback seguro: asumimos superado si el servidor falla (para no bloquear la app)
          if (mounted) setState(() => _tutorialSuperado = true); 
      } catch (e) {
          debugPrint("Error general al cargar estado del tutorial: $e");
          if (mounted) setState(() => _tutorialSuperado = true);
      } finally {
          if (mounted) setState(() => _isLoadingStatus = false);
      }
  }

  // Función para lanzar el tutorial de forma manual (Botón de Ayuda)
  void _launchTutorialManual() {
      Navigator.of(context).push(
          MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => TutorialPage(
                  apiClient: _apiClient, 
                  // 🚨 FIX: isCompulsory: false para que no llame al backend al cerrar
                  onFinished: () => Navigator.of(context).pop(), 
                  isCompulsory: false, 
              ),
          ),
      );
  }

  // Función para lanzar el tutorial de forma obligatoria (usado en initState)
  void _showTutorialPage({required bool isInitial}) {
      Navigator.of(context).push(
          MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => TutorialPage(
                  apiClient: _apiClient,
                  isCompulsory: isInitial, // ⬅️ TRUE para el flujo inicial
                  onFinished: () {
                      // Cierra el tutorial y actualiza el estado local
                      Navigator.of(context).pop(); 
                      if (mounted) {
                          setState(() => _tutorialSuperado = true); 
                      }
                  },
              ),
          ),
      );
  }

  PreferredSizeWidget _buildAppBarInicio(BuildContext context) {
    return AppBar(
      title: const Text('VitIA'),
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 1,
      // 🚨 FIX CLAVE: Botón de Ayuda (Interrogante)
      leading: IconButton(
        icon: const Icon(Icons.help_outline, size: 26), 
        onPressed: _launchTutorialManual, // ⬅️ Lanza el tutorial manual
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PerfilPage()),
              );
            },
            child: const Icon(Icons.account_circle, size: 28),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
      // ⚠️ Bloquea la interfaz principal si está cargando O si el tutorial no ha sido superado
      if (_isLoadingStatus || !_tutorialSuperado) { 
          return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Color(0xFF6B8E23))),
          );
      }
      
      const Color darkBarColor = Color(0xFF142018); 

      return Scaffold(
          extendBody: true,
          // Muestra el AppBar solo en la pantalla de inicio (currentIndex == 0)
          appBar: currentIndex == 0 ? _buildAppBarInicio(context) : null,
          
          body: _screens[currentIndex],
          
          // BARRA DE NAVEGACIÓN FLOTANTE
          bottomNavigationBar: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 25), 
              
              child: Container(
                  decoration: BoxDecoration(
                      color: darkBarColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                          BoxShadow(
                              color: darkBarColor.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                          ),
                      ],
                  ),
                  
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0), 
                      
                      child: GNav(
                          gap: 8,
                          color: Colors.white70,
                          activeColor: Colors.white,
                          tabBackgroundColor: const Color(0xFF283A2F), 
                          tabBorderRadius: 100,
                          tabShadow: const [], 
                          padding: const EdgeInsets.all(12),
                          selectedIndex: currentIndex,
                          onTabChange: (index) {
                              setState(() => currentIndex = index);
                          },
                          
                          // 2. LISTA DE BOTONES: [Home, Foto, Catálogo, Foro]
                          tabs: const [
                              GButton(icon: Icons.home, iconSize: 30),                 
                              GButton(icon: Icons.camera_alt_outlined, iconSize: 30),   
                              GButton(icon: Icons.menu_book, iconSize: 30),            
                              GButton(icon: Icons.forum, iconSize: 30),                
                          ],
                      ),
                  ),
              ),
          ),
      );
  }
}