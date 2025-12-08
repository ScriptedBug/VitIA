import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/user_sesion.dart';
import '../../core/api_client.dart';
import '../../core/services/api_config.dart';
import 'detalle_variedad_page.dart'; 
import '../../pages/capture/foto_page.dart';
import '../../pages/main_layout/home_page.dart';
import 'detalle_coleccion_page.dart'; // <--- AÑADE ESTO


class CatalogoPage extends StatefulWidget { // ⬅️ CLASE RENOMBRADA A CATÁLOGO
  final int initialTab; 
  final ApiClient? apiClient;
  const CatalogoPage({super.key, this.initialTab = 0, this.apiClient,}); 

  @override
  State<CatalogoPage> createState() => _CatalogoPageState(); // ⬅️ ESTADO RENOMBRADO A CATÁLOGO
}

class _CatalogoPageState extends State<CatalogoPage> with SingleTickerProviderStateMixin { // ⬅️ ESTADO RENOMBRADO A CATÁLOGO
  
  // --- VARIABLES DE ESTADO Y CONTROL ---
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  // Variables del estado original (mantidas para la lógica)
  bool _modoOscuro = false;
  // 1. AÑADE ESTAS VARIABLES
  List<Map<String, dynamic>> _variedades = []; 
  List<Map<String, dynamic>> _coleccionUsuario = [];

  List<Map<String, dynamic>> _filtradas = [];
  List<Map<String, dynamic>> _filtradasColeccion = [];

  bool _isLoading = true;
  ApiClient? _apiClient; // Usa ? para evitar problemas de late si algo falla

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = widget.initialTab;

    // 1. INYECCIÓN DE DEPENDENCIAS
    // Si el test nos pasa un cliente falso (mock), usamos ese. Si no, el real.
    _apiClient = widget.apiClient ?? ApiClient(getBaseUrl());

