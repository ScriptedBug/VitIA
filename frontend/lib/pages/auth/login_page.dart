import 'package:flutter/material.dart';
// Quitar dart:convert y http
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// Quitar shared_preferences
// import 'package:shared_preferences/shared_preferences.dart'; 

// ⬅️ NUEVA IMPORTACIÓN DEL SERVICIO
import '../../core/services/auth_service.dart'; 
import '../../core/services/api_config.dart'; // Mantener api_config
import '../main_layout/home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  bool _isLoading = false; 
  final AuthService _authService = AuthService(); // Instancia del servicio

  Future<void> login() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    final emailInput = emailCtrl.text.trim();
    final passwordInput = passwordCtrl.text.trim();

    try {
      // 1. Obtener Token y guardarlo (llamada al servicio)
      final token = await _authService.getToken(emailInput, passwordInput);

      // 2. Obtener Nombre de usuario y guardarlo (llamada al servicio)
      await _authService.fetchAndSaveUserName(token, emailInput); 
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inicio de sesión exitoso")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
      
    } catch (e) {
      if (!mounted) return;
      print("ERROR DE CONEXIÓN O PETICIÓN: $e");
      
      // Muestra el mensaje de error del servicio o un genérico
      final errorMessage = e.toString().contains("Exception:") 
          ? e.toString().replaceFirst("Exception: ", "") 
          : "Error de conexión al servidor.";
          
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() => _isLoading = false);
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
                onPressed: _isLoading ? null : login, 
                child: _isLoading 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : const Text("Iniciar sesión"),
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