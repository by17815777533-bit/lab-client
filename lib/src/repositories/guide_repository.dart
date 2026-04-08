import '../core/network/api_client.dart';
import '../models/guide_option.dart';

class GuideRepository {
  GuideRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<GuideOption>> fetchOptions() async {
    final response = await _apiClient.get('/api/guide/options');
    final items = response as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map((Map item) => GuideOption.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }
}
