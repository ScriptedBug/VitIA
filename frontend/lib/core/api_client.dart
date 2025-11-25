
import 'package:dio/dio.dart';
import './models/prediction_model.dart';
import 'package:image_picker/image_picker.dart';


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
    required int idVariedad,
    String? notas,
    double? lat,
    double? lon,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      
      FormData formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(bytes, filename: imageFile.name),
        "id_variedad": idVariedad,
        if (notas != null) "notas": notas,
        if (lat != null) "latitud": lat,
        if (lon != null) "longitud": lon,
      });

      // Asegúrate de que el token de autenticación esté configurado en los headers de Dio
      // Si usas un interceptor para el token, esto funcionará directo.
      // Si no, necesitarás pasar el token aquí.
      
      await _dio.post('/coleccion/upload', data: formData);
      
    } catch (e) {
      throw Exception('Error al guardar en colección: $e');
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

}