import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';


class CatalogoPage extends StatefulWidget { // ⬅️ CLASE RENOMBRADA A CATÁLOGO
  final int initialTab; 
  const CatalogoPage({super.key, this.initialTab = 0}); 

  @override
  State<CatalogoPage> createState() => _CatalogoPageState(); // ⬅️ ESTADO RENOMBRADO A CATÁLOGO
}

class _CatalogoPageState extends State<CatalogoPage> with SingleTickerProviderStateMixin { // ⬅️ ESTADO RENOMBRADO A CATÁLOGO
  
  // --- VARIABLES DE ESTADO Y CONTROL ---
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  // Variables del estado original (mantidas para la lógica)
  bool _modoOscuro = false;
  List<Map<String, dynamic>> _variedades = [];
  List<Map<String, dynamic>> _filtradas = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Usar el índice inicial pasado desde HomePage
    _tabController.index = widget.initialTab; 

    // Datos de ejemplo adaptados al nuevo estilo de tarjeta
    _variedades = [
      {
        'nombre': 'Moscatel',
        'region': 'Levante español y Canarias',
        'tipo': 'Blanca',
        'imagen': 'assets/hoja1.jpg',
        'descripcion': 'Variedad aromática y dulce. Se usa para vinos de postre.',
        'ubicacion': 'Valencia, España'
      },
      {
        'nombre': 'Merseguera',
        'region': 'Comunidad Valenciana',
        'tipo': 'Blanca',
        'imagen': 'assets/hoja2.jpg',
        'descripcion': 'Uva blanca de la Comunidad Valenciana, resistente a la sequía.',
        'ubicacion': 'Valencia, España'
      },
      {
        'nombre': 'Giró',
        'region': 'Islas Baleares (Mallorca)',
        'tipo': 'Tinta',
        'imagen': 'assets/hoja3.jpg',
        'descripcion': 'Variedad tinta autóctona de Baleares.',
        'ubicacion': 'Mallorca, España'
      },
      {
        'nombre': 'Monastrell',
        'region': 'Sureste de España',
        'tipo': 'Tinta',
        'imagen': 'assets/hoja4.jpg',
        'descripcion': 'Variedad muy extendida en Murcia y Alicante.',
        'ubicacion': 'Murcia, España'
      },
    ];
    _filtradas = List.from(_variedades);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- MÉTODOS DE GESTIÓN DE DATOS Y LÓGICA ORIGINAL (MANTENIDOS) ---

