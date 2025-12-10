import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/services/api_config.dart';
import '../../core/services/user_sesion.dart';
import 'post_detail_page.dart';

class ForoPage extends StatefulWidget {
  const ForoPage({super.key});

  @override
  State<ForoPage> createState() => _ForoPageState();
}

class _ForoPageState extends State<ForoPage> with SingleTickerProviderStateMixin {
  late ApiClient _apiClient;
  bool _isLoading = true;
  List<Map<String, dynamic>> _publicacionesTodas = [];
  List<Map<String, dynamic>> _publicacionesMias = [];
  
  // Control de pestaña actual (0: Todos, 1: Tus hilos)
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(getBaseUrl());
    if (UserSession.token != null) {
      _apiClient.setToken(UserSession.token!);
    }
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final listaTodas = await _apiClient.getPublicaciones();
      
      List<dynamic> listaMias = [];
      if (UserSession.token != null) {
        try {
          listaMias = await _apiClient.getUserPublicaciones();
        } catch (e) {
          debugPrint("Error loading user posts: $e");
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
      debugPrint("Error loading forum: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _mapearPublicaciones(List<dynamic> rawList) {
    return rawList.map((item) {
      String? imagenUrl;
      if (item['links_fotos'] != null && (item['links_fotos'] as List).isNotEmpty) {
        imagenUrl = item['links_fotos'][0];
      }

      String nombreUsuario = "Anónimo";
      if (item['autor'] != null) {
        final autor = item['autor'];
        String nombre = autor['nombre'] ?? "Usuario";
        String apellidos = autor['apellidos'] ?? "";
        nombreUsuario = "$nombre $apellidos".trim();
      } else if (item['id_usuario'] != null) {
        nombreUsuario = "Usuario #${item['id_usuario']}";
      }

      return {
        'id': item['id_publicacion'],
        'titulo': item['titulo'] ?? '',
        'text': item['texto'] ?? '',
        'user': nombreUsuario,
        'time': _formatearFecha(item['fecha_publicacion'] ?? item['fecha_creacion']),
        'image': imagenUrl,
        'likes': item['likes'] ?? 0,
        'comments': (item['comentarios'] as List?)?.length ?? 0,
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
      return "Hace unos instantes";
    } catch (e) {
      return "Reciente";
    }
  }

  void _mostrarDialogoCrear() {
     if (UserSession.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes iniciar sesión para publicar."))
      );
      return;
    }

    final tituloCtrl = TextEditingController();
    final textoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nueva Publicación"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tituloCtrl,
              decoration: const InputDecoration(labelText: "Título", hintText: "Ej: Duda sobre poda..."),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textoCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Mensaje", hintText: "Escribe aquí tu consulta..."),
            ),
          ],
        ),
        actions: [
          TextButton(child: const Text("Cancelar"), onPressed: () => Navigator.pop(ctx)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7A7A30), foregroundColor: Colors.white),
            child: const Text("Publicar"),
            onPressed: () async {
              if (tituloCtrl.text.isEmpty || textoCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await _apiClient.createPublicacion(tituloCtrl.text, textoCtrl.text);
                if (mounted) {
                   _cargarDatos();
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Publicado!")));
                }
              } catch (e) {
                if(mounted) setState(() => _isLoading = false);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeList = _selectedTab == 0 ? _publicacionesTodas : _publicacionesMias;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Color fondo muy suave
      body: Stack(
        children: [
          // CONTENIDO PRINCIPAL SCROLLABLE
          CustomScrollView(
            slivers: [
              // 1. HEADER GRANDE
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "VitIA" pequeño centrado o arriba
                     const Center(
                        child: Text("VitIA", style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2
                        )),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Comunidad", style: TextStyle(
                            fontFamily: 'Serif', // O usa GoogleFonts.playfairDisplay()
                            fontSize: 34,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A)
                          )),
                          IconButton(
                            icon: const Icon(Icons.search, size: 28),
                            onPressed: () {},
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 2. TABS (Botones pastilla)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton("Todos", 0),
                      _buildTabButton("Tus hilos", 1),
                    ],
                  ),
                ),
              ),

              // 3. SECCIÓN POPULARES (Solo si estamos en 'Todos')
              if (_selectedTab == 0) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text("Populares", style: TextStyle(
                      fontFamily: 'Serif',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2A2A2A)
                    )),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 180, // Altura tarjetas populares
                    child: _isLoading 
                      ? const Center(child: CircularProgressIndicator()) 
                      : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        // Usamos la misma lista o una filtrada. Aquí dummy para ejemplo visual
                        itemCount: _publicacionesTodas.take(5).length,
                        itemBuilder: (context, index) {
                          return _PopularCard(post: _publicacionesTodas[index]);
                        },
                      ),
                  ),
                ),
              ],

              // 4. SECCIÓN RECIENTES (Encabezado)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 30, 20, 10),
                  child: Text("Recientes", style: TextStyle(
                    fontFamily: 'Serif',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2A2A2A)
                  )),
                ),
              ),

              // 5. Espaciador para la lista y botón
              const SliverToBoxAdapter(child: SizedBox(height: 10)),

              // 6. LISTA VERTICAL (RECIENTES)
              _isLoading
                ? const SliverToBoxAdapter(child: SizedBox(height: 200, child: Center(child: CircularProgressIndicator())))
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _RecentCard(post: activeList[index]);
                      },
                      childCount: activeList.length,
                    ),
                  ),

              // Espacio extra al final para que no tape el toolbar flotante ni el botón
              const SliverToBoxAdapter(child: SizedBox(height: 160)),
            ],
          ),

          // BOTÓN FLOTANTE CREAR HILO (Fijo)
          Positioned(
            bottom: 110, left: 20, right: 20,
            child: ElevatedButton(
              onPressed: _mostrarDialogoCrear,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7A7A30), // Color oliva
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 4,
                shadowColor: const Color(0xFF7A7A30).withOpacity(0.4),
              ),
              child: const Text("Crear hilo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),

          // BARRA DE NAVEGACIÓN FLOTANTE PERSONALIZADA
          Positioned(
            left: 40, right: 40, bottom: 20,
            child: _buildFloatingNavBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))] : [],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E241E), // Negro verdoso oscuro
        borderRadius: BorderRadius.circular(35),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavIcon(icon: Icons.home_outlined, isSelected: false),
          _NavIcon(icon: Icons.camera_alt_outlined, isSelected: false), // Cámara
          _NavIcon(icon: Icons.book, isSelected: true), // Foro/Comunidad (Activo)
           // Icono chat (simulado como en la imagen con burbuja)
          _NavIcon(icon: Icons.chat_bubble_outline, isSelected: false),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  const _NavIcon({required this.icon, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: isSelected 
          ? const BoxDecoration(color: Colors.white, shape: BoxShape.circle) 
          : null,
      child: Icon(
        icon, 
        color: isSelected ? Colors.black : Colors.white70,
        size: 24
      ),
    );
  }
}

