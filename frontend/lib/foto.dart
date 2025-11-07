import 'package:flutter/material.dart';

class Foto extends StatelessWidget {
  const Foto({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ientificar planta'),
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