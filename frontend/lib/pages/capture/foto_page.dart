import 'package:flutter/material.dart';

class FotoPage extends StatelessWidget {
  const FotoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identificar planta'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Aquí harás fotos para identificar las plantas.',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}