// TARJETA POPULARES (Diseño Horizontal)
class _PopularCard extends StatefulWidget {
  final Map<String, dynamic> post;
  const _PopularCard({required this.post});

  @override
  State<_PopularCard> createState() => _PopularCardState();
}

class _PopularCardState extends State<_PopularCard> {
  late int _likes;
  bool _isLiked = false;
  late ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _likes = widget.post['likes'];
    _apiClient = ApiClient(getBaseUrl());
    if (UserSession.token != null) _apiClient.setToken(UserSession.token!);
  }

  Future<void> _darLike() async {
    setState(() {
      if (_isLiked) {
        _likes--;
        _isLiked = false;
      } else {
        _likes++;
        _isLiked = true;
      }
    });
    try {
      if (_isLiked) {
        await _apiClient.likePublicacion(widget.post['id']);
      } else {
        await _apiClient.unlikePublicacion(widget.post['id']);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_isLiked) {
            _likes--;
            _isLiked = false;
          } else {
            _likes++;
            _isLiked = true;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PostDetailPage(post: widget.post)),
        );
      },
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 16, bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset:const Offset(0,2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'), // Avatar dummy
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.post['user'], maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(widget.post['time'], style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(widget.post['text'], 
                maxLines: 4, 
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: _darLike,
                  child: Row(
                    children: [
                      Text("$_likes", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border, 
                        size: 16, 
                        color: _isLiked ? Colors.red : Colors.grey
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text("${widget.post['comments']}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// TARJETA RECIENTES (Diseño Vertical con imagen opcional)
class _RecentCard extends StatefulWidget {
  final Map<String, dynamic> post;
  const _RecentCard({required this.post});

  @override
  State<_RecentCard> createState() => _RecentCardState();
}

class _RecentCardState extends State<_RecentCard> {
  late int _likes;
  bool _isLiked = false;
  late ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _likes = widget.post['likes'];
    _apiClient = ApiClient(getBaseUrl());
    if (UserSession.token != null) _apiClient.setToken(UserSession.token!);
  }

  Future<void> _darLike() async {
    setState(() {
      if (_isLiked) {
        _likes--;
        _isLiked = false;
      } else {
        _likes++;
        _isLiked = true;
      }
    });
    try {
      if (_isLiked) {
        await _apiClient.likePublicacion(widget.post['id']);
      } else {
        await _apiClient.unlikePublicacion(widget.post['id']);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_isLiked) {
            _likes--;
            _isLiked = false;
          } else {
            _likes++;
            _isLiked = true;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PostDetailPage(post: widget.post)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
             Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  // Color aleatorio o imagen dummy si no hay avatar real
                  backgroundColor: Colors.brown.shade100,
                  child: const Icon(Icons.person, color: Colors.brown), 
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.post['user'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(widget.post['time'], style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            
            if (widget.post['titulo'] != '')
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(widget.post['titulo'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),

            Text(widget.post['text'], style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
            const SizedBox(height: 12),

            // Imagen opcional
            if (widget.post['image'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    widget.post['image'],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c,e,s) => Container(height: 100, color: Colors.grey.shade100),
                  ),
                ),
              ),
            
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _darLike,
                  child: Row(
                    children: [
                      Text("$_likes", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border, 
                        size: 20, 
                        color: _isLiked ? Colors.red : Colors.grey
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text("${widget.post['comments']}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey),
              ],
            )
          ],
        ),
      ),
    );
  }
}