// lib/pages/auth/login_form_page.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vinas_mobile/core/services/user_sesion.dart';
import '../../core/services/api_config.dart';
import '../main_layout/home_page.dart';
import 'register_page.dart';

class LoginFormPage extends StatefulWidget {
  const LoginFormPage({super.key});

  @override
  State<LoginFormPage> createState() => _LoginFormPageState();
}

class _LoginFormPageState extends State<LoginFormPage> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  // Color principal (Vino VitIA: #A01B4C)
  final Color _authMainColor = const Color(0xFFA01B4C);
  // Blanco cálido VitIA: #FFFFEFB
  final Color _authFieldColor = const Color(0xFFFFFFEB);

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

        await UserSession.setToken(token);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Inicio de sesión exitoso")),
        );

        // Vuelve a HomePage y limpia el stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      } else {
        String message = "Credenciales incorrectas o error de servidor.";
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
        SnackBar(
            content: Text("Error de conexión al servidor: ${e.runtimeType}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _authMainColor, // Fondo color Vino VitIA
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Título "Iniciar sesión"
                const Text(
                  "Iniciar sesión",
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Lora'),
                ),
                const SizedBox(height: 50),

                // --- Campo de Correo electrónico ---
                TextField(
                  controller: emailCtrl,
                  style: TextStyle(color: _authMainColor, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: "Correo electrónico",
                    filled: true,
                    fillColor: _authFieldColor,
                    // Bordes estilizados
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide:
                            BorderSide(color: _authMainColor, width: 2)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide:
                            BorderSide(color: _authMainColor, width: 2)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide:
                            BorderSide(color: _authFieldColor, width: 2)),
                    labelStyle: TextStyle(color: _authMainColor),
                  ),
                ),
                const SizedBox(height: 15),

                // --- Campo de Contraseña ---
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  style: TextStyle(color: _authMainColor, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: "Contraseña",
                    filled: true,
                    fillColor: _authFieldColor,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide:
                            BorderSide(color: _authMainColor, width: 2)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide:
                            BorderSide(color: _authMainColor, width: 2)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide:
                            BorderSide(color: _authFieldColor, width: 2)),
                    labelStyle: TextStyle(color: _authMainColor),
                  ),
                ),
                const SizedBox(height: 30),

                // --- Botón Continuar (Relleno Blanco) ---
                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _authFieldColor,
                      foregroundColor: _authMainColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                    ),
                    child: const Text("Continuar",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 30),

                // --- Botón de Registro (Texto simple) ---
                TextButton(
                  onPressed: () {
                    // Navega a RegisterPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    );
                  },
                  child: const Text(
                    "No tienes cuenta? Regístrate",
                    style: TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // <<< BARRA DE NAVEGACIÓN SIMULADA ELIMINADA >>>
    );
  }
}
