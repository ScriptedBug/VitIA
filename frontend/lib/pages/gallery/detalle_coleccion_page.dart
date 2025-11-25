import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/api_client.dart';
import '../../core/services/api_config.dart';
import '../../core/services/user_sesion.dart';

class DetalleColeccionPage extends StatefulWidget {
  final Map<String, dynamic> coleccionItem;

  const DetalleColeccionPage({super.key, required this.coleccionItem});

  @override
  State<DetalleColeccionPage> createState() => _DetalleColeccionPageState();
}

class _DetalleColeccionPageState extends State<DetalleColeccionPage> {
  late Map<String, dynamic> _itemActual;
  late ApiClient _apiClient;
  
  bool _isUpdating = false;
  late TextEditingController _notasController;
  LatLng? _ubicacionActual;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _itemActual = Map.from(widget.coleccionItem);
    _notasController = TextEditingController(text: _itemActual['descripcion']);

    if (_itemActual['latitud'] != null && _itemActual['longitud'] != null) {
      _ubicacionActual = LatLng(
        (_itemActual['latitud'] as num).toDouble(),
        (_itemActual['longitud'] as num).toDouble(),
      );
    }

    _apiClient = ApiClient(getBaseUrl());
    if (UserSession.token != null) {
      _apiClient.setToken(UserSession.token!);
    }
  }

  @override
  void dispose() {
    _notasController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // --- GUARDAR CAMBIOS ---
  Future<void> _guardarCambios() async {
    setState(() => _isUpdating = true);
    try {
      final updates = <String, dynamic>{
        'notas': _notasController.text,
      };
      if (_ubicacionActual != null) {
        updates['latitud'] = _ubicacionActual!.latitude;
        updates['longitud'] = _ubicacionActual!.longitude;
      }

      await _apiClient.updateCollectionItem(_itemActual['id'], updates);

      setState(() {
        _itemActual['descripcion'] = _notasController.text;
        _isUpdating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cambios guardados"), backgroundColor: Colors.green),
        );
        // Devolvemos true para indicar que hubo cambios
        Navigator.pop(context, true); 
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // --- ELIMINAR ITEM ---
  Future<void> _confirmarEliminacion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminar captura"),
        content: const Text("¿Estás seguro de que quieres borrar esta variedad de tu colección? Esta acción no se puede deshacer."),
        actions: [
          TextButton(child: const Text("Cancelar"), onPressed: () => Navigator.pop(ctx, false)),
          TextButton(
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _apiClient.deleteCollectionItem(_itemActual['id']);
        if (mounted) {
          Navigator.pop(context, true); // Volver al catálogo indicando cambio
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Eliminado correctamente")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al eliminar: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorTema = Colors.teal.shade700;
    
    String fechaTexto = "Fecha desconocida";
    if (_itemActual['fecha_captura'] != null) {
      try {
        final fecha = DateTime.parse(_itemActual['fecha_captura'].toString());
        fechaTexto = "${fecha.day}/${fecha.month}/${fecha.year}";
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            backgroundColor: colorTema,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              // Botón ELIMINAR
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: "Eliminar",
                onPressed: _isUpdating ? null : _confirmarEliminacion,
              ),
              // Botón GUARDAR
              IconButton(
                icon: _isUpdating 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save),
                onPressed: _isUpdating ? null : _guardarCambios,
                tooltip: "Guardar cambios",
              )
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _itemActual['nombre'] ?? 'Sin Nombre',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black45, blurRadius: 10)]),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImagen(_itemActual),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FECHA
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: colorTema),
                      const SizedBox(width: 8),
                      Text("Capturado: $fechaTexto", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // NOTAS
                  const Text("Mis Notas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notasController,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: "Escribe tus notas...",
                      filled: true, fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // MAPA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Ubicación", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (_ubicacionActual != null)
                        Text("${_ubicacionActual!.latitude.toStringAsFixed(4)}, ${_ubicacionActual!.longitude.toStringAsFixed(4)}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _ubicacionActual ?? const LatLng(40.4168, -3.7038), 
                          initialZoom: 13.0,
                          onTap: (_, point) => setState(() => _ubicacionActual = point),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.vinas.app',
                          ),
                          if (_ubicacionActual != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _ubicacionActual!,
                                  width: 40, height: 40,
                                  child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text("Toca el mapa para cambiar la posición.", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagen(Map<String, dynamic> item) {
    final String? path = item['imagen'];
    if (path == null || path.isEmpty) return Container(color: Colors.grey.shade300);
    return Image.network(path, fit: BoxFit.cover);
  }
}