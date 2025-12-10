import 'package:flutter/material.dart';
import 'dart:io';
import 'detalle_coleccion_page.dart'; // Import para navegación

class UserVarietyDetailPage extends StatefulWidget {
  final Map<String, dynamic> varietyInfo;
  final List<Map<String, dynamic>> captures;

  const UserVarietyDetailPage({
    super.key,
    required this.varietyInfo,
    required this.captures,
  });

  @override
  State<UserVarietyDetailPage> createState() => _UserVarietyDetailPageState();
}

class _UserVarietyDetailPageState extends State<UserVarietyDetailPage> {
  bool _isVerticalListView = true; // Default to "Multiple" (Vertical List) as per user req implied? 
  // User said "ordenar hacia la derecha" (Individual) and "vision multiple como la individual ahora" (Vertical List).
  // Let's set default to whatever makes sense. User said "ahora funciona mejor" so maybe keep current default but swap content?
  // User: "la vista individual ser solo una ... horizontal"
  // User: "vision multiple ... ver como se ve la vista individual ahora" (Vertical List)
  
  // Let's use `_isHorizontalView` to track.
  bool _isHorizontalView = false; // Default: Multiple (Vertical)

  @override
  Widget build(BuildContext context) {
    // Assuming varietyInfo contains name, region, etc.
    // If captures is not empty, we can try to get a better image from captures if the main one is generic.
    final String mainImage = widget.varietyInfo['imagen'] ?? 
                            (widget.captures.isNotEmpty ? widget.captures[0]['imagen'] : null) ?? 
                            'assets/images/placeholder.png'; // Fallback
    
    // Determine if main image is asset or network/file
    final bool isAsset = mainImage.startsWith('assets/');

    return Scaffold(
      backgroundColor: Colors.white, // As per design
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
             // 1. Header with Back Button and "Biblioteca" breadcrumb style
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                       child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: const Text(
                          "VitIA",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.0),
                        ),
                      ),
                    ),
                    const Text(
                      "Biblioteca",
                      style: TextStyle(
                        fontFamily: 'Serif', 
                        fontSize: 32,
                        fontWeight: FontWeight.w400, 
                        color: Color(0xFF1E2623),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text("Tus variedades", style: TextStyle(color: Colors.grey.shade600)),
                        ),
                        Text(" > ${widget.varietyInfo['nombre']}", style: const TextStyle(color: Colors.black)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 2. Huge Image
            SliverToBoxAdapter(
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.black12,
                ),
                child: isAsset
                  ? Image.asset(mainImage, fit: BoxFit.cover)
                  : (mainImage.startsWith('http') 
                      ? Image.network(mainImage, fit: BoxFit.cover)
                      : Image.file(File(mainImage), fit: BoxFit.cover)),
              ),
            ),

            // 3. Title and Info
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.varietyInfo['nombre'],
                            style: const TextStyle(
                              fontFamily: 'Serif',
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.varietyInfo['region'] ?? 'Región Desconocida',
                            style: const TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.favorite_border, size: 28),
                      onPressed: () {}, // Favorite logic placeholder
                    )
                  ],
                ),
              ),
            ),

            // 4. "Mis fotos" Header and Toggles
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Mis fotos",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        // Icono 1: Vista Individual (Cuadrado / Carousel Horizontal)
                        IconButton(
                          icon: Icon(Icons.crop_square, color: _isHorizontalView ? Colors.black : Colors.grey),
                          onPressed: () => setState(() => _isHorizontalView = true),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: "Vista Individual",
                        ),
                        const SizedBox(width: 16),
                        // Icono 2: Vista Múltiple (Lista Vertical / Grid)
                        IconButton(
                          icon: Icon(Icons.grid_view, color: !_isHorizontalView ? Colors.black : Colors.grey), 
                          onPressed: () => setState(() => _isHorizontalView = false),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: "Vista Múltiple",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // 5. Content (Grid or List)
            _isHorizontalView 
            ? _buildHorizontalView()
            : _buildVerticalListView(),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
      // Optional: Add floating action button for quick actions like "Add Photo" to this variety
    );
  }

  // Vista Individual: Carousel Horizontal
  Widget _buildHorizontalView() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 400, // Altura suficiente para la carta
        child: PageView.builder(
          controller: PageController(viewportFraction: 0.85),
          itemCount: widget.captures.length,
          itemBuilder: (context, index) {
            final item = widget.captures[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _buildCardItem(item),
            );
          },
        ),
      ),
    );
  }

  // Vista Múltiple: Lista Vertical (Lo que antes era "Individual" o List)
  Widget _buildVerticalListView() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = widget.captures[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildCardItem(item),
            );
          },
          childCount: widget.captures.length,
        ),
      ),
    );
  }

  Widget _buildCardItem(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => DetalleColeccionPage(coleccionItem: item))
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 250, // Imagen grandecita
                width: double.infinity,
                child: _buildImage(item['imagen']),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['fecha_captura'] ?? 'Fecha desconocida',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  // Solo FECHA solicitado por usuario.
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? path) {
    if (path == null) {
      return Container(color: Colors.grey.shade300, child: const Icon(Icons.image_not_supported));
    }
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover);
    } else if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    } else {
      return Image.file(File(path), fit: BoxFit.cover);
    }
  }
}
