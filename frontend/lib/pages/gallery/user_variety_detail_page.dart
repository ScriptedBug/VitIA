import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'detalle_coleccion_page.dart';
import '../../core/api_client.dart';
import '../../core/services/api_config.dart';
import '../../core/services/user_sesion.dart';

class UserVarietyDetailPage extends StatefulWidget {
  final Map<String, dynamic> varietyInfo;
  final List<Map<String, dynamic>> captures;
  final VoidCallback? onBack; // Callback para volver atrás

  const UserVarietyDetailPage({
    super.key,
    required this.varietyInfo,
    required this.captures,
    this.onBack,
  });

  @override
  State<UserVarietyDetailPage> createState() => _UserVarietyDetailPageState();
}

class _UserVarietyDetailPageState extends State<UserVarietyDetailPage> {
  // NAV: Selección interna
  Map<String, dynamic>? _selectedCapture;

  // VIEW MODE: true = Individual (Horizontal), false = Multiple (Vertical)
  bool _isHorizontalView = false;

  // STATE: Local captures list to allow refreshing
  late List<Map<String, dynamic>> _captures;
  late ApiClient _apiClient;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _captures = List.from(widget.captures);
    _apiClient = ApiClient(getBaseUrl());
    if (UserSession.token != null) {
      _apiClient.setToken(UserSession.token!);
    }
  }

  // REFRESH LOGIC
  Future<void> _reloadCaptures() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch entire collection (or filtering endpoint if available)
      final allItems = await _apiClient.getUserCollection();

      // 2. Filter by current variety name
      final varietyName = widget.varietyInfo['nombre'];

      final updatedList = allItems
          .where((item) {
            final vData = item['variedad'] ?? {};
            return vData['nombre'] == varietyName;
          })
          .map((item) {
            final vData = item['variedad'] ?? {};
            return {
              'id': item['id_coleccion'],
              'nombre': vData['nombre'] ?? 'Sin nombre',
              'descripcion': item['notas'] ?? vData['descripcion'],
              'region': 'Mi Bodega',
              'tipo': vData['color'] ?? 'Personal',
              'imagen': item['path_foto_usuario'],
              'morfologia': vData['morfologia'],
              'fecha_captura': item['fecha_captura'],
              'latitud': item['latitud'],
              'longitud': item['longitud'],
              'es_local': false,
              'variedad_original': vData,
            };
          })
          .toList()
          .cast<Map<String, dynamic>>();

      if (mounted) {
        setState(() {
          _captures = updatedList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error reloading captures: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. NESTED NAV: Detail View
    if (_selectedCapture != null) {
      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (didPop) return;
          setState(() => _selectedCapture = null);
        },
        child: DetalleColeccionPage(
          coleccionItem: _selectedCapture!,
          onClose: (refresh) {
            setState(() => _selectedCapture = null);
            if (refresh) {
              // If an item was deleted/edited, reload list
              _reloadCaptures();
              // Optionally notify parent too if needed
              if (widget.onBack != null) widget.onBack!();
            }
          },
        ),
      );
    }

    // MAIN IMAGE RESOLUTION
    final String mainImage = widget.varietyInfo['imagen'] ??
        (_captures.isNotEmpty ? _captures[0]['imagen'] : null) ??
        'assets/images/placeholder.png'; // Fallback

    // THEME COLOR
    final bool isBlanca = (widget.varietyInfo['tipo'] == 'Blanca');
    final colorTema = isBlanca ? Colors.lime.shade700 : Colors.purple.shade900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. BACKGROUND (Full Screen)
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: _buildMainImage(mainImage),
            ),
          ),

          // 2. BACK BUTTON (Floating)
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ),

          // 3. DRAGGABLE SHEET
          DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black26, blurRadius: 20, spreadRadius: 5)
                  ],
                ),
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    // HEADER SECTION
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Drag Handle
                            Center(
                              child: Container(
                                width: 40,
                                height: 5,
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),

                            // Title & Region
                            Text(
                              widget.varietyInfo['nombre'] ?? 'Sin Nombre',
                              style: GoogleFonts.lora(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: colorTema.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: colorTema)),
                                  child: Text(
                                    (widget.varietyInfo['tipo'] ?? 'Personal')
                                        .toUpperCase(),
                                    style: GoogleFonts.lora(
                                        color: colorTema,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10),
                                  ),
                                ),
                                // Region removed
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ACTION BAR (Toggles)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Mis fotos (${_captures.length})",
                              style: GoogleFonts.lora(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            if (_isLoading)
                              const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                            else
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.view_carousel,
                                        color: _isHorizontalView
                                            ? Colors.black
                                            : Colors.grey),
                                    onPressed: () => setState(
                                        () => _isHorizontalView = true),
                                    tooltip: "Vista Individual",
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.grid_view,
                                        color: !_isHorizontalView
                                            ? Colors.black
                                            : Colors.grey),
                                    onPressed: () => setState(
                                        () => _isHorizontalView = false),
                                    tooltip: "Vista Múltiple",
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),

                    // CONTENT
                    _isHorizontalView
                        ? SliverToBoxAdapter(
                            child: SizedBox(
                              height: 450, // Más grande
                              child: PageView.builder(
                                controller:
                                    PageController(viewportFraction: 0.85),
                                itemCount: _captures.length,
                                itemBuilder: (context, index) {
                                  final item = _captures[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: _buildCardItem(item,
                                        isHorizontal: true),
                                  );
                                },
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final item = _captures[index];
                                  return _buildCardItem(item,
                                      isHorizontal: false);
                                },
                                childCount: _captures.length,
                              ),
                            ),
                          ),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildCardItem(Map<String, dynamic> item,
      {required bool isHorizontal}) {
    // Prep Date
    String fecha = "Fecha desc.";
    if (item['fecha_captura'] != null) {
      try {
        final d = DateTime.parse(item['fecha_captura'].toString());
        fecha = "${d.day}/${d.month}/${d.year}";
      } catch (_) {}
    }

    // Theme color for badge
    final bool isBlanca = (widget.varietyInfo['tipo'] == 'Blanca');
    final colorTema = isBlanca ? Colors.lime.shade700 : Colors.purple.shade900;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCapture = item;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                // Si es Horizontal View, redondeamos solo arriba. Si es Grid, redondeamos TODO porque es solo imagen.
                borderRadius: isHorizontal
                    ? const BorderRadius.vertical(top: Radius.circular(15))
                    : BorderRadius.circular(15),
                child: _buildImage(item['imagen'], fit: BoxFit.cover),
              ),
            ),

            // SOLO MOSTRAR INFO SI ES LA VISTA HORIZONTAL
            if (isHorizontal)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge Izquierda (Tipo)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorTema),
                      ),
                      child: Text(
                        (widget.varietyInfo['tipo'] ?? 'PERSONAL')
                            .toUpperCase(),
                        style: TextStyle(
                            color: colorTema,
                            fontWeight: FontWeight.bold,
                            fontSize: 10),
                      ),
                    ),

                    // Fecha Derecha
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "Capturado: $fecha",
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    )
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? path, {BoxFit fit = BoxFit.cover}) {
    if (path == null) {
      return Container(
          color: Colors.grey.shade300,
          child: const Icon(Icons.image_not_supported));
    }
    ImageProvider img;
    if (path.startsWith('http')) {
      img = NetworkImage(path);
    } else if (path.startsWith('assets/')) {
      img = AssetImage(path);
    } else {
      img = FileImage(File(path));
    }
    return Image(
        image: img,
        fit: fit,
        errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200));
  }

  // Method for the hero background image (Blurred + Contain)
  Widget _buildMainImage(String path) {
    ImageProvider img;
    if (path.startsWith('http')) {
      img = NetworkImage(path);
    } else if (path.startsWith('assets/')) {
      img = AssetImage(path);
    } else {
      img = FileImage(File(path));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Blur BG
        Image(image: img, fit: BoxFit.cover),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(color: Colors.black.withOpacity(0.3)),
        ),
        // 2. Main Image
        Align(
          alignment: Alignment.topCenter,
          child: Image(
            image: img,
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
          ),
        ),
      ],
    );
  }
}
