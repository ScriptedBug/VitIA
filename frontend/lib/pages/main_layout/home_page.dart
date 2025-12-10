// lib/pages/main_layout/home_page.dart

import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:dio/dio.dart';

// Importaciones de páginas y servicios
import '../gallery/catalogo_page.dart';
import '../capture/foto_page.dart';
import '../library/foro_page.dart';
import 'inicio_screen.dart';
import 'perfil_page.dart';
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

  // CAMBIO: Convertimos _screens en un método get para poder acceder a setState y lógica de instancia
  List<Widget> get _screens => [
        const InicioScreen(),
        const FotoPage(),
        // CAMBIO: Ahora pasamos el callback al catálogo
        CatalogoPage(
          initialTab: 0,
          onCameraTap: () {
            setState(() {
              currentIndex = 1; // Cambia al tab de cámara (FotoPage)
            });
          },
        ),
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
      // BOTÓN DE AYUDA (Mantiene IconData, ya que el mockup no tiene icono de imagen aquí)
      leading: IconButton(
        icon: const Icon(Icons.help_outline, size: 26),
        onPressed: _launchTutorialManual,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PerfilPage(apiClient: _apiClient)),
              );
            },
            // Ícono de Perfil (Mantiene IconData)
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
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF8B9E3A))),
      );
    }

    const Color darkBarColor = Color(0xFF142018); // Negro VitIA
    const Color activeTabColor =
        Color.fromARGB(255, 255, 255, 255); // Magenta/Vino

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
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            child: GNav(
              gap: 8,
              color: Colors.white70,
              activeColor: Colors.white,
              tabBackgroundColor:
                  activeTabColor.withOpacity(0.5), // Magenta/Vino
              tabBorderRadius: 100,
              tabShadow: const [],
              padding: const EdgeInsets.all(12),
              selectedIndex: currentIndex,
              onTabChange: (index) {
                setState(() => currentIndex = index);
              },

              // 🚨 SUSTITUCIÓN DE ICONOS: Usamos Image.asset de la carpeta assets/navbar
              tabs: [
                GButton(
                  icon: Icons.home,
                  iconSize: 0, // Deshabilitar el icono de Material
                  leading: Image.asset('assets/navbar/icon_nav_home.png',
                      width: 30,
                      color: currentIndex == 0
                          ? Colors.black
                          : const Color.fromARGB(
                              179, 218, 211, 211) // Color de activo/inactivo
                      ),
                ),
                // CAMBIO: Ocultamos el botón de cámara de la barra si ahora es un FAB flotante
                // O lo mantenemos si queremos redundancia. El usuario dijo "que el boton de hacer foto se mantenga arriba".
                // Si ponemos un FAB central, ¿qué hacemos con la barra?
                // Opción 1: Mantener los 4 items y el FAB flota encima (tapando quizás el de cámara).
                // Opción 2: Dejar hueco.
                // Vamos a mantener la barra tal cual y el FAB flotará "encima", aunque visualmente puede chocar.
                // REVISIÓN: El usuario dijo "mueva por la barra de herramientas que ya existe".
                // Si ponemos el FAB en `centerDocked`, quedará encima.
                GButton(
                  icon: Icons.camera_alt_outlined,
                  iconSize: 0,
                  leading: Image.asset('assets/navbar/icon_nav_camera.png',
                      width: 30,
                      color: currentIndex == 1
                          ? Colors.black
                          : const Color.fromARGB(179, 218, 211, 211)),
                ),
                GButton(
                  icon: Icons.menu_book,
                  iconSize: 0,
                  leading: Image.asset('assets/navbar/icon_nav_catalogo.png',
                      width: 30,
                      color: currentIndex == 2
                          ? Colors.black
                          : const Color.fromARGB(179, 218, 211, 211)),
                ),
                GButton(
                  icon: Icons.forum,
                  iconSize: 0,
                  leading: Image.asset('assets/navbar/icon_nav_foro.png',
                      width: 30,
                      color: currentIndex == 3
                          ? Colors.black
                          : const Color.fromARGB(179, 218, 211, 211)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
