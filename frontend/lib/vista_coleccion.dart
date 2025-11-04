import 'package:flutter/material.dart';

class VistaColeccion extends StatelessWidget {
  const VistaColeccion({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Colección Personal'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Aquí aparecerán las variedades que guardes en tu coleccion personal.',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
