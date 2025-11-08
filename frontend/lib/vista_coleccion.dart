import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';


class VistaColeccion extends StatefulWidget {
  const VistaColeccion({super.key});

  @override
  State<VistaColeccion> createState() => _VistaColeccionState();
}

class _VistaColeccionState extends State<VistaColeccion> {
  bool _modoOscuro = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _variedades = [];
  List<Map<String, dynamic>> _filtradas = [];

  @override
  void initState() {
    super.initState();
    _variedades = [
      {
        'nombre': 'Tempranillo',
        'imagen': 'assets/hoja1.jpg',
        'descripcion': 'Uva tinta típica de La Rioja.',
        'ubicacion': 'La Rioja, España'
      },
      {
        'nombre': 'Albariño',
        'imagen': 'assets/hoja2.jpg',
        'descripcion': 'Variedad blanca de Galicia.',
        'ubicacion': 'Rías Baixas, España'
      },
    ];
    _filtradas = List.from(_variedades);
  }

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

    if(statusCamara.isDenied || statusUbicacion.isDenied){
      if(!mounted){return;}
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permisos de cámara y ubicación son necesarios.")),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? foto = await picker.pickImage(source: ImageSource.camera);
    
    if (foto == null) {return;}

    //Obtener ubicación actual
    Position? posicion;
    try{
      posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch(e){
      print("Error obteniendo ubicación: $e");
    }

    String ubicacionTexto = "Ubicación no disponible";
    if(posicion != null){
      ubicacionTexto = "Lat: ${posicion.latitude}, Lon: ${posicion.longitude}";
    }
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
          // Imagen principal
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

          // Fila con título centrado y botones a la derecha
          Row(
            children: [
              // Espaciador para centrar el título visualmente
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

          // Descripción
          Text(
            variedad['descripcion']?.isNotEmpty == true
                ? variedad['descripcion']
                : "Sin descripción disponible",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 10),

          // Ubicación
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

  @override
  Widget build(BuildContext context) {
    final theme = _modoOscuro ? ThemeData.dark() : ThemeData.light();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Colección Personal'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _alternarTema,
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: _filtrar,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar variedad...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _filtradas.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _filtradas.length) {
                      return GestureDetector(
                        onTap: _abrirCamara,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey, width: 2),
                          ),
                          child: const Center(
                            child: Icon(Icons.add, size: 40),
                          ),
                        ),
                      );
                    }

                    final variedad = _filtradas[index];
                    final img = variedad['imagen'];

                    return GestureDetector(
                      onTap: () => _mostrarFichaTecnica(variedad),
                      child: Column(
                        children: [
                          ClipOval(
                            child: Image.asset(
                              img,
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            variedad['nombre'],
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
