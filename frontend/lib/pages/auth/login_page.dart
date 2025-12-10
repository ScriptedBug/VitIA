// lib/pages/auth/login_page.dart

import 'package:flutter/material.dart';
import 'package:vinas_mobile/core/services/user_sesion.dart';
import '../main_layout/home_page.dart';
import 'register_page.dart';
import 'login_form_page.dart'; // <<< Nuevo archivo de formulario

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Color principal (Vino VitIA: #A01B4C)
  final Color _authMainColor = const Color(0xFFA01B4C); 
  // Blanco cálido VitIA: #FFFFEFB
  final Color _authFieldColor = const Color(0xFFFFFFEB); 
  
  // Función placeholder para el login de invitado (o si se quiere implementar)
  void loginAsGuest(BuildContext context) {
    // Implementar lógica de invitado si es necesaria
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Funcionalidad de invitado en desarrollo")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _authMainColor, // Fondo color Vino VitIA
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Título "Bienvenido a VitIA"
                const Text(
                  "Bienvenido a",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Lora'), 
                ),
                const Text(
                  "VitIA",
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Lora'), 
                ),
                const SizedBox(height: 30),
                
                // --- Ilustración de Inicio ---
                Image.asset(
                    'assets/inicio/ilustracion_inicio.png', // Ruta ajustada
                    height: 150,
                    width: 150,
                    color: _authFieldColor, // Colorear la ilustración de blanco cálido
                ),
                const SizedBox(height: 50),
                
                // 🚨 BOTÓN 1: Iniciar Sesión (Lleva al formulario de credenciales)
                Container(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginFormPage()), // <<< NAVEGA AL FORMULARIO
                      );
                    }, 
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: _authFieldColor,
                      side: BorderSide(color: _authFieldColor, width: 2), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: const Text("Iniciar sesión", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 15),

                // 🚨 BOTÓN 2: Registrarse (Lleva al formulario de registro)
                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _authFieldColor, 
                      foregroundColor: _authMainColor, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: const Text("Registrarse", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 20),
                
                // --- Entrar como invitado ---
                TextButton(
                  onPressed: () => loginAsGuest(context),
                  child: const Text(
                    "Entrar como invitado",
                    style: TextStyle(color: Colors.white, decoration: TextDecoration.underline),
                  ),
                ),
                 const SizedBox(height: 50), 
              ],
            ),
          ),
        ),
      ),
      // <<< BARRA DE NAVEGACIÓN SIMULADA ELIMINADA >>>
    );
  }
}