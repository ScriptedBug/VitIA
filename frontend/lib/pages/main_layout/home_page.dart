// lib/pages/main_layout/home_page.dart

import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:dio/dio.dart';

// Importaciones de páginas y servicios
import '../gallery/catalogo_page.dart'; 
import '../capture/foto_page.dart';
import '../library/foro_page.dart'; 
import 'inicio_screen.dart'; 
import 'perfil_page.dart'; // Mismo directorio
import '../../core/api_client.dart'; 
import '../../core/services/api_config.dart';
import '../../core/services/user_sesion.dart'; 
import '../tutorial/tutorial_page.dart'; 
import '../auth/login_page.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomepageState();
}

class _HomepageState extends State<HomePage> {
  int currentIndex = 0;
  
  bool _isAuthenticated = false; 
  bool _tutorialSuperado = true;
  bool _isLoadingStatus = true;
  late ApiClient _apiClient; 

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
    _checkAuthAndTutorial(); 
  }
  
  bool _checkIsAuthenticated() {
      return UserSession.token != null && UserSession.token!.isNotEmpty;
  }

  void _checkAuthAndTutorial() {
      _isAuthenticated = _checkIsAuthenticated();
      
      if (!_isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
              );
          });
      } else {
          _apiClient.setToken(UserSession.token!);
          _checkTutorialStatus();
      }
  }

  Future<void> _checkTutorialStatus() async {
      if (!mounted) return;
      setState(() => _isLoadingStatus = true);

      try {
          final bool tutorialStatus = await _apiClient.getTutorialStatus(); 
          
          if (!tutorialStatus) {
              // Si el tutorial NO está superado, bloqueamos el build y lo mostramos.
              if (mounted) setState(() => _tutorialSuperado = false); 
              
              WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showTutorialPage(isInitial: true);
              });
          }
          
          if (mounted) setState(() => _tutorialSuperado = tutorialStatus);

      } on DioException catch (e) {
          debugPrint("Error al cargar estado del tutorial: ${e.message}");
          if (mounted) setState(() => _tutorialSuperado = true); 
      } catch (e) {
          debugPrint("Error general al cargar estado del tutorial: $e");
          if (mounted) setState(() => _tutorialSuperado = true);
      } finally {
          if (mounted) setState(() => _isLoadingStatus = false);
      }
  }

  // FUNCIÓN ASIGNADA AL BOTÓN DE AYUDA (El que faltaba)
  void _launchTutorialManual() {
      Navigator.of(context).push(
          MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => TutorialPage(
                  apiClient: _apiClient, 
                  onFinished: () => Navigator.of(context).pop(), 
                  isCompulsory: false, 
              ),
          ),
      );
  }

  void _showTutorialPage({required bool isInitial}) {
      Navigator.of(context).push(
          MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => TutorialPage(
                  apiClient: _apiClient,
                  isCompulsory: isInitial, 
                  onFinished: () {
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
      // 🔑 BOTÓN DE AYUDA (LEADING)
      leading: IconButton(
        icon: const Icon(Icons.help_outline, size: 26), 
        onPressed: _launchTutorialManual, // <<< El botón está aquí y funcional
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PerfilPage(apiClient: _apiClient)), // Pasamos apiClient
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
      if (_isLoadingStatus || !_tutorialSuperado) { 
          return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Color(0xFF8B9E3A))),
          );
      }
      
      const Color darkBarColor = Color(0xFF142018); // Negro VitIA

      return Scaffold(
          extendBody: true,
          appBar: currentIndex == 0 ? _buildAppBarInicio(context) : null,
          
          body: _screens[currentIndex],
          
          // BARRA DE NAVEGACIÓN FLOTANTE (OPERATIVA)
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
                          tabBackgroundColor: const Color(0xFF9C27B0).withOpacity(0.5), // Magenta/Vino
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