import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api_client.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // kIsWeb

class EditProfilePage extends StatefulWidget {
  final ApiClient apiClient;

  const EditProfilePage({super.key, required this.apiClient});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();

  // Imagen
  XFile? _imageFile; // Cambiado a XFile para compatibilidad Web
  String? _currentPhotoUrl;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await widget.apiClient.getMe();
      if (mounted) {
        setState(() {
          _nombreController.text = userData['nombre'] ?? '';
          _apellidosController.text = userData['apellidos'] ?? '';
          _ubicacionController.text = userData['ubicacion'] ?? '';
          _currentPhotoUrl = userData['path_foto_perfil'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargar perfil: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile; // Guardamos XFile directamente
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      // 1. Subir foto si hay una nueva seleccionada
      if (_imageFile != null) {
        // _imageFile ya es XFile
        await widget.apiClient.uploadAvatar(_imageFile!);
      }

      // 2. Actualizar datos de texto
      final Map<String, dynamic> updates = {
        "nombre": _nombreController.text.trim(),
        "apellidos": _apellidosController.text.trim(),
        "ubicacion": _ubicacionController.text.trim(),
      };

      await widget.apiClient.updateProfile(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
        Navigator.pop(context, true); // Devuelve true para indicar éxito
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (_imageFile != null) {
      if (kIsWeb) {
        // En Web, path es un blob URL, usamos NetworkImage
        imageProvider = NetworkImage(_imageFile!.path);
      } else {
        // En Móvil, path es ruta de archivo, usamos FileImage
        imageProvider = FileImage(File(_imageFile!.path));
      }
    } else if (_currentPhotoUrl != null) {
      imageProvider = NetworkImage(_currentPhotoUrl!);
    } else {
      imageProvider = null;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Ajustes del perfil",
            style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SELECCION DE FOTO ---
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: const Color(0xFFF5F5F5),
                              backgroundImage: imageProvider,
                              child: imageProvider == null
                                  ? const Icon(Icons.person, size: 50)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF142018),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    _buildTextField(
                      controller: _nombreController,
                      label: "Nombre",
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _apellidosController,
                      label: "Apellidos",
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _ubicacionController,
                      label: "Ubicación (Ciudad, País)",
                      icon: Icons.location_on_outlined,
                      hint: "Ej. Requena, Valencia",
                      isOptional: true,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF142018),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text("Guardar Cambios",
                                style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool isOptional = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: const Color(0xFFFCFBF6),
      ),
      validator: (value) {
        if (!isOptional && (value == null || value.isEmpty)) {
          return 'Campo obligatorio';
        }
        return null;
      },
    );
  }
}
