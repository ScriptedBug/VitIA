import 'package:flutter/material.dart';

class Biblioteca extends StatelessWidget {
  const Biblioteca({super.key});

  @override
  Widget build(BuildContext context) {
    // Lista de variedades de ejemplo
    final List<Map<String, String>> variedades = [
      {
        'nombre': 'Variedad X',
        'descripcion': 'Descripción breve...',
        'imagen': 'assets/images/hoja_verde.png',
      },
      {
        'nombre': 'Variedad Y',
        'descripcion': 'Descripción breve...',
        'imagen': 'assets/images/hoja_roja.png',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        leading: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: Icon(Icons.settings, size: 26),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Icon(Icons.account_circle, size: 28),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // 🔍 Barra de búsqueda
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar...',
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 📋 Lista de variedades
            Expanded(
              child: ListView.builder(
                itemCount: variedades.length,
                itemBuilder: (context, index) {
                  final variedad = variedades[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              variedad['imagen']!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            variedad['nombre']!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            variedad['descripcion']!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // acción al presionar "Ver más"
                              },
                              child: const Text(
                                'Ver más',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
