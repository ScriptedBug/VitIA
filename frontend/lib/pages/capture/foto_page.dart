import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:image_picker/image_picker.dart';
import '../../core/api_client.dart';
import '../../core/services/api_config.dart';
import '../../core/models/prediction_model.dart';
import '../../core/services/user_sesion.dart';

class FotoPage extends StatefulWidget {
  const FotoPage({super.key});

  @override
  State<FotoPage> createState() => _FotoPageState();
}

class _FotoPageState extends State<FotoPage> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _useSimulatedCamera = false;
  bool _isAnalyzing = false;
  
  List<PredictionModel>? _predictions;
  
  // En web usamos bytes o XFile, en móvil File. 
  // Para simplificar la visualización en esta variable:
  XFile? _galleryImage; 
  
  late ApiClient _apiClient;
  late AnimationController _loadingController;
  final ImagePicker _picker = ImagePicker();

  final String _fallbackImage = 'https://images.unsplash.com/photo-1596244956306-a9df17907407?q=80&w=1974&auto=format&fit=crop';

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(getBaseUrl());
    if (UserSession.token != null) {
    _apiClient.setToken(UserSession.token!);
    debugPrint("Token configurado en FotoPage");
  } else {
    debugPrint("⚠️ ADVERTENCIA: No hay token de sesión. El guardado fallará.");
  }
    _initCamera();
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _useSimulatedCamera = true);
        return;
      }
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      try {
        await _cameraController!.lockCaptureOrientation(DeviceOrientation.portraitUp);
      } catch (_) {}
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint("Error cámara: $e");
      if (mounted) setState(() => _useSimulatedCamera = true);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  // --- MODIFICADO: Ahora recibe XFile ---
  Future<void> _analyzeImage(XFile imageFile) async {
    setState(() {
      _isAnalyzing = true;
      _predictions = null;
    });

    try {
      // Simulación solo si NO tenemos imagen real y estamos en modo simulado
      // Pero si viene de galería (imageFile), intentamos enviarla siempre.
      if (_useSimulatedCamera && _galleryImage == null && imageFile.path == "simulated_path") {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() {
             _predictions = [
               PredictionModel(variedad: "Tempranillo (Simulado)", confianza: 98.5),
               PredictionModel(variedad: "Garnacha", confianza: 12.4),
             ];
             _isAnalyzing = false;
          });
        }
        return;
      }

      // Llamada a la API pasando el XFile
      final results = await _apiClient.predictImage(imageFile);
      
      if (mounted) {
        setState(() {
          _predictions = results;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  XFile? _capturedPhoto;

  Future<void> _takePhoto() async {
    if (_isAnalyzing) return;
    if (!_isCameraInitialized && !_useSimulatedCamera) return;

    try {
      
      final XFile photo = await _cameraController!.takePicture();
      setState(() => _capturedPhoto = photo);
      _analyzeImage(photo); // Pasamos el XFile directamente
      
    } catch (e) {
      debugPrint("Error taking photo: $e");
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isAnalyzing) return;
    
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _galleryImage = image; // Guardamos el XFile
        });
        _analyzeImage(image); // Pasamos el XFile directamente
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _resetScanner() {
    setState(() {
      _predictions = null;
      _isAnalyzing = false;
      _galleryImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const double navBarHeight = 100.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. FONDO
          if (_galleryImage != null)
             // En Web Image.file falla, usamos Image.network con path o Image.memory si fuera necesario
             // kIsWeb viene de flutter/foundation.dart
             kIsWeb 
                ? Image.network(_galleryImage!.path, fit: BoxFit.cover) 
                : Image.file(File(_galleryImage!.path), fit: BoxFit.cover)
          else if (_isCameraInitialized)
            CameraPreview(_cameraController!)
          else if (_useSimulatedCamera)
            Image.network(_fallbackImage, fit: BoxFit.cover)
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // 2. BOTÓN CERRAR
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      if (_predictions != null || _galleryImage != null) _resetScanner();
                    },
                  ),
                ),
              ),
            ),
          ),

          // 3. CUADRO DE ENFOQUE
          if (_predictions == null)
            const Positioned(
              top: 150, left: 40, right: 40, bottom: 350,
              child: ScannerOverlay(),
            ),

          // 4. CONTROLES
          if (_predictions == null && !_isAnalyzing)
            Positioned(
              bottom: 130, left: 0, right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo_library, color: Colors.white, size: 32),
                      onPressed: _pickFromGallery,
                      tooltip: "Subir de galería",
                    ),
                    GestureDetector(
                      onTap: _takePhoto,
                      child: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Center(
                          child: Container(
                            width: 70, height: 70,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cached, color: Colors.white, size: 32),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),

          // 5. PANEL RESULTADOS
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              height: _predictions != null ? 450 : (_isAnalyzing ? 250 : 0),
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, 20, 20, navBarHeight + bottomPadding),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildPanelContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPanelContent() {
    if (_isAnalyzing) {
      return [
        Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
        RotationTransition(turns: _loadingController, child: const Icon(Icons.sync, size: 40, color: Colors.black87)),
        const SizedBox(height: 16),
        const Text("Analizando imagen...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ];
    }
    if (_predictions != null) {
      return [
        Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
        const Text("Resultados", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: _predictions!.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final item = _predictions![index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(backgroundColor: Colors.green[100], child: Text("${index + 1}")),
                title: Text(item.variedad, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.confianza / 100,
                    backgroundColor: Colors.grey[200],
                    color: item.confianza > 80 ? Colors.green : Colors.orange,
                    minHeight: 8,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("${item.confianza.toStringAsFixed(1)}%", style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: _isSaving ? const CircularProgressIndicator(strokeWidth: 2) : const Icon(Icons.save_alt, color: Colors.blue),
                      onPressed: _isSaving ? null : () => _saveResult(item),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        TextButton.icon(
          onPressed: _resetScanner,
          icon: const Icon(Icons.camera_alt),
          label: const Text("Escanear otra vez"),
        )
      ];
    }
    return [];
  }
  // Dentro de _FotoPageState

  bool _isSaving = false;

  Future<void> _saveResult(PredictionModel prediction) async {
    // Verificación de seguridad
    if ((_galleryImage == null && !_isCameraInitialized) && !_useSimulatedCamera) return;

    setState(() => _isSaving = true);

    try {
      // Obtenemos el archivo correcto (Galería o Foto tomada)
      // NOTA: Para este ejemplo simplificado, asumimos que si no es galería, es la última foto tomada.
      // Si usas cámara, necesitarás guardar el XFile en una variable de clase al tomar la foto (ver abajo).
      
      XFile? fileToSave = _galleryImage;
      
      // Si no hay imagen de galería, usamos la lógica de simulación o cámara
      if (fileToSave == null && _useSimulatedCamera) {
          // En modo simulado no podemos guardar de verdad sin un archivo real
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Modo simulación: No se puede subir imagen real")));
          setState(() => _isSaving = false);
          return;
      }

      if (fileToSave != null) {
        // AQUÍ LLAMAMOS AL ENDPOINT
        // Nota: Necesitamos saber el ID REAL de la variedad. 
        // Tu modelo de predicción devuelve 'nombre', pero la BD necesita 'id'.
        // Por ahora enviaremos un ID fijo (ej: 1) o tendrás que buscar el ID basado en el nombre.
        
        await _apiClient.saveToCollection(
          imageFile: fileToSave,
  
          // ¡Pasamos el nombre real que viene de la IA!
          nombreVariedad: prediction.variedad, 
  
          notas: "Identificado con VitIA: ${prediction.variedad} (${prediction.confianza}%)"
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Guardado en tu colección!'), backgroundColor: Colors.green),
        );
        _resetScanner(); // Volver a empezar
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({super.key});
  @override
  Widget build(BuildContext context) => CustomPaint(painter: ScannerCornerPainter());
}
class ScannerCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 4.0..strokeCap = StrokeCap.round;
    double cL = 40.0, r = 20.0;
    canvas.drawPath(Path()..moveTo(0, cL)..lineTo(0, r)..arcToPoint(Offset(r, 0), radius: Radius.circular(r))..lineTo(cL, 0), paint);
    canvas.drawPath(Path()..moveTo(size.width - cL, 0)..lineTo(size.width - r, 0)..arcToPoint(Offset(size.width, r), radius: Radius.circular(r))..lineTo(size.width, cL), paint);
    canvas.drawPath(Path()..moveTo(0, size.height - cL)..lineTo(0, size.height - r)..arcToPoint(Offset(r, size.height), radius: Radius.circular(r), clockwise: false)..lineTo(cL, size.height), paint);
    canvas.drawPath(Path()..moveTo(size.width - cL, size.height)..lineTo(size.width - r, size.height)..arcToPoint(Offset(size.width, size.height - r), radius: Radius.circular(r), clockwise: false)..lineTo(size.width, size.height - cL), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}