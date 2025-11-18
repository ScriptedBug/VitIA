import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
      title: 'VitIA',
      home: LoginPage(),
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
//                            LOGIN PAGE
////////////////////////////////////////////////////////////////////////////////

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  Future<void> login() async {
    final url = Uri.parse("http://10.0.2.2:8000/auth/token");


    final response = await http.post(
      url,
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {
        "username": emailCtrl.text.trim(),
        "password": passwordCtrl.text.trim(),
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("TOKEN: ${data["access_token"]}");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inicio de sesión exitoso")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      final data = jsonDecode(response.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["detail"] ?? "Error al iniciar sesión")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "VitIA - Iniciar sesión",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                    labelText: "Email", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: "Contraseña", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: login,
                child: const Text("Iniciar sesión"),
              ),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  );
                },
                child: const Text("Crear cuenta"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
//                            REGISTER PAGE
////////////////////////////////////////////////////////////////////////////////

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController apellidosCtrl = TextEditingController();

  Future<void> register() async {
    final url = Uri.parse("http://10.0.2.2:8000/auth/register");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": emailCtrl.text.trim(),
        "nombre": nombreCtrl.text.trim(),
        "apellidos": apellidosCtrl.text.trim(),
        "password": passCtrl.text.trim(),
      }),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario creado correctamente")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      final data = jsonDecode(response.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["detail"] ?? "Error al crear usuario")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear cuenta")),
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(
                  labelText: "Nombre", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: apellidosCtrl,
              decoration: const InputDecoration(
                  labelText: "Apellidos", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                  labelText: "Email", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(
                  labelText: "Contraseña", border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: register,
              child: const Text("Crear cuenta"),
            ),
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
//                              HOME PAGE
////////////////////////////////////////////////////////////////////////////////

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

  PreferredSizeWidget _buildAppBarInicio() {
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
      actions: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: Icon(Icons.account_circle, size: 28),
        ),
      ],
    );
  }
}

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
