import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';


final apiBaseUrlProvider = Provider<String>((ref) => const String.fromEnvironment(
'API_BASE_URL', defaultValue: 'http://10.0.2.2:8000',
));


final apiProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(apiBaseUrlProvider)));