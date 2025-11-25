import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/services/api_config.dart';
import '../../core/services/user_sesion.dart';
import '../auth/login_page.dart'; // Asegúrate de importar el Login si rediriges

class ForoPage extends StatefulWidget {
  const ForoPage({super.key});

  @override
  State<ForoPage> createState() => _ForoPageState();
}

class _ForoPageState extends State<ForoPage> with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  late ApiClient _apiClient;
  
  // Estado de datos
  List<Map<String, dynamic>> _publicacionesTodas = [];
  List<Map<String, dynamic>> _publicacionesMias = [];
  bool _isLoading = true;
  bool _isCreating = false; // Para mostrar carga al crear

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Inicializar API
    _apiClient = ApiClient(getBaseUrl());
    if (UserSession.token != null) {
      _apiClient.setToken(UserSession.token!);
    }

    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      // 1. Cargar Feed Global
      final listaTodas = await _apiClient.getPublicaciones();
      
      // 2. Cargar Mis Hilos (Solo si hay usuario logueado)
      List<dynamic> listaMias = [];
      if (UserSession.token != null) {
        try {
          listaMias = await _apiClient.getUserPublicaciones();
        } catch (e) {
          print("No se pudieron cargar los hilos propios: $e");
        }
      }

      if (mounted) {
        setState(() {
          _publicacionesTodas = _mapearPublicaciones(listaTodas);
          _publicacionesMias = _mapearPublicaciones(listaMias);
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error general cargando foro: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- NUEVO: DIÁLOGO PARA CREAR PUBLICACIÓN ---
  void _mostrarDialogoCrear() {
    // Verificar sesión primero
    if (UserSession.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes iniciar sesión para publicar."))
      );
      // Opcional: Redirigir al login
      // Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }

    final tituloCtrl = TextEditingController();
    final textoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nueva Publicación"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloCtrl,
                decoration: const InputDecoration(
                  labelText: "Título",
                  hintText: "Ej: Duda sobre poda...",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textoCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Mensaje",
                  hintText: "Escribe aquí tu consulta o experiencia...",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.send, size: 18),
            label: const Text("Publicar"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (tituloCtrl.text.isEmpty || textoCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("El título y el mensaje son obligatorios"))
                );
                return;
              }

              // 1. Cerrar diálogo
              Navigator.pop(ctx);

              // 2. Mostrar carga
              setState(() => _isLoading = true); // Reusamos isLoading o creamos uno nuevo

              try {
                // 3. Llamar API
                await _apiClient.createPublicacion(tituloCtrl.text, textoCtrl.text);
                
                // 4. Recargar lista y confirmar
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("¡Publicado con éxito!"), backgroundColor: Colors.green)
                  );
                  _cargarDatos(); // Recargamos para ver el nuevo post
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error al publicar: $e"), backgroundColor: Colors.red)
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // Convierte el JSON del backend al formato que necesita la UI
  List<Map<String, dynamic>> _mapearPublicaciones(List<dynamic> rawList) {
    return rawList.map((item) {
      
      String? imagenUrl;
      if (item['links_fotos'] != null && (item['links_fotos'] as List).isNotEmpty) {
        imagenUrl = item['links_fotos'][0];
      }

      String nombreUsuario = "Usuario";
      if (item['usuario'] != null && item['usuario']['nombre'] != null) {
        nombreUsuario = item['usuario']['nombre'];
      } else if (item['id_usuario'] != null) {
        nombreUsuario = "Usuario #${item['id_usuario']}";
      }

      return {
        'id': item['id_publicacion'],
        'titulo': item['titulo'] ?? 'Sin título',
        'text': item['texto'] ?? '',
        'user': nombreUsuario,
        'time': _formatearFecha(item['fecha_creacion']),
        'image': imagenUrl,
        'likes': 0, 
        'comments': 0, 
      };
    }).toList().cast<Map<String, dynamic>>();
  }

  String _formatearFecha(String? fechaIso) {
    if (fechaIso == null) return "Reciente";
    try {
      final fecha = DateTime.parse(fechaIso);
      final diferencia = DateTime.now().difference(fecha);

      if (diferencia.inDays > 0) return "Hace ${diferencia.inDays} días";
      if (diferencia.inHours > 0) return "Hace ${diferencia.inHours} h";
      if (diferencia.inMinutes > 0) return "Hace ${diferencia.inMinutes} min";
      return "Ahora mismo";
    } catch (e) {
      return "Reciente";
    }
  }

  Future<void> _borrarPublicacion(int id) async {
    // Diálogo de confirmación opcional
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminar"),
        content: const Text("¿Seguro que quieres borrar esta publicación?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Borrar", style: TextStyle(color: Colors.red))),
        ],
      )
    );

    if (confirmar != true) return;

    try {
      await _apiClient.deletePublicacion(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Publicación eliminada")));
        _cargarDatos(); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No puedes borrar esto (Solo el autor puede)"), backgroundColor: Colors.orange));
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- WIDGETS UI ---

  Widget _buildPostCard(Map<String, dynamic> post, {bool esMio = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal.shade100,
                  child: Icon(Icons.person, color: Colors.teal.shade800, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post['user'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(post['time'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                if (esMio)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    onPressed: () => _borrarPublicacion(post['id']),
                  )
              ],
            ),
            const SizedBox(height: 12),

            // TÍTULO Y TEXTO
            if (post['titulo'] != 'Sin título')
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text(post['titulo'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            Text(post['text'], style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 12),

            // IMAGEN
            if (post['image'] != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  post['image'],
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c,e,s) => Container(height: 150, color: Colors.grey.shade200, child: const Center(child: Icon(Icons.broken_image))),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // FOOTER INTERACCIONES
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.favorite_border, size: 20, color: Colors.grey),
                const SizedBox(width: 4),
                Text("${post['likes']}"),
                const SizedBox(width: 16),
                const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey),
                const SizedBox(width: 4),
                Text("${post['comments']}"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidad'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // 1. BOTÓN CREAR PUBLICACIÓN (Movido aquí)
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28, color: Colors.black),
            tooltip: "Nueva publicación",
            onPressed: _mostrarDialogoCrear,
          ),
          // 2. BOTÓN REFRESCAR
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refrescar",
            onPressed: _cargarDatos,
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Colors.black,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black,
                tabs: const [
                  Tab(text: 'Todos'),
                  Tab(text: 'Mis Hilos'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              // Pestaña 1: TODOS
              _publicacionesTodas.isEmpty
                  ? const Center(child: Text("No hay publicaciones aún."))
                  : RefreshIndicator( // Añadido 'tira para refrescar'
                      onRefresh: _cargarDatos,
                      child: ListView.builder(
                        itemCount: _publicacionesTodas.length,
                        itemBuilder: (ctx, i) => _buildPostCard(_publicacionesTodas[i]),
                      ),
                    ),

              // Pestaña 2: MIS HILOS
              _publicacionesMias.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("No has publicado nada todavía."),
                          TextButton(onPressed: _mostrarDialogoCrear, child: const Text("Crear mi primer post"))
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarDatos,
                      child: ListView.builder(
                        itemCount: _publicacionesMias.length,
                        itemBuilder: (ctx, i) => _buildPostCard(_publicacionesMias[i], esMio: true),
                      ),
                    ),
            ],
          ),
      // ELIMINADO EL FLOATING ACTION BUTTON DE AQUÍ
    );
  }
}