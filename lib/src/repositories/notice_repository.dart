import '../core/network/api_client.dart';
import '../models/notice_item.dart';
import '../models/paged_result.dart';

class NoticeRepository {
  NoticeRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<NoticeItem>> fetchLatest({int limit = 6}) async {
    final response = await _apiClient.get(
      '/api/notices/latest',
      queryParameters: <String, dynamic>{'limit': limit},
    );

    final items = response as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) => NoticeItem.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<PagedResult<NoticeItem>> fetchPage({
    int pageNum = 1,
    int pageSize = 10,
    String? keyword,
    String? publishScope,
  }) async {
    final response = await _apiClient.get(
      '/api/notices',
      queryParameters: <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize,
        'keyword': keyword,
        'publishScope': publishScope,
      },
    );

    return PagedResult<NoticeItem>.fromJson(
      response as Map<String, dynamic>,
      NoticeItem.fromJson,
    );
  }
}
