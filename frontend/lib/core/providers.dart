import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

import 'services/api_config.dart';

final apiBaseUrlProvider = Provider<String>((ref) {
  const env = String.fromEnvironment('API_BASE_URL');
  if (env.isNotEmpty) return env;
  return getBaseUrl();
});

final apiProvider =
    Provider<ApiClient>((ref) => ApiClient(ref.watch(apiBaseUrlProvider)));
