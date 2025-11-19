import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/services/api_config.dart';
import '../main_layout/home_page.dart'; // Importa la nueva ubicación

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
    final baseUrl = getBaseUrl();
    final url = Uri.parse("$baseUrl/auth/register");

    try {
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

      if (!mounted) return;

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