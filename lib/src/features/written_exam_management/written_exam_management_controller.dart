import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/paged_result.dart';
import '../../models/practice_question_bank_item.dart';
import '../../models/written_exam_models.dart';
import '../../repositories/written_exam_repository.dart';

class WrittenExamManagementController extends ChangeNotifier {
  WrittenExamManagementController(this._repository);

  final WrittenExamRepository _repository;

  bool _loading = false;
  bool _saving = false;
  bool _reviewing = false;
  String? _errorMessage;
  WrittenExamConfigData? _config;
  List<PracticeQuestionBankItem> _questions = <PracticeQuestionBankItem>[];
  PagedResult<WrittenExamSubmissionRecord>? _submissionsPage;
  int _submissionPageNum = 1;
  final int _submissionPageSize = 10;
  int? _submissionStatus;
  String _submissionKeyword = '';

  bool get loading => _loading;
  bool get saving => _saving;
  bool get reviewing => _reviewing;
  String? get errorMessage => _errorMessage;
  WrittenExamConfigData? get config => _config;
  List<PracticeQuestionBankItem> get questions =>
      List<PracticeQuestionBankItem>.unmodifiable(_questions);
  List<WrittenExamSubmissionRecord> get submissions =>
      _submissionsPage?.records ?? <WrittenExamSubmissionRecord>[];
  int get submissionPageNum => _submissionPageNum;
  int get submissionTotalPages => _submissionsPage?.pages ?? 0;
  int get submissionTotal => _submissionsPage?.total ?? 0;
  int? get submissionStatus => _submissionStatus;
  String get submissionKeyword => _submissionKeyword;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _repository.fetchAdminConfig(),
        _repository.fetchAdminSubmissions(
          pageNum: _submissionPageNum,
          pageSize: _submissionPageSize,
          status: _submissionStatus,
          realName: _submissionKeyword.trim().isEmpty
              ? null
              : _submissionKeyword.trim(),
        ),
      ]);
      _config = results[0] as WrittenExamConfigData;
      _questions = _config!.questions.toList(growable: true);
      _submissionsPage = results[1] as PagedResult<WrittenExamSubmissionRecord>;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '正式笔试管理加载失败，请稍后重试';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  void updateSubmissionKeyword(String value) {
    _submissionKeyword = value;
  }

  void updateSubmissionStatus(int? value) {
    _submissionStatus = value;
    notifyListeners();
  }

  Future<void> searchSubmissions() async {
    _submissionPageNum = 1;
    await _loadSubmissions();
  }

  Future<void> previousSubmissionPage() async {
    if (_submissionPageNum <= 1) {
      return;
    }
    _submissionPageNum -= 1;
    await _loadSubmissions();
  }

  Future<void> nextSubmissionPage() async {
    if (_submissionsPage == null ||
        _submissionPageNum >= _submissionsPage!.pages) {
      return;
    }
    _submissionPageNum += 1;
    await _loadSubmissions();
  }

  void addQuestions(List<PracticeQuestionBankItem> items) {
    final existingKeys = _questions
        .map((item) => item.bankQuestionId ?? item.id)
        .toSet();

    for (final item in items) {
      final key = item.bankQuestionId ?? item.id;
      if (!existingKeys.contains(key)) {
        _questions.add(
          item.copyWith(
            score: item.score ?? 10,
            sortOrder: _questions.length + 1,
          ),
        );
        existingKeys.add(key);
      }
    }
    _normalizeSortOrder();
    notifyListeners();
  }

  void removeQuestionAt(int index) {
    if (index < 0 || index >= _questions.length) {
      return;
    }
    _questions.removeAt(index);
    _normalizeSortOrder();
    notifyListeners();
  }

  void moveQuestion(int index, int delta) {
    final target = index + delta;
    if (index < 0 ||
        index >= _questions.length ||
        target < 0 ||
        target >= _questions.length) {
      return;
    }
    final item = _questions.removeAt(index);
    _questions.insert(target, item);
    _normalizeSortOrder();
    notifyListeners();
  }

  void updateQuestionScore(int index, int value) {
    if (index < 0 || index >= _questions.length) {
      return;
    }
    _questions[index] = _questions[index].copyWith(score: value);
    notifyListeners();
  }

  Future<bool> saveConfig({
    required bool recruitmentOpen,
    required String title,
    required String description,
    required String startTime,
    required String endTime,
    required int passScore,
  }) async {
    _saving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.saveAdminConfig(
        recruitmentOpen: recruitmentOpen,
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        passScore: passScore,
        questions: _questions,
      );
      await load();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '正式笔试配置保存失败，请稍后重试';
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<bool> reviewSubmission({
    required int submissionId,
    required int status,
    String? adminRemark,
  }) async {
    _reviewing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.reviewSubmission(
        submissionId: submissionId,
        status: status,
        adminRemark: adminRemark,
      );
      await _loadSubmissions();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '笔试审核失败，请稍后重试';
      return false;
    } finally {
      _reviewing = false;
      notifyListeners();
    }
  }

  Future<void> _loadSubmissions() async {
    try {
      _submissionsPage = await _repository.fetchAdminSubmissions(
        pageNum: _submissionPageNum,
        pageSize: _submissionPageSize,
        status: _submissionStatus,
        realName: _submissionKeyword.trim().isEmpty
            ? null
            : _submissionKeyword.trim(),
      );
      notifyListeners();
    } on ApiException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
    } catch (_) {
      _errorMessage = '笔试提交记录加载失败，请稍后重试';
      notifyListeners();
    }
  }

  void _normalizeSortOrder() {
    _questions = _questions
        .asMap()
        .entries
        .map(
          (entry) => entry.value.copyWith(
            sortOrder: entry.key + 1,
            score: entry.value.score ?? 10,
          ),
        )
        .toList(growable: true);
  }
}
