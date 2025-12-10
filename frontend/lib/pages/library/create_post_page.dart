import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api_client.dart';
import '../../core/services/api_config.dart';
import '../../core/services/user_sesion.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  
  late ApiClient _apiClient;
  bool _isPublishing = false;
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(getBaseUrl());
    if (UserSession.token != null) {
      _apiClient.setToken(UserSession.token!);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _handlePublish() async {
    if (_titleController.text.trim().isEmpty || _textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, escribe un título y un mensaje.')),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      // Enviamos el texto y la imagen (si existe)
      await _apiClient.createPublicacion(
        _titleController.text, 
        _textController.text,
        imageFile: _selectedImage
      );
      
      if (mounted) {
        Navigator.pop(context, true); // Retorna true para refrescar la lista
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al publicar: $e')),
        );
        setState(() => _isPublishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // BARRA SUPERIOR PERSONALIZADA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black87,
                      textStyle: const TextStyle(fontSize: 16),
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Cancelar'),
                  ),
                  
                  ElevatedButton(
                    onPressed: _isPublishing ? null : _handlePublish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                    child: _isPublishing 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Publicar', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ÁREA DE USUARIO Y TEXTO
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         const CircleAvatar(
                          radius: 22,
                          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'), // Avatar dummy
                          backgroundColor: Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _titleController,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  hintText: 'Título de tu publicación...',
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _textController,
                                maxLines: null,
                                style: const TextStyle(fontSize: 16, color: Colors.black87),
                                decoration: const InputDecoration(
                                  hintText: '¿Qué te gustaría compartir hoy?',
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // PREVISUALIZACIÓN DE IMAGEN / PICKER
                    if (_selectedImage != null)
                      GestureDetector(
                        onTap: () {
                          // Mostrar imagen en pantalla completa
                          showDialog(
                            context: context,
                            builder: (ctx) => Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: EdgeInsets.zero,
                              child: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  InteractiveViewer(
                                    minScale: 0.5,
                                    maxScale: 4.0,
                                    child: Image.file(
                                      File(_selectedImage!.path),
                                      fit: BoxFit.contain,
                                      height: double.infinity,
                                      width: double.infinity,
                                    ),
                                  ),
                                  SafeArea(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                        onPressed: () => Navigator.pop(ctx),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 120, // Hacemos que sea pequeña (thumbnail)
                          height: 120,
                          margin: const EdgeInsets.only(top: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                            image: DecorationImage(
                              image: FileImage(File(_selectedImage!.path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 5, right: 5,
                                child: InkWell(
                                  onTap: () => setState(() => _selectedImage = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54, 
                                      shape: BoxShape.circle
                                    ),
                                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () => _pickImage(ImageSource.gallery),
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text("Añadir imagen", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // BARRA DE ACCIONES INFERIOR (Iconos)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _pickImage(ImageSource.camera), 
                    icon: const Icon(Icons.camera_alt_outlined, size: 28)
                  ),
                  IconButton(
                    onPressed: () => _pickImage(ImageSource.gallery), 
                    icon: const Icon(Icons.photo_outlined, size: 28)
                  ),
                  const Spacer(), 
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.alternate_email, size: 20, color: Colors.black54),
                    label: const Text("Etiquetar", style: TextStyle(color: Colors.black54)),
                  ),
                   TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.location_on_outlined, size: 20, color: Colors.black54),
                    label: const Text("Ubicación", style: TextStyle(color: Colors.black54)),
                  ),
                ],
              ),
            ),

            // BOTÓN PUBLICAR GRANDE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ElevatedButton(
                onPressed: _isPublishing ? null : _handlePublish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A7A30), // Color Oliva
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  elevation: 0,
                ),
                child: _isPublishing 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Publicar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
