import '../core/network/api_client.dart';
import '../models/statistics_overview.dart';

class StatisticsRepository {
  StatisticsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<StatisticsOverview> fetchOverview({int? labId}) async {
    final String path = labId == null
        ? '/api/statistics/overview'
        : '/api/statistics/lab/$labId';
    final response = await _apiClient.get(path);
    return StatisticsOverview.fromJson(response as Map<String, dynamic>);
  }
}
