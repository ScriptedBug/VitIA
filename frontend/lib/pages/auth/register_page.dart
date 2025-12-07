// lib/pages/auth/register_page.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/services/api_config.dart';
import '../main_layout/home_page.dart'; 
import 'login_page.dart'; 
// 🚨 FIX CRÍTICO: Necesario para guardar el token después del registro
import 'package:vinas_mobile/core/services/user_sesion.dart'; 


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
    final registerUrl = Uri.parse("$baseUrl/auth/register");

    try {
      // 1. Petición de Registro
      final response = await http.post(
        registerUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailCtrl.text.trim(),
          "nombre": nombreCtrl.text.trim(),
          "apellidos": apellidosCtrl.text.trim(),
          "password": passCtrl.text.trim(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        
        // 🚨 PASO 1: Iniciar sesión automáticamente para obtener el Token
        final loginUrl = Uri.parse("$baseUrl/auth/token");
        final loginResponse = await http.post(
          loginUrl,
          headers: {"Content-Type": "application/x-www-form-urlencoded"},
          body: {
            "username": emailCtrl.text.trim(), 
            "password": passCtrl.text.trim(),
          },
        );
        
        if (!mounted) return;

        if (loginResponse.statusCode == 200) {
            final tokenData = jsonDecode(loginResponse.body);
            final token = tokenData["access_token"];

            // 🔑 FIX CLAVE: Guardar el token en la sesión
            UserSession.setToken(token); 
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Usuario creado e iniciado sesión correctamente")),
            );

            // Redirigir a HomePage. HomePage chequeará el tutorial.
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
        } else {
            // Fallo en la obtención del token después del registro
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Usuario creado, pero error al iniciar sesión automáticamente. Por favor, inicie sesión manualmente.")),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()), 
            );
        }
        
      } else {
        // Manejo de errores de registro (ej. email ya registrado)
        String message = "Error al crear la cuenta.";
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            message = errorData["detail"] ?? message;
          } catch (_) {}
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
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