import 'package:dio/dio.dart';


class ApiClient {
final Dio _dio;
ApiClient(String baseUrl) : _dio = Dio(BaseOptions(baseUrl: baseUrl));


Future<Map<String, dynamic>> ping() async {
final r = await _dio.get('/health/ping');
return r.data as Map<String, dynamic>;
}
}