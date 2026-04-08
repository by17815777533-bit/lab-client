import '../core/network/api_client.dart';
import '../models/gradpath_question.dart';
import '../models/paged_result.dart';

class GradPathConfig {
  GradPathConfig({required this.baseUrl, required this.wsUrl});

  final String? baseUrl;
  final String? wsUrl;

  factory GradPathConfig.fromJson(Map<String, dynamic> json) {
    return GradPathConfig(
      baseUrl: json['baseUrl']?.toString(),
      wsUrl: json['wsUrl']?.toString(),
    );
  }
}

class GradPathRepository {
  GradPathRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<GradPathConfig> fetchConfig() async {
    final response = await _apiClient.get('/api/gradpath/config');
    return GradPathConfig.fromJson(response as Map<String, dynamic>);
  }

  Future<PagedResult<GradPathQuestion>> fetchQuestions({
    int pageNum = 1,
    int pageSize = 9,
    String? trackCode,
    String? keyword,
  }) async {
    final response = await _apiClient.get(
      '/api/gradpath/questions',
      queryParameters: <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize,
        'trackCode': trackCode,
        'keyword': keyword,
      },
    );

    return PagedResult<GradPathQuestion>.fromCustomJson(
      response as Map<String, dynamic>,
      GradPathQuestion.fromJson,
      recordsKey: 'list',
      totalKey: 'total',
      pageNumKey: 'pageNum',
      pageSizeKey: 'pageSize',
      pagesKey: 'pages',
    );
  }

  Future<GradPathQuestion> fetchQuestionDetail(int questionId) async {
    final response = await _apiClient.get(
      '/api/gradpath/questions/$questionId',
    );
    return GradPathQuestion.fromJson(response as Map<String, dynamic>);
  }

  Future<GradPathQuestion> generateQuestion({
    required String keyword,
    String? trackCode,
  }) async {
    final response = await _apiClient.post(
      '/api/gradpath/questions/generate',
      queryParameters: <String, dynamic>{
        'keyword': keyword,
        'trackCode': trackCode,
      },
    );
    return GradPathQuestion.fromJson(response as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> debugCode({
    required String questionTitle,
    required String code,
    required String language,
    String? input,
    String? trackCode,
  }) async {
    final response = await _apiClient.post(
      '/api/gradpath/judge/debug',
      data: <String, dynamic>{
        'questionTitle': questionTitle,
        'code': code,
        'language': language,
        'input': input,
        'trackCode': trackCode,
      },
    );
    return _asMap(response);
  }

  Future<Map<String, dynamic>> submitCode({
    required int questionId,
    required String questionTitle,
    required String code,
    required String language,
    String? trackCode,
  }) async {
    final response = await _apiClient.post(
      '/api/gradpath/judge/submit',
      data: <String, dynamic>{
        'questionId': questionId,
        'questionTitle': questionTitle,
        'code': code,
        'language': language,
        'trackCode': trackCode,
      },
    );
    return _asMap(response);
  }

  Future<Map<String, dynamic>> analyzeCode({
    required String questionTitle,
    required String code,
    required String errorMsg,
    required String output,
  }) async {
    final response = await _apiClient.post(
      '/api/gradpath/judge/analyze',
      data: <String, dynamic>{
        'questionTitle': questionTitle,
        'code': code,
        'errorMsg': errorMsg,
        'output': output,
      },
    );
    return _asMap(response);
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return <String, dynamic>{'result': value};
  }
}
