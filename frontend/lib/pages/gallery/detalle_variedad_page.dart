import 'dart:io';
import 'package:flutter/gestures.dart'; // Necesario para detectar el clic en el texto
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Necesario para abrir el navegador

class DetalleVariedadPage extends StatelessWidget {
  final Map<String, dynamic> variedad;

  const DetalleVariedadPage({super.key, required this.variedad});

  // Función para abrir URLs
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lógica para determinar el tema y color
    final bool isBlanca = variedad['tipo'] == 'Blanca';
    final colorTema = isBlanca ? Colors.lime.shade700 : Colors.purple.shade900;
    
    // Extraemos los mapas de datos
    final Map<String, dynamic>? morfologia = variedad['morfologia'];
    final Map<String, dynamic>? infoExtra = variedad['info_extra'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // 1. APPBAR
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

                  // SECCIÓN: MORFOLOGÍA
                  if (morfologia != null) 
                    _buildMorfologiaSectionNuevo(morfologia, isBlanca),

                  // SECCIÓN: INFO EXTRA (ACTUALIZADA CON LINKS)
                  if (infoExtra != null && infoExtra.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    _buildSectionTitle("Datos Adicionales"),
                    ...infoExtra.entries.map((e) {
                      // Detectamos si el valor es un Link
                      String valor = e.value.toString();
                      bool esLink = valor.startsWith('http') || valor.startsWith('https');

                      return Padding(
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
                                    TextSpan(
                                      text: "${e.key}: ", 
                                      style: const TextStyle(fontWeight: FontWeight.bold)
                                    ),
                                    // Si es link, lo ponemos azul, subrayado y clickeable
                                    esLink 
                                      ? TextSpan(
                                          text: valor,
                                          style: const TextStyle(
                                            color: Colors.blue, 
                                            decoration: TextDecoration.underline,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              _launchURL(valor);
                                            },
                                        )
                                      : TextSpan(text: valor),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
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

  Widget _buildMorfologiaSectionNuevo(Map<String, dynamic> morfologia, bool isBlanca) {
    final int iconProp = isBlanca ? 3 : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Morfología"),
        const SizedBox(height: 8),

        // Hoja
        if (morfologia['hoja'] != null && morfologia['hoja'].toString().isNotEmpty)
          _buildMorfologiaCard(
            titulo: "Hoja",
            descripcion: morfologia['hoja'],
            iconPath: 'assets/icons/Propiedad$iconProp=hoja.png',
          ),

        // Racimo
        if (morfologia['racimo'] != null && morfologia['racimo'].toString().isNotEmpty)
          _buildMorfologiaCard(
            titulo: "Racimo",
            descripcion: morfologia['racimo'],
            iconPath: 'assets/icons/Propiedad$iconProp=racimo.png',
          ),

        // Uva
        if (morfologia['uva'] != null && morfologia['uva'].toString().isNotEmpty)
          _buildMorfologiaCard(
            titulo: "Uva",
            descripcion: morfologia['uva'],
            iconPath: 'assets/icons/Propiedad$iconProp=uva.png',
          ),
      ],
    );
  }

  Widget _buildMorfologiaCard({
    required String titulo,
    required String descripcion,
    required String iconPath,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        // CAMBIO APLICADO: BORDE NEGRO
        border: Border.all(color: Colors.black, width: 1.2), 
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              iconPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.image_not_supported, color: Colors.grey);
              },
            ),
          ),
          const SizedBox(width: 16),
          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descripcion,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
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