import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/services/api_config.dart';
import '../../core/services/user_sesion.dart';

class PostDetailPage extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late ApiClient _apiClient;
  bool _isLoadingComments = true;
  List<dynamic> _comentarios = [];

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(getBaseUrl());
    if (UserSession.token != null) {
      _apiClient.setToken(UserSession.token!);
    }
    _cargarComentarios();
  }

  Future<void> _cargarComentarios() async {
    try {
      final id = widget.post['id'];
      final results = await _apiClient.getComentariosPublicacion(id);
      if (mounted) {
        setState(() {
          _comentarios = results;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text("Hilo", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CABECERA DEL AUTOR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.shade200,
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.post['user'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(widget.post['time'], style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                    ],
                  )
                ],
              ),
            ),

            // 2. CONTENIDO DEL POST
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.post['titulo'] != '')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(widget.post['titulo'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    ),
                  Text(widget.post['text'], style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. IMAGEN (Si existe)
            if (widget.post['image'] != null)
              Container(
                width: double.infinity,
                color: Colors.grey.shade100,
                child: Image.network(
                  widget.post['image'],
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const SizedBox.shrink(),
                ),
              ),
            
            // 4. BARRA DE INTERACCION
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.favorite_border, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text("${widget.post['likes']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 20),
                  const Icon(Icons.chat_bubble_outline, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text("${_comentarios.length}", style: const TextStyle(fontWeight: FontWeight.bold)), // Usamos el count real de los cargados o del feed
                ],
              ),
            ),

            const Divider(height: 1),

            // 5. SECCIÓN DE COMENTARIOS
            Padding(
              padding: const EdgeInsets.all(20),
              child: const Text("Comentarios", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),

            if (_isLoadingComments)
              const Center(child: CircularProgressIndicator())
            else if (_comentarios.isEmpty)
               const Padding(
                 padding: EdgeInsets.all(20.0),
                 child: Center(child: Text("Sé el primero en comentar.", style: TextStyle(color: Colors.grey))),
               )
            else
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                itemCount: _comentarios.length,
                separatorBuilder: (c,i) => const Divider(),
                itemBuilder: (ctx, index) {
                  final c = _comentarios[index];
                  // Ajusta según tu modelo de comentario
                  final String texto = c['texto'] ?? "";
                  final autor = c['usuario'] != null ? (c['usuario']['nombre'] ?? "Usuario") : "Anónimo";

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16, 
                          backgroundColor: Colors.grey.shade100,
                          child: Text(autor[0].toUpperCase(), style: const TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(autor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(texto, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
