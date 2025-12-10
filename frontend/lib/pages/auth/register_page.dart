// lib/pages/auth/register_page.dart (CÓDIGO FINAL DE REGISTRO)

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/services/api_config.dart';
import '../main_layout/home_page.dart'; 
import 'login_page.dart'; 
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
  
  // Color principal (Vino VitIA: #A01B4C)
  final Color _authMainColor = const Color(0xFFA01B4C); 
  // Blanco cálido VitIA: #FFFFEFB
  final Color _authFieldColor = const Color(0xFFFFFFEB);

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
        
        // PASO 2: Iniciar sesión automáticamente para obtener el Token
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

            UserSession.setToken(token); 
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Usuario creado e iniciado sesión correctamente")),
            );

            // Redirige a HomePage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
        } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Usuario creado, pero error al iniciar sesión automáticamente. Por favor, inicie sesión manualmente.")),
            );
            Navigator.pop(context); // Vuelve a la página anterior
        }
        
      } else {
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
                const Text(
                  "Registrarse",
                  style: TextStyle(
                      fontSize: 36, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white, 
                      fontFamily: 'Lora'), 
                ),
                const SizedBox(height: 50),
                
                // --- Campo de Nombre ---
                TextField(
                  controller: nombreCtrl,
                  style: TextStyle(color: _authMainColor, fontSize: 16),
                  decoration: InputDecoration(
                      labelText: "Nombre", 
                      filled: true,
                      fillColor: _authFieldColor, 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: _authMainColor, width: 2)), 
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: _authMainColor, width: 2)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: _authFieldColor, width: 2)),
                      labelStyle: TextStyle(color: _authMainColor), 
                  ),
                ),
                const SizedBox(height: 15),

                // --- Campo de Apellidos ---
                TextField(
                  controller: apellidosCtrl,
                  style: TextStyle(color: _authMainColor, fontSize: 16),
                  decoration: InputDecoration(
                      labelText: "Apellidos", 
                      filled: true,
                      fillColor: _authFieldColor, 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: _authMainColor, width: 2)), 
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: _authMainColor, width: 2)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: _authFieldColor, width: 2)),
                      labelStyle: TextStyle(color: _authMainColor), 
                  ),
                ),
                const SizedBox(height: 15),
                 
                 // --- Campo de Correo Electrónico ---
                TextField(
                  controller: emailCtrl,
                  style: TextStyle(color: _authMainColor, fontSize: 16),
                  decoration: InputDecoration(
                      labelText: "Correo electrónico", 
                      filled: true,
                      fillColor: _authFieldColor, 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: _authMainColor, width: 2)), 
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: _authMainColor, width: 2)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: _authFieldColor, width: 2)),
                      labelStyle: TextStyle(color: _authMainColor), 
                  ),
                ),
                const SizedBox(height: 15),
                
                // --- Campo de Contraseña ---
                TextField(
                  controller: passCtrl,
                  style: TextStyle(color: _authMainColor, fontSize: 16),
                  decoration: InputDecoration(
                      labelText: "Contraseña", 
                      filled: true,
                      fillColor: _authFieldColor, 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: _authMainColor, width: 2)), 
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: _authMainColor, width: 2)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: _authFieldColor, width: 2)),
                      labelStyle: TextStyle(color: _authMainColor), 
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 30),
                
                // --- Botón Continuar (Relleno Blanco) ---
                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _authFieldColor, 
                      foregroundColor: _authMainColor, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: const Text("Continuar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // --- Botón de Iniciar Sesión ---
                 TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Vuelve a LoginPage
                  },
                  child: const Text(
                    "Ya tienes una cuenta? Inicia sesión",
                    style: TextStyle(color: Colors.white, decoration: TextDecoration.underline),
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