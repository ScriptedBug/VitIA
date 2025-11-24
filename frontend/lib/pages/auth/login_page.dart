import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vinas_mobile/core/services/user_sesion.dart';
import '../../core/services/api_config.dart';
import '../main_layout/home_page.dart'; // Importa la nueva ubicación
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  Future<void> login() async {
    final baseUrl = getBaseUrl();
    final url = Uri.parse("$baseUrl/auth/token");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "username": emailCtrl.text.trim(),
          "password": passwordCtrl.text.trim(),
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data["access_token"];

        UserSession.setToken(token);
        print("Token guardado en sesión: $token");

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
    } catch (e) {
      if (!mounted) return;
      print("ERROR DE CONEXIÓN O PETICIÓN: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error de conexión al servidor: ${e.runtimeType}")),
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