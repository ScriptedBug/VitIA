import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
// Importaciones de las páginas de contenido
import '../gallery/catalogo_page.dart'; // Catálogo unificado
import '../capture/foto_page.dart'; // Foto
import '../library/foro_page.dart'; // Foro
import 'inicio_screen.dart'; // Home
import 'perfil_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomepageState();
}

class _HomepageState extends State<HomePage> {
  int currentIndex = 0;

  // 1. LISTA DE PANTALLAS: DEBE SEGUIR EL ORDEN DE LOS BOTONES: [Home, Foto, Catálogo, Foro]
  final List<Widget> _screens = [
    // Índice 0: Botón HOME
    const InicioScreen(),
    
    // Índice 1: Botón CÁMARA/FOTO 
    const FotoPage(),
    
    // Índice 2: Botón CATÁLOGO (Libro)
    // Queremos que el catálogo inicie en la pestaña Biblioteca (Índice 0 en CatalogoPage)
    const CatalogoPage(initialTab: 0), 
    
    // Índice 3: Botón FORO (Chat)
    const ForoPage(),
  ];

  @override
  Widget build(BuildContext context) {
    const Color darkBarColor = Color(0xFF142018); 

    return Scaffold(
      appBar: currentIndex == 0 ? _buildAppBarInicio(context) : null,
      
      body: _screens[currentIndex],
      
      // BARRA DE NAVEGACIÓN
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
                // Esto controla qué widget de _screens se muestra
                setState(() => currentIndex = index);
              },
              
              // 2. LISTA DE BOTONES: DEBE COINCIDIR EN ORDEN CON LAS PANTALLAS
              tabs: const [
                GButton(icon: Icons.home, iconSize: 30),                  // Índice 0 -> Inicio
                GButton(icon: Icons.camera_alt_outlined, iconSize: 30),   // Índice 1 -> Foto
                GButton(icon: Icons.menu_book, iconSize: 30),             // Índice 2 -> Catálogo
                GButton(icon: Icons.forum, iconSize: 30),                 // Índice 3 -> Foro
              ],
            ),
          ),
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
      leading: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.0),
        child: Icon(Icons.settings, size: 26),
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
}