import 'package:flutter/material.dart';

class ForoPage extends StatefulWidget {
  const ForoPage({super.key});

  @override
  State<ForoPage> createState() => _ForoPageState();
}

class _ForoPageState extends State<ForoPage> with SingleTickerProviderStateMixin {
  
  late TabController _tabController;

  // Datos de publicación de prueba (simulando lo que vendría del backend)
  final List<Map<String, dynamic>> _publicaciones = [
    {
      'id': 1,
      'user': 'Tú',
      'time': 'Hace 5 días',
      'text': '¡Hoy he visitado una bodega y he reconocido tres variedades gracias a la app!',
      'image': null,
      'likes': 1,
      'comments': 2,
      'is_thread_starter': false,
    },
    {
      'id': 2,
      'user': 'Tú',
      'time': 'Hace 9 días',
      'text': 'Mi viña tiene puntos negros en las hojas, ¿puede ser una enfermedad?',
      'image': 'assets/hoja_negra.jpg', // Usar una imagen de tu carpeta assets
      'likes': 2,
      'comments': 3,
      'is_thread_starter': true,
    },
    {
      'id': 3,
      'user': 'Tú',
      'time': 'Hace 2 semanas',
      'text': 'Estoy aprendiendo sobre las cepas autóctonas de Murcia. Me gustaría conocer cuáles son más resistentes a la sequía.',
      'image': null,
      'likes': 1,
      'comments': 1,
      'is_thread_starter': false,
    },
    {
      'id': 4,
      'user': 'Tú',
      'time': 'Hace 1 mes',
      'text': 'Hoy he visto una vid creciendo junto a un olivo. La app me ha dicho que podría ser Monastrell.',
      'image': 'assets/olivo_vid.jpg', // Usar una imagen de tu carpeta assets
      'likes': 3,
      'comments': 2,
      'is_thread_starter': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- WIDGET DE LA TARJETA DE PUBLICACIÓN ---

  Widget _buildPostCard(Map<String, dynamic> post) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER (Foto de perfil y Usuario)
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.green, // Color verde para simular la imagen
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['user'] ?? 'Anónimo',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      post['time'] ?? 'Ahora',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. CONTENIDO DEL TEXTO
            Text(
              post['text'] ?? '',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),

            // 3. IMAGEN (Si existe)
            if (post['image'] != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Aquí se usaría Image.file(File(post['image'])) o Image.network(post['image'])
                    // Usamos un Container como placeholder para simular la imagen
                    Container(
                      height: 150,
                      color: Colors.grey.shade300,
                      child: Center(
                          child: Text(
                        'Imagen: ${post['image']}',
                        style: TextStyle(color: Colors.grey.shade600),
                      )),
                    ),
                    // Botón "Crear hilo" superpuesto si es necesario (como en la segunda imagen)
                    if (post['is_thread_starter'])
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Crear hilo', style: TextStyle(fontSize: 16)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 4. FOOTER (Contadores y Botones de Interacción)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Me Gusta (Corazón)
                Row(
                  children: [
                    const Icon(Icons.favorite_border, size: 20),
                    const SizedBox(width: 4),
                    Text(post['likes'].toString()),
                  ],
                ),
                const SizedBox(width: 16),
                // Comentarios (Burbuja de chat)
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 20),
                    const SizedBox(width: 4),
                    Text(post['comments'].toString()),
                  ],
                ),
                const SizedBox(width: 16),
                // Compartir
                const Icon(Icons.share, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- ESTRUCTURA PRINCIPAL DEL FORO ---

  @override
  Widget build(BuildContext context) {
    // Filtrar 'Tus hilos' (simulación: publicaciones donde is_thread_starter es verdadero)
    final List<Map<String, dynamic>> misHilos = _publicaciones
        .where((p) => p['user'] == 'Tú') // Se asume que 'Tú' es el usuario actual
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidad'),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Icon(Icons.search, size: 26),
          ),
        ],
        // Botones de Tab (Todos / Tus hilos)
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
                  color: Colors.black, // Color sólido al seleccionar
                ),
                labelColor: Colors.white, // Texto blanco para pestaña activa
                unselectedLabelColor: Colors.black, // Texto negro para pestañas inactivas
                tabs: const [
                  Tab(text: 'Todos'),
                  Tab(text: 'Tus hilos'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Pestaña 'Todos' (Todas las publicaciones)
          ListView(
            children: _publicaciones.map((post) => _buildPostCard(post)).toList(),
          ),

          // 2. Pestaña 'Tus hilos' (Publicaciones del usuario actual)
          ListView(
            children: misHilos.map((post) => _buildPostCard(post)).toList(),
          ),
        ],
      ),
    );
  }
}