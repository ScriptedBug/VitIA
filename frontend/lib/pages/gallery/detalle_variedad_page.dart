import 'dart:io';
import 'package:flutter/material.dart';

class DetalleVariedadPage extends StatelessWidget {
  final Map<String, dynamic> variedad;

  const DetalleVariedadPage({super.key, required this.variedad});

  @override
  Widget build(BuildContext context) {
    final bool isBlanca = variedad['tipo'] == 'Blanca';
    final colorTema = isBlanca ? Colors.lime.shade700 : Colors.purple.shade900;
    
    // Extraemos los datos nuevos
    final Map<String, dynamic>? morfologia = variedad['morfologia'];
    final Map<String, dynamic>? infoExtra = variedad['info_extra'];

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1. APPBAR (Igual que antes)
          SliverAppBar(
            expandedHeight: 350.0,
            pinned: true,
            backgroundColor: colorTema,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                variedad['nombre'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImagen(variedad),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. CONTENIDO
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Etiquetas superiores
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorTema.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colorTema),
                        ),
                        child: Text(
                          (variedad['tipo'] ?? 'Desconocido').toUpperCase(),
                          style: TextStyle(color: colorTema, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(variedad['region'] ?? 'España', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // SECCIÓN: DESCRIPCIÓN
                  _buildSectionTitle("Descripción"),
                  Text(
                    variedad['descripcion'] ?? "Sin descripción detallada.",
                    style: TextStyle(fontSize: 16, height: 1.6, color: Colors.grey.shade800),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 30),

                  // SECCIÓN: MORFOLOGÍA (Solo si existe)
                  if (morfologia != null) ...[
                    _buildSectionTitle("Morfología"),
                    _buildMorfologiaItem("Hoja", morfologia['hoja']),
                    _buildMorfologiaItem("Racimo", morfologia['racimo']),
                    _buildMorfologiaItem("Uva", morfologia['uva']),
                    const SizedBox(height: 30),
                  ],

                  // SECCIÓN: INFO EXTRA (Solo si existe)
                  if (infoExtra != null && infoExtra.isNotEmpty) ...[
                    _buildSectionTitle("Datos Adicionales"),
                    ...infoExtra.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.arrow_right, color: colorTema),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(color: Colors.grey.shade800, fontSize: 15),
                                children: [
                                  TextSpan(text: "${e.key}: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: "${e.value}"),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 30),
                  ],
                  
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMorfologiaItem(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey.shade800)),
          ),
        ],
      ),
    );
  }

  Widget _buildImagen(Map<String, dynamic> variedad) {
    final String? path = variedad['imagen'];
    if (path == null) return Container(color: Colors.grey.shade300);
    if (variedad['es_local'] == true) return Image.file(File(path), fit: BoxFit.cover);
    if (path.startsWith('assets/')) return Image.asset(path, fit: BoxFit.cover);
    return Image.network(path, fit: BoxFit.cover);
  }
}