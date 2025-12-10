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
import 'detalle_coleccion_page.dart'; 
import 'user_variety_detail_page.dart'; // <--- NUEVA PÁGINA


class CatalogoPage extends StatefulWidget { // ⬅️ CLASE RENOMBRADA A CATÁLOGO
  final int initialTab; 
  final ApiClient? apiClient;
  final VoidCallback? onCameraTap; // CAMBIO: Callback para navegación externa

  const CatalogoPage({super.key, this.initialTab = 0, this.apiClient, this.onCameraTap}); 

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
  
  // Modificado: Ahora _coleccionUsuario y _filtradasColeccion serán una lista de ÚNICOS (representantes)
  // para mostrar en la lista agrupada.
  List<Map<String, dynamic>> _filtradasColeccion = [];
  
  // Nuevo: Mapa para guardar todos los items agrupados por nombre de variedad
  Map<String, List<Map<String, dynamic>>> _mapaVariedadesUsuario = {};

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
      
      final List<Map<String, dynamic>> todosLosItems = lista.map((item) {
           final variedadData = item['variedad'] ?? {};
           return {
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
             'variedad_original': variedadData, // Guardamos info extra
           };
      }).toList().cast<Map<String, dynamic>>();

      // 1. Agrupar por nombre
      final Map<String, List<Map<String, dynamic>>> agrupado = {};
      for (var item in todosLosItems) {
        final nombre = item['nombre'];
        if (!agrupado.containsKey(nombre)) {
          agrupado[nombre] = [];
        }
        agrupado[nombre]!.add(item);
      }

      // 2. Crear lista de representantes (uno por cada clave del mapa)
      final List<Map<String, dynamic>> representantes = [];
      agrupado.forEach((key, valor) {
        // Usamos el primero como representante visual
        representantes.add(valor.first);
      });

      setState(() {
        _coleccionUsuario = representantes; // Esto ahora es la lista de GRUPOS
        _mapaVariedadesUsuario = agrupado;
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
    // CAMBIO: Si se proporciona callback, úsalo para cambiar de tab.
    if (widget.onCameraTap != null) {
      widget.onCameraTap!();
    } else {
      // Fallback a navegación antigua (por si acaso)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FotoPage()),
      ).then((_) {
        _cargarVariedadesBackend(); 
      });
    }
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
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
           Container(
            padding: const EdgeInsets.all(10), // Padding para que el icono no toque los bordes
            decoration: BoxDecoration(
              color: Colors.grey.shade100, // Color de fondo gris claro
              shape: BoxShape.circle, // Forma circular
            ),
            child: InkWell( // InkWell para el efecto de splash al pulsar (opcional)
              onTap: () {
                 // Lógica para abrir filtros
              },
              customBorder: const CircleBorder(), // Asegura que el splash sea circular
              child: const Icon(
                Icons.sort,
                color: Colors.black54,
                size: 24, // Tamaño del icono
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- NUEVOS WIDGETS PARA FAVORITOS Y HEADER ---

  Widget _buildFavoritosSection() {
    // Datos mockeados para la visualización
    final favoritos = [
      {'nombre': 'Merseguera', 'imagen': 'assets/icons/Propiedad2=hoja.png'},
      {'nombre': 'Trepadell', 'imagen': 'assets/icons/Propiedad2=racimo.png'},
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151B18), // Dark green/black background
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.favorite_border, color: Colors.white70, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Favoritos",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Text(
                "${favoritos.length}",
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180, // Altura fija para el scroll horizontal
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: favoritos.length + 1, // +1 para el visual de "corte"
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index == favoritos.length) {
                   // Elemento extra p/ efecto visual
                   return const SizedBox(width: 20); 
                }
                return _buildFavoritoCard(favoritos[index]);
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFavoritoCard(Map<String, dynamic> item) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Align(
            alignment: Alignment.topRight,
            child: Icon(Icons.favorite, color: Colors.black, size: 18),
          ),
          Image.asset(
            item['imagen']!,
            height: 80,
            fit: BoxFit.contain,
            errorBuilder: (_,__,___) => const Icon(Icons.grass, size: 50),
          ),
          Text(
            item['nombre']!,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Widget específico para el diseño de tarjetas de "Tus Variedades" (Agrupadas)
  Widget _buildCollectionGroupCard(Map<String, dynamic> item) {
    // Buscamos cuántas tienes
    final nombre = item['nombre'];
    final cantidad = _mapaVariedadesUsuario[nombre]?.length ?? 0;
    final bool isBlanca = item['tipo'] == 'Blanca';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container( // Usamos Container para borde personalizado si se quiere
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Navegar a la NUEVA página de detalle de usuario
            final listaCapturas = _mapaVariedadesUsuario[nombre] ?? [];
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserVarietyDetailPage(
                  varietyInfo: item, 
                  captures: listaCapturas
                ),
              ),
            ).then((value) {
               // Al volver, refrescar por si borró algo
               _cargarColeccionBackend(); 
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['region'] ?? "Comunidad Valenciana", // Placeholder si es null
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.favorite, size: 20, color: Colors.black)
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  nombre,
                  style: const TextStyle(
                    fontFamily: 'Serif',
                    fontSize: 28, 
                    fontWeight: FontWeight.w400, // Letra estilo display
                    color: Color(0xFF1E2623),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isBlanca ? const Color(0xFF8B8000).withOpacity(0.8) : const Color(0xFF800020).withOpacity(0.8), // Gold/Burgundy
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item['tipo'], // "Blanca" / "Tinta"
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                if (cantidad > 1) ...[
                   const SizedBox(height: 10),
                   Text("$cantidad capturas", style: const TextStyle(color: Colors.grey, fontSize: 12)) 
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  
  @override
  Widget build(BuildContext context) {

    // Un header personalizado en lugar de AppBar
    return Scaffold(
      backgroundColor: Colors.white, // Fondo general
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER PERSONALIZADO
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                 // Decoración negra curvada superior (estilo "Isla" o Header)
                 // Como en la imagen parece un texto simple, lo dejamos simple.
                child: const Text(
                  "VitIA",
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                    letterSpacing: 1.0
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Biblioteca",
                    style: TextStyle(
                      fontFamily: 'Serif', // O usa GoogleFonts.dmSerifDisplay() si tienes el paquete
                      fontSize: 32,
                      fontWeight: FontWeight.w400, // Letra más fina/elegante
                      color: Color(0xFF1E2623),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, size: 28),
                    onPressed: () {
                      // Acción de búsqueda global si se desea
                    },
                  )
                ],
              ),
            ),

            // 2. TABS PERSONALIZADOS (Pills)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), // Más margen lateral
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2), // Gris clarito específico
                borderRadius: BorderRadius.circular(30),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab, 
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08), 
                      blurRadius: 4, 
                      offset: const Offset(0, 2)
                    )
                  ],
                ),
                labelColor: Colors.black87,
                unselectedLabelColor: Colors.grey.shade500,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                splashBorderRadius: BorderRadius.circular(30),
                padding: const EdgeInsets.all(5), // Espacio interno para que el indicador "flote"
                tabs: const [
                  Tab(text: "Todas"),
                  Tab(text: "Tus variedades"),
                ],
              ),
            ),

