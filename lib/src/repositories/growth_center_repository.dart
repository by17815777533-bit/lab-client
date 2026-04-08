import '../core/network/api_client.dart';
import '../models/growth_center_models.dart';
import '../models/paged_result.dart';
import '../models/practice_question_bank_item.dart';

class GrowthCenterPracticeResult {
  GrowthCenterPracticeResult({required this.data});

  final Map<String, dynamic> data;

  bool get correct => data['correct'] == true;
  String get status => data['status']?.toString() ?? '';
  String get message => data['message']?.toString() ?? '';

  factory GrowthCenterPracticeResult.fromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) {
      return GrowthCenterPracticeResult(data: value);
    }
    if (value is Map) {
      return GrowthCenterPracticeResult(
        data: value.map((key, item) => MapEntry(key.toString(), item)),
      );
    }
    return GrowthCenterPracticeResult(data: <String, dynamic>{'message': '$value'});
  }
}

class GrowthCenterRepository {
  GrowthCenterRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<GrowthDashboard> fetchDashboard() async {
    final response = await _apiClient.get('/api/growth-center/dashboard');
    return GrowthDashboard.fromJson(response as Map<String, dynamic>);
  }

  Future<GrowthAssessmentQuestionSet> fetchAssessmentQuestions() async {
    final response = await _apiClient.get('/api/growth-center/assessment/questions');
    return GrowthAssessmentQuestionSet.fromJson(
      response as Map<String, dynamic>,
    );
  }

  Future<GrowthResultView> submitAssessment({
    required int versionNo,
    required List<Map<String, dynamic>> answers,
  }) async {
    final response = await _apiClient.post(
      '/api/growth-center/assessment/submit',
      data: <String, dynamic>{'versionNo': versionNo, 'answers': answers},
    );
    return GrowthResultView.fromJson(response as Map<String, dynamic>);
  }

  Future<List<GrowthTrackSummary>> fetchTracks({String? category}) async {
    final response = await _apiClient.get(
      '/api/growth-center/tracks',
      queryParameters: <String, dynamic>{'category': category},
    );
    final list = response as List<dynamic>? ?? const <dynamic>[];
    return list
        .whereType<Map>()
        .map(
          (Map item) =>
              GrowthTrackSummary.fromJson(item.cast<String, dynamic>()),
        )
        .toList(growable: false);
  }

  Future<GrowthTrackDetail> fetchTrackDetail(String code) async {
    final response = await _apiClient.get('/api/growth-center/tracks/$code');
    return GrowthTrackDetail.fromJson(response as Map<String, dynamic>);
  }

  Future<PagedResult<PracticeQuestionBankItem>> fetchPracticeQuestions({
    int pageNum = 1,
    int pageSize = 9,
    String? trackCode,
    String? questionType,
    String? keyword,
  }) async {
    final response = await _apiClient.get(
      '/api/growth-center/practice/questions',
      queryParameters: <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize,
        'trackCode': trackCode,
        'questionType': questionType,
        'keyword': keyword,
      },
    );

    return PagedResult<PracticeQuestionBankItem>.fromCustomJson(
      response as Map<String, dynamic>,
      PracticeQuestionBankItem.fromJson,
      recordsKey: 'list',
      totalKey: 'total',
      pageNumKey: 'pageNum',
      pageSizeKey: 'pageSize',
      pagesKey: 'pages',
    );
  }

  Future<PracticeQuestionBankItem> fetchPracticeQuestionDetail(int questionId) async {
    final response = await _apiClient.get(
      '/api/growth-center/practice/questions/$questionId',
    );
    return PracticeQuestionBankItem.fromJson(response as Map<String, dynamic>);
  }

  Future<GrowthCenterPracticeResult> submitPracticeAnswer({
    required int questionId,
    String? mode,
    String? answer,
    String? language,
    String? code,
    String? input,
  }) async {
    final response = await _apiClient.post(
      '/api/growth-center/practice/submit',
      data: <String, dynamic>{
        'questionId': questionId,
        'mode': mode,
        'answer': answer,
        'language': language,
        'code': code,
        'input': input,
      },
    );
    return GrowthCenterPracticeResult.fromDynamic(response);
  }

  Future<PagedResult<PracticeQuestionBankItem>> fetchAdminQuestionBank({
    int pageNum = 1,
    int pageSize = 10,
    String? trackCode,
    String? questionType,
    String? keyword,
  }) async {
    final response = await _apiClient.get(
      '/api/growth-center/admin/question-bank',
      queryParameters: <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize,
        'trackCode': trackCode,
        'questionType': questionType,
        'keyword': keyword,
      },
    );
    return PagedResult<PracticeQuestionBankItem>.fromJson(
      response as Map<String, dynamic>,
      PracticeQuestionBankItem.fromJson,
    );
  }

  Future<PracticeQuestionBankItem> fetchAdminQuestionDetail(int questionId) async {
    final response = await _apiClient.get(
      '/api/growth-center/admin/question-bank/$questionId',
    );
    return PracticeQuestionBankItem.fromJson(response as Map<String, dynamic>);
  }

  Future<void> saveAdminQuestion(PracticeQuestionBankItem item) {
    return _apiClient.post(
      '/api/growth-center/admin/question-bank',
      data: item.toPayload(),
    );
  }

  Future<void> deleteAdminQuestion(int questionId) {
    return _apiClient.post(
      '/api/growth-center/admin/question-bank/delete/$questionId',
    );
  }
}
