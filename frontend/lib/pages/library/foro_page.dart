import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/services/api_config.dart';
import '../../core/services/user_sesion.dart';
import 'post_detail_page.dart';
import 'create_post_page.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/vitia_header.dart';

class ForoPage extends StatefulWidget {
  const ForoPage({super.key});

  @override
  State<ForoPage> createState() => _ForoPageState();
}

class _ForoPageState extends State<ForoPage>
    with SingleTickerProviderStateMixin {
  late ApiClient _apiClient;
  bool _isCreatingPost = false; // Estado para controlar la vista de crear post
  
  // Variables de estado restauradas
  bool _isLoading = true;
  List<Map<String, dynamic>> _publicacionesTodas = [];
  List<Map<String, dynamic>> _publicacionesMias = [];
  List<Map<String, dynamic>>? _publicacionesPopulares; // Nullable para evitar error "undefined" en hot reload
  int _selectedTab = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

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
          // 1. Obtener UserID si no lo tenemos
          if (UserSession.userId == null) {
            final meData = await _apiClient.getMe();
            UserSession.setUserId(meData['id_usuario']);
          }

          listaMias = await _apiClient.getUserPublicaciones();
        } catch (e) {
          debugPrint("Error loading user posts: $e");
        }
      }

      if (mounted) {
        setState(() {
          _publicacionesTodas = _mapearPublicaciones(listaTodas);
          _publicacionesMias = _mapearPublicaciones(listaMias);
          
          // Crear lista de populares ordenada por Likes DESC, luego Comentarios DESC
          _publicacionesPopulares = List<Map<String, dynamic>>.from(_publicacionesTodas);
          _publicacionesPopulares!.sort((a, b) {
            final likesA = (a['likes'] as num?)?.toInt() ?? 0;
            final likesB = (b['likes'] as num?)?.toInt() ?? 0;
            final compareLikes = likesB.compareTo(likesA); // Descendente
            
            if (compareLikes != 0) {
              return compareLikes;
            } else {
              // Si empata en likes, ordenar por comentarios
              final commentsA = (a['comments'] as num?)?.toInt() ?? 0;
              final commentsB = (b['comments'] as num?)?.toInt() ?? 0;
              return commentsB.compareTo(commentsA); // Descendente
            }
          });

          debugPrint("Foro loaded. All: ${_publicacionesTodas.length}, Popular: ${_publicacionesPopulares?.length}");
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading forum: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _mapearPublicaciones(List<dynamic> rawList) {
    return rawList
        .map((item) {
          String? imagenUrl;
          if (item['links_fotos'] != null &&
              (item['links_fotos'] as List).isNotEmpty) {
            imagenUrl = item['links_fotos'][0];
          }

          String nombreUsuario = "Anónimo";
          int? authorId; // Para verificar isMine

          if (item['autor'] != null) {
            final autor = item['autor'];
            nombreUsuario =
                "${autor['nombre'] ?? 'Usuario'} ${autor['apellidos'] ?? ''}"
                    .trim();
            authorId = autor['id_usuario'];
          } else if (item['id_usuario'] != null) {
            // Fallback si la API devuelve id_usuario en root
            nombreUsuario = "Usuario #${item['id_usuario']}";
            authorId = item['id_usuario'];
          }

          return {
            'id': item['id_publicacion'],
            'titulo': item['titulo'] ?? '',
            'text': item['texto'] ?? '',
            'user': nombreUsuario,
            'time': _formatearFecha(
                item['fecha_publicacion'] ?? item['fecha_creacion']),
            'image': imagenUrl,
            'likes': item['likes'] ?? 0,
            'comments': (item['comentarios'] as List?)?.length ?? 0,
            'isMine': authorId != null && authorId == UserSession.userId,
            'isLiked': item['is_liked'] ?? false,
          };
        })
        .toList()
        .cast<Map<String, dynamic>>();
  }

  List<Map<String, dynamic>> _getFilteredList(List<Map<String, dynamic>> list) {
    if (_searchQuery.isEmpty) return list;
    return list.where((post) {
      final title = post['titulo'].toString().toLowerCase();
      final content = post['text'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || content.contains(query);
    }).toList();
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
          const SnackBar(content: Text("Debes iniciar sesión para publicar.")));
      return;
    }
    // Cambiamos el estado para mostrar la vista de creación embebida
    setState(() => _isCreatingPost = true);
  }


  Widget build(BuildContext context) {
    // Si estamos creando un post, interceptamos el "Back" para solo cerrar el modo de creación
    return PopScope(
      canPop: !_isCreatingPost,
      onPopInvoked: (didPop) {
        if (didPop) return;
        setState(() => _isCreatingPost = false);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: Stack(
          children: [
            // CONTENIDO PRINCIPAL (Normal)
            Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: Column(
                children: [
                  // 1. HEADER GRANDE (FIJO)
                  // 1. HEADER GRANDE (FIJO)
                  VitiaHeader(
                    title: "Comunidad",
                    actionIcon: IconButton(
                      icon: Icon(_isSearching ? Icons.close : Icons.search, size: 28),
                      onPressed: () {
                        setState(() {
                          if (_isSearching) {
                            _isSearching = false;
                            _searchQuery = "";
                            _searchController.clear();
                          } else {
                            _isSearching = true;
                          }
                        });
                      },
                    ),
                  ),

                  // BARRA DE BÚSQUEDA (Visible si _isSearching es true)
                  if (_isSearching)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: "Buscar por título...",
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = "");
                            },
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),

                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        // 2. TABS
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
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

                        // 3. POPULARES
                        if (_selectedTab == 0) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                              child: Text("Populares",
                                  style: GoogleFonts.lora(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2A2A2A))),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 180,
                              child: _isLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      itemCount: _getFilteredList(_publicacionesPopulares ?? []).take(5).length,
                                      itemBuilder: (context, index) {
                                        final filtered = _getFilteredList(_publicacionesPopulares ?? []);
                                        return _PopularCard(
                                          post: filtered[index],
                                          onTap: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) => PostDetailPage(
                                                      post: filtered[index])),
                                            );
                                            if (result == true && mounted) {
                                              _cargarDatos();
                                            }
                                          },
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ],

                        // 4. RECIENTES (Encabezado)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                            child: Text("Recientes",
                                style: GoogleFonts.lora(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2A2A2A))),
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 10)),

                        // 6. LISTA VERTICAL
                        _isLoading
                            ? const SliverToBoxAdapter(
                                child: SizedBox(
                                    height: 200,
                                    child: Center(child: CircularProgressIndicator())))
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final activeList = _selectedTab == 0
                                        ? _publicacionesTodas
                                        : _publicacionesMias;
                                    final filteredList = _getFilteredList(activeList);
                                    return _RecentCard(
                                      post: filteredList[index],
                                      onTap: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => PostDetailPage(
                                                  post: filteredList[index])),
                                        );
                                        if (result == true && mounted) {
                                          _cargarDatos();
                                        }
                                      },
                                    );
                                  },
                                  childCount: _getFilteredList(_selectedTab == 0
                                          ? _publicacionesTodas
                                          : _publicacionesMias)
                                      .length,
                                ),
                              ),

                        const SliverToBoxAdapter(child: SizedBox(height: 160)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // BOTÓN FLOTANTE CREAR HILO (Visible solo si no estamos creando)
            if (!_isCreatingPost)
              Positioned(
                bottom: 110,
                left: 20,
                right: 20,
                child: ElevatedButton(
                  onPressed: _mostrarDialogoCrear,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7A7A30),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    elevation: 4,
                    shadowColor: const Color(0xFF7A7A30).withOpacity(0.4),
                  ),
                  child: const Text("Crear hilo",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

             // VISTA DE CREACIÓN DE POST (SUPERPUESTA)
            if (_isCreatingPost)
              Positioned.fill(
                child: Container(
                   color: Colors.white, // Cubre toda la pantalla (dentro del Scaffold)
                   child: CreatePostPage(
                     onPostCreated: () {
                       setState(() => _isCreatingPost = false);
                       _cargarDatos();
                       ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text("¡Publicación creada exitosamente!")));
                     },
                     onCancel: () {
                        setState(() => _isCreatingPost = false);
                     },
                   )
                ),
              ),
          ],
        ),
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
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ]
                : [],
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
}

