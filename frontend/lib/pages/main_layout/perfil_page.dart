import 'package:flutter/material.dart';
import '../auth/login_page.dart'; // Importa la página de Login

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  void logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()), 
      (route) => false, // Elimina el stack de navegación
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Perfil")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => logout(context),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text("Cerrar sesión"),
        ),
      ),
    );
  }
}