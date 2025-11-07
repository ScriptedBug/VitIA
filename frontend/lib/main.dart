import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'biblioteca.dart';
import 'vista_coleccion.dart';
import 'foto.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Viñas AI',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomepageState();
}

class _HomepageState extends State<HomePage> {
  int currentIndex = 0;

  final List<Widget> _screens = [
    const Inicio(),
    const VistaColeccion(),
    const Foto(),
    const Biblioteca(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Solo el AppBar del Inicio se define aquí
      appBar: currentIndex == 0 ? _buildAppBarInicio() : null,

      body: _screens[currentIndex],

      bottomNavigationBar: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.only(left: 40.0, right: 40.0, bottom: 30.0),
          child: GNav(
            gap: 8,
            color: Colors.black54,
            activeColor: Colors.black,
            tabBackgroundColor: Colors.grey.shade200,
            padding: const EdgeInsets.all(8),
            selectedIndex: currentIndex,
            onTabChange: (index) {
              setState(() => currentIndex = index);
            },
            tabs: const [
              GButton(icon: Icons.home, iconSize: 30),
              GButton(icon: Icons.favorite, iconSize: 30),
              GButton(icon: Icons.camera_alt_outlined, iconSize: 30),
              GButton(icon: Icons.browse_gallery, iconSize: 30),
            ],
          ),
        ),
      ),
    );
  }

  // 🏠 AppBar solo visible en la pantalla principal
  PreferredSizeWidget _buildAppBarInicio() {
    return AppBar(
      title: const Text('VitIA'),
      centerTitle: true,
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      foregroundColor: Colors.white,
      elevation: 1,
      leading: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.0),
        child: Icon(Icons.settings, size: 26),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: Icon(Icons.account_circle, size: 28),
        ),
      ],
    );
  }
}

// 🌿 Pantalla de Inicio
class Inicio extends StatelessWidget {
  const Inicio({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Bienvenido a VitIA',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}