// TARJETA POPULARES (Diseño Horizontal)
class _PopularCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;

  const _PopularCard({required this.post, required this.onTap});

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
    _isLiked = widget.post['isLiked'] ?? false;
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
      onTap: widget.onTap,
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 16, bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade300,
                  child:
                      const Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.post['user'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(widget.post['time'],
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade500)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            if (widget.post['titulo'] != null && widget.post['titulo'] != '') ...[
              Text(
                widget.post['titulo'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
            ],
            Expanded(
              child: Text(
                widget.post['text'],
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.grey.shade800, fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: _darLike,
                  child: Row(
                    children: [
                      Text("$_likes",
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Icon(_isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 16, color: _isLiked ? Colors.red : Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text("${widget.post['comments']}",
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                const Icon(Icons.chat_bubble_outline,
                    size: 16, color: Colors.grey),
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
  final VoidCallback onTap;

  const _RecentCard({required this.post, required this.onTap});

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
    _isLiked = widget.post['isLiked'] ?? false;
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
      onTap: widget.onTap,
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
                      Text(widget.post['user'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(widget.post['time'],
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (widget.post['titulo'] != '')
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(widget.post['titulo'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),

            Text(widget.post['text'],
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
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
                    errorBuilder: (c, e, s) =>
                        Container(height: 100, color: Colors.grey.shade100),
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
                      Text("$_likes",
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Icon(_isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 20, color: _isLiked ? Colors.red : Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text("${widget.post['comments']}",
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                const Icon(Icons.chat_bubble_outline,
                    size: 20, color: Colors.grey),
              ],
            )
          ],
        ),
      ),
    );
  }
}
