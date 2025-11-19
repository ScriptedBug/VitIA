// lib/main.dart
import 'package:flutter/material.dart';
import 'pages/auth/login_page.dart'; // Importa la nueva ubicación

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
      home: LoginPage(), // Ahora apunta a la nueva página
    );
  }
}