            // 3. CONTENIDO (TabBarView con Scroll único para la primera pestaña)
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // --- PESTAÑA 1: TODAS ---
                  CustomScrollView(
                    slivers: [
                      // Sección Favoritos (scrollea con la página)
                      SliverToBoxAdapter(
                        child: _buildFavoritosSection(),
                      ),
                      
                      // Buscador y Título "Todas las variedades"
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSearchBarAndFilters(), 
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Todas las variedades',
                                    style: TextStyle(fontSize: 18, color: Colors.grey.shade800, fontWeight: FontWeight.normal),
                                  ),
                                  const Icon(Icons.filter_list, size: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Lista de Variedades
                      _filtradas.isEmpty
                          ? SliverFillRemaining(
                              child: Center(
                                child: _isLoading 
                                  ? const CircularProgressIndicator()
                                  : const Text("No se encontraron variedades"),
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return _buildVarietyCard(_filtradas[index]);
                                },
                                childCount: _filtradas.length,
                              ),
                            ),
                      
                       // Espacio final
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),

                  // --- PESTAÑA 2: COLECCIÓN (Igual que antes) ---
                  UserSession.token == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Inicia sesión para ver tu colección"),
                              const SizedBox(height:10),
                              ElevatedButton(
                                onPressed: () {}, // Navegar login
                                child: const Text("Ir a Login")
                              )
                            ],
                          ),
                        )
                      : Column(
                          children: [
                             _buildSearchBarAndFilters(), // Buscador específico de colección
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text("Mis Capturas (${_filtradasColeccion.length})", 
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                              ),
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
                                    itemBuilder: (context, index) {
                                      // Usamos el NUEVO diseño de tarjeta agrupada
                                      return _buildCollectionGroupCard(_filtradasColeccion[index]);
                                    },
                                  ),
                            ),
                            // NUEVO: Botón estático en la parte inferior
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    offset: const Offset(0, -4),
                                    blurRadius: 10,
                                  )
                                ]
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _abrirCamara,
                                icon: const Icon(Icons.camera_alt),
                                label: const Text("Añadir Variedad"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF151B18),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