    // 2. CORRECCIÓN DEL CICLO DE VIDA (CRÍTICO PARA TESTS)
    // Usamos addPostFrameCallback para esperar a que la UI se construya antes de cargar.
    // Esto permite mostrar el SnackBar de error sin que falle el test.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (UserSession.token != null) {
        _apiClient!.setToken(UserSession.token!);
        _cargarTodo(); // Carga ambas listas (Biblioteca + Colección)
      } else {
        _cargarSoloBiblioteca(); // Carga solo la pública
      }
    });
  }

  Future<void> _cargarTodo() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _cargarVariedadesBackend(),
      _cargarColeccionBackend(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _cargarSoloBiblioteca() async {
    setState(() => _isLoading = true);
    await _cargarVariedadesBackend();
    setState(() => _isLoading = false);
  }
  // 3. AÑADE ESTE MÉTODO
  Future<void> _cargarVariedadesBackend() async {
    // 1. Aseguramos que se muestre el spinner de carga al empezar
    setState(() => _isLoading = true); 

    try {
      final lista = await _apiClient!.getVariedades();
      
      setState(() {
        _variedades = lista.map((item) {
           return {
             'id': item['id_variedad'],
             'nombre': item['nombre'],
             'descripcion': item['descripcion'],
             'region': 'España', 
             'tipo': item['color'] ?? 'Desconocido',
             'imagen': (item['links_imagenes'] != null && (item['links_imagenes'] as List).isNotEmpty)
                 ? item['links_imagenes'][0] 
                 : null,
              'morfologia': item['morfologia'], 
              'info_extra': item['info_extra'],
           };
        }).toList().cast<Map<String, dynamic>>();
        
        _filtradas = _variedades;
        // _isLoading = false; // LO QUITAMOS DE AQUÍ (se hace en finally)
      });
    } catch (e) {
      debugPrint("Error cargando catálogo: $e");
      
      // --- CORRECCIÓN VISUAL ---
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error de conexión: No se pudieron cargar las viñas'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Reintentar', 
              textColor: Colors.white,
              onPressed: _cargarVariedadesBackend // Botón para probar otra vez
            ),
          ),
        );
      }
    } finally {
      // --- ESTO ASEGURA QUE EL CIRCULITO DEJE DE GIRAR SIEMPRE ---
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cargarColeccionBackend() async {
    try {
      final lista = await _apiClient!.getUserCollection();
      
      setState(() {
        _coleccionUsuario = lista.map((item) {
           // ... (tu código de mapeo se mantiene igual) ...
           final variedadData = item['variedad'] ?? {};
           return {
             // ... tus campos ...
             'id': item['id_coleccion'], 
             'nombre': variedadData['nombre'] ?? 'Sin nombre',
             'descripcion': item['notas'] ?? variedadData['descripcion'],
             'region': 'Mi Bodega', 
             'tipo': variedadData['color'] ?? 'Personal',
             'imagen': item['path_foto_usuario'], 
             'morfologia': variedadData['morfologia'],
             'fecha_captura': item['fecha_captura'],
             'latitud': item['latitud'],
             'longitud': item['longitud'],
             'es_local': false,
           };
        }).toList().cast<Map<String, dynamic>>();
        
        _filtradasColeccion = _coleccionUsuario;
      });
    } catch (e) {
      debugPrint("Error cargando colección: $e");
      // Feedback visual también aquí
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar tu colección')),
        );
      }
    }
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
      // Filtramos la lista activa según la pestaña
      if (_tabController.index == 0) {
        _filtradas = _variedades
            .where((v) => v['nombre'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      } else {
        _filtradasColeccion = _coleccionUsuario
            .where((v) => v['nombre'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

 
  void _abrirCamara() {
    // Navegamos directamente a la pantalla de cámara (FotoPage)
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FotoPage()),
    ).then((_) {
      // Opcional: Cuando vuelvas de la cámara, recargar la lista por si guardaste algo nuevo
      _cargarVariedadesBackend(); 
    });
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

  Widget _buildVarietyCard(Map<String, dynamic> variedad,{bool isColeccion = false}) {
    final bool isBlanca = variedad['tipo'] == 'Blanca';
    final String? imagenPath = variedad['imagen'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(
          onTap: () async { // Hazlo async
            if (isColeccion) {
              final resultado = await Navigator.push( // Espera el resultado
                context,
                MaterialPageRoute(
                  builder: (context) => DetalleColeccionPage(coleccionItem: variedad),
                ),
              );
              
              // Si devolvió 'true', significa que borramos o editamos algo -> Recargar lista
              if (resultado == true) {
                _cargarColeccionBackend(); 
              }
            } else {
              // SI ES BIBLIOTECA -> Navega a la página original con morfología
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetalleVariedadPage(variedad: variedad),
                ),
              );
            }
          },
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
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        variedad['nombre'],
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                // Miniatura de imagen
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: imagenPath != null 
                    ? Image.network(
                        imagenPath, 
                        width: 70, height: 70, 
                        fit: BoxFit.cover,
                        errorBuilder: (c,e,s) => Container(width:70, height:70, color:Colors.grey[300], child: const Icon(Icons.broken_image)),
                      )
                    : Container(width:70, height:70, color:Colors.grey[300], child: const Icon(Icons.wine_bar)),
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
          UserSession.token == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Inicia sesión para ver tu colección"),
                      ElevatedButton(
                        onPressed: () {
                           // Navegar a Login si no hay token (opcional)
                        }, 
                        child: const Text("Ir a Login")
                      )
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("Mis Capturas (${_filtradasColeccion.length})", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                    Expanded(
                      child: _filtradasColeccion.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.wine_bar, size: 50, color: Colors.grey),
                                const SizedBox(height: 10),
                                const Text('Tu colección está vacía.'),
                                TextButton(
                                  onPressed: _abrirCamara,
                                  child: const Text('¡Escanea tu primera variedad!'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filtradasColeccion.length,
                            itemBuilder: (context, index) => _buildVarietyCard(_filtradasColeccion[index], isColeccion: true),
                          ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}