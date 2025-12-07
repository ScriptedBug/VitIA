
import 'package:dio/dio.dart';
import './models/prediction_model.dart';
import 'package:image_picker/image_picker.dart';
import 'models/coleccion_model.dart';
import 'package:http_parser/http_parser.dart';



class ApiClient {
final Dio _dio;
ApiClient(String baseUrl) : _dio = Dio(BaseOptions(baseUrl: baseUrl));


Future<Map<String, dynamic>> ping() async {
final r = await _dio.get('/health/ping');
return r.data as Map<String, dynamic>;
}

Future<List<dynamic>> getVariedades() async {
    try {
      final response = await _dio.get('/variedades/');
      return response.data as List<dynamic>;
    } catch (e) {
      print("Error al obtener variedades: $e");
      rethrow;
    }
  }

Future<List<PredictionModel>> predictImage(XFile file) async {
    try {
      // 1. Leemos los bytes del archivo (Funciona en Web y Móvil)
      final bytes = await file.readAsBytes();
      
      // 2. Usamos fromBytes en lugar de fromFile
      FormData formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(
          bytes, 
          filename: file.name, // XFile ya trae el nombre
          contentType: MediaType('image', 'jpeg'), // Ajusta según el tipo real si es necesario
        ),
      });

      final response = await _dio.post('/ia/predict', data: formData);

      final List<dynamic> rawList = response.data['predicciones'];
      return rawList.map((e) => PredictionModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error al analizar imagen: $e');
    }
  }

  // Método para guardar en la colección subiendo la imagen
  Future<void> saveToCollection({
    required XFile imageFile,
    required String nombreVariedad, // <--- CAMBIO DE TIPO
    String? notas,
    double? lat,
    double? lon,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      
      FormData formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(
          bytes, 
          filename: imageFile.name,
          contentType: MediaType('image', 'jpeg')),
        "nombre_variedad": nombreVariedad, // <--- Enviamos el nombre
        if (notas != null) "notas": notas,
        if (lat != null) "latitud": lat,
        if (lon != null) "longitud": lon,
      });

      await _dio.post('/coleccion/upload', data: formData);
    } catch (e) {
      throw Exception('Error al guardar: $e');
    }
  }

  void setToken(String token) {
    _dio.options.headers["Authorization"] = "Bearer $token";
  }

  Future<List<dynamic>> getUserCollection() async {
    try {
      final response = await _dio.get('/coleccion/');
      return response.data as List<dynamic>;
    } catch (e) {
      print("Error al obtener colección: $e");
      rethrow;
    }
  }

  Future<void> updateCollectionItem(int idColeccion, Map<String, dynamic> updates) async {
    try {
      // El backend espera un PATCH a /coleccion/{id}
      await _dio.patch('/coleccion/$idColeccion', data: updates);
    } catch (e) {
      print("Error al actualizar item: $e");
      rethrow;
    }
  }

  Future<void> deleteCollectionItem(int idColeccion) async {
    try {
      await _dio.delete('/coleccion/$idColeccion');
    } catch (e) {
      print("Error al eliminar item: $e");
      rethrow;
    }
  }

  // --- SECCIÓN FORO / PUBLICACIONES ---

  // 1. Obtener el feed global (Todos)
  Future<List<dynamic>> getPublicaciones() async {
    try {
      final response = await _dio.get('/publicaciones/');
      return response.data as List<dynamic>;
    } catch (e) {
      print("Error al obtener feed: $e");
      return [];
    }
  }

  // 2. Obtener mis hilos (Solo usuario actual)
  Future<List<dynamic>> getUserPublicaciones() async {
    try {
      final response = await _dio.get('/publicaciones/me');
      return response.data as List<dynamic>;
    } catch (e) {
      print("Error al obtener mis publicaciones: $e");
      rethrow;
    }
  }

  // 3. Crear nueva publicación (Para el futuro botón "+")
  Future<void> createPublicacion(String titulo, String texto) async {
    try {
      await _dio.post('/publicaciones/', data: {
        "titulo": titulo,
        "texto": texto,
        "links_fotos": [] // Por ahora lista vacía, luego podrás subir fotos
      });
    } catch (e) {
      print("Error al crear publicación: $e");
      rethrow;
    }
  }

  // 4. Eliminar publicación
  Future<void> deletePublicacion(int idPublicacion) async {
    try {
      await _dio.delete('/publicaciones/$idPublicacion');
    } catch (e) {
      print("Error al eliminar publicación: $e");
      rethrow;
    }
  }

  // Función para descargar tus fotos
  Future<List<ColeccionModel>> getCollection() async {
    try {
      final response = await _dio.get('/coleccion/');
      final List<dynamic> data = response.data;
      return data.map((json) => ColeccionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar la colección: $e');
    }
  }

  // --- SECCIÓN TUTORIAL ---

  /// Obtiene el estado 'tutorial_superado' del usuario actual (GET /users/me).
  Future<bool> getTutorialStatus() async {
    try {
      final response = await _dio.get('/users/me');
      
      // 🚨 Leemos el campo específico 'tutorial_superado' del JSON de respuesta
      return response.data['tutorial_superado'] as bool? ?? false;
      
    } catch (e) {
      print("Error al obtener el estado del tutorial: $e");
      // Fallback seguro: Si falla (401, red), asumimos true para no bloquear el build
      // (En HomePage gestionaremos que si falla, se redirija si es necesario).
      return true; 
    }
  }

  /// Llama a PATCH /users/me para actualizar 'tutorial_superado' a true.
  Future<void> markTutorialAsComplete() async {
    try {
      await _dio.patch('/users/me', data: {
        "tutorial_superado": true
      });
    } catch (e) {
      print("Error al marcar tutorial como completo: $e");
      throw Exception('Fallo al actualizar estado del tutorial en el servidor.');
    }
  }
}