  void _filtrar(String query) {
    setState(() {
      _filtradas = _variedades
          .where((v) => v['nombre'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _abrirCamara() async {
    var statusCamara = await Permission.camera.request();
    var statusUbicacion = await Permission.locationWhenInUse.request();

    if (statusCamara.isDenied || statusUbicacion.isDenied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permisos de cámara y ubicación son necesarios.")),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? foto = await picker.pickImage(source: ImageSource.camera);

    if (foto == null) { return; }

    Position? posicion;
    try {
      posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch(e) {
      print("Error obteniendo ubicación: $e");
    }

    String ubicacionTexto = posicion != null
        ? "Lat: ${posicion.latitude}, Lon: ${posicion.longitude}"
        : "Ubicación no disponible";

    _mostrarDialogoNuevaVariedad(File(foto.path), ubicacionTexto);
  }

  void _mostrarDialogoNuevaVariedad(File imagen, String ubicacionInicial) {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final ubicCtrl = TextEditingController(text: ubicacionInicial);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nueva Variedad"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Image.file(imagen, height: 100),
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: "Nombre de variedad"),
              ),
              TextField(
                controller: descCtrl,
                decoration:
                    const InputDecoration(labelText: "Descripción (opcional)"),
              ),
              TextField(
                controller: ubicCtrl,
                decoration:
                    const InputDecoration(labelText: "Ubicación (opcional)"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            child: const Text("Guardar"),
            onPressed: () {
              setState(() {
                _variedades.add({
                  'nombre': nombreCtrl.text,
                  'imagen': imagen.path,
                  'descripcion': descCtrl.text,
                  'ubicacion': ubicCtrl.text,
                  'region': 'Colección Personal',
                  'tipo': 'Desconocido', 
                });
                _filtradas = List.from(_variedades);
              });
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEditarVariedad(Map<String, dynamic> variedad) {
    final nombreCtrl = TextEditingController(text: variedad['nombre']);
    final descCtrl = TextEditingController(text: variedad['descripcion']);
    final ubicCtrl = TextEditingController(text: variedad['ubicacion']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Editar Variedad"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: "Nombre"),
              ),
              TextField(
                controller: descCtrl,
                decoration:
                    const InputDecoration(labelText: "Descripción (opcional)"),
              ),
              TextField(
                controller: ubicCtrl,
                decoration:
                    const InputDecoration(labelText: "Ubicación (opcional)"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            child: const Text("Guardar"),
            onPressed: () {
              setState(() {
                variedad['nombre'] = nombreCtrl.text;
                variedad['descripcion'] = descCtrl.text;
                variedad['ubicacion'] = ubicCtrl.text;
              });
              Navigator.pop(ctx);
              Navigator.pop(context);
              _mostrarFichaTecnica(variedad);
            },
          ),
        ],
      ),
    );
  }

  void _mostrarFichaTecnica(Map<String, dynamic> variedad) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                variedad['imagen'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    variedad['nombre'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.brush, color: Colors.blueGrey),
                  tooltip: "Editar",
                  onPressed: () => _mostrarDialogoEditarVariedad(variedad),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  tooltip: "Eliminar",
                  onPressed: () => _confirmarEliminacion(variedad),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              variedad['descripcion']?.isNotEmpty == true
                  ? variedad['descripcion']
                  : "Sin descripción disponible",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              variedad['ubicacion']?.isNotEmpty == true
                  ? "Ubicación: ${variedad['ubicacion']}"
                  : "Ubicación no especificada",
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminacion(Map<String, dynamic> variedad) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminar Variedad"),
        content: Text(
            "¿Seguro que deseas eliminar la variedad \"${variedad['nombre']}\"?"),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
            onPressed: () {
              setState(() {
                _variedades.remove(variedad);
                _filtradas = List.from(_variedades);
              });
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
  
  void _alternarTema() {
     setState(() {
       _modoOscuro = !_modoOscuro;
     });
   }
   
  // ------------------------------------------------------------------
  // --- WIDGETS DE INTERFAZ (ADAPTADOS AL NUEVO DISEÑO) ---

  Widget _buildVarietyCard(Map<String, dynamic> variedad) {
    final bool isBlanca = variedad['tipo'] == 'Blanca';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(
          onTap: () => _mostrarFichaTecnica(variedad),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        variedad['region'] ?? 'Región Desconocida',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        variedad['nombre'],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isBlanca ? Colors.lime.shade700 : Colors.purple.shade900,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          variedad['tipo'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Icono de corazón (Estilo de la foto)
                IconButton(
                  icon: Icon(
                    Icons.favorite,
                    color: Colors.grey.shade300, 
                    size: 24,
                  ),
                  onPressed: () {}, 
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBarAndFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _filtrar,
              decoration: InputDecoration(
                hintText: 'Buscar...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.black54),
            onPressed: () {
              // Lógica para abrir filtros
            },
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Variedades'), // Título de la sección
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Lógica adicional si se requiere un botón de búsqueda en la App Bar
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _abrirCamara, // Método de cámara
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).primaryColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Biblioteca'), // Índice 0
            Tab(text: 'Colección'),  // Índice 1
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pestaña 1: BIBLIOTECA GLOBAL
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBarAndFilters(),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Todas las variedades (${_filtradas.length})',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list, size: 20),
                      onPressed: () {}, // Icono de filtro flotante
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _filtradas.length,
                  itemBuilder: (context, index) {
                    return _buildVarietyCard(_filtradas[index]);
                  },
                ),
              ),
            ],
          ),

          // Pestaña 2: MI COLECCIÓN PERSONAL
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Aquí se mostrará tu colección personal.'),
                ElevatedButton(
                  onPressed: _abrirCamara,
                  child: const Text('Añadir nueva variedad'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}