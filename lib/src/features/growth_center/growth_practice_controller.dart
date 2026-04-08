import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/paged_result.dart';
import '../../models/practice_question_bank_item.dart';
import '../../repositories/growth_center_repository.dart';

class GrowthPracticeController extends ChangeNotifier {
  GrowthPracticeController(this._repository, {String? initialTrackCode})
    : _trackCode = initialTrackCode ?? 'common';

  final GrowthCenterRepository _repository;

  bool _loading = false;
  bool _submitting = false;
  bool _running = false;
  String? _errorMessage;
  PagedResult<PracticeQuestionBankItem>? _page;
  PracticeQuestionBankItem? _selectedQuestion;
  int _pageNum = 1;
  final int _pageSize = 8;
  String _trackCode;
  String _questionType = '';
  String _keyword = '';
  String _language = 'java';
  String _answer = '';
  String _code = '';
  String _input = '';
  String? _resultMessage;

  bool get loading => _loading;
  bool get submitting => _submitting;
  bool get running => _running;
  String? get errorMessage => _errorMessage;
  List<PracticeQuestionBankItem> get questions =>
      _page?.records ?? <PracticeQuestionBankItem>[];
  PracticeQuestionBankItem? get selectedQuestion => _selectedQuestion;
  int get pageNum => _pageNum;
  int get totalPages => _page?.pages ?? 0;
  String get trackCode => _trackCode;
  String get questionType => _questionType;
  String get keyword => _keyword;
  String get language => _language;
  String get answer => _answer;
  String get code => _code;
  String get input => _input;
  String? get resultMessage => _resultMessage;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _page = await _repository.fetchPracticeQuestions(
        pageNum: _pageNum,
        pageSize: _pageSize,
        trackCode: _trackCode == 'all' ? null : _trackCode,
        questionType: _questionType.isEmpty ? null : _questionType,
        keyword: _keyword.trim().isEmpty ? null : _keyword.trim(),
      );
      if (_page!.records.isNotEmpty) {
        final target = _selectedQuestion != null
            ? _page!.records
                .cast<PracticeQuestionBankItem?>()
                .firstWhere(
                  (item) => item?.id == _selectedQuestion!.id,
                  orElse: () => _page!.records.first,
                )
            : _page!.records.first;
        await selectQuestion(target!.id, silent: true);
      } else {
        _selectedQuestion = null;
      }
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '成长练习加载失败，请稍后重试';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  void updateTrackCode(String? value) {
    _trackCode = value ?? 'common';
  }

  void updateQuestionType(String? value) {
    _questionType = value ?? '';
  }

  void updateKeyword(String value) {
    _keyword = value;
  }

  Future<void> search() async {
    _pageNum = 1;
    await load();
  }

  Future<void> previousPage() async {
    if (_pageNum <= 1) {
      return;
    }
    _pageNum -= 1;
    await load();
  }

  Future<void> nextPage() async {
    if (_page == null || _pageNum >= _page!.pages) {
      return;
    }
    _pageNum += 1;
    await load();
  }

  Future<void> selectQuestion(int questionId, {bool silent = false}) async {
    if (!silent) {
      _loading = true;
      notifyListeners();
    }
    try {
      _selectedQuestion = await _repository.fetchPracticeQuestionDetail(questionId);
      _answer = '';
      _language = _selectedQuestion!.allowedLanguages.isNotEmpty
          ? _selectedQuestion!.allowedLanguages.first
          : 'java';
      _code = _templateFor(_language);
      _input = _selectedQuestion!.sampleInput ?? '';
      _resultMessage = null;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '题目详情加载失败，请稍后重试';
    } finally {
      if (!silent) {
        _loading = false;
      }
      notifyListeners();
    }
  }

  void updateAnswer(String value) {
    _answer = value;
    notifyListeners();
  }

  void updateLanguage(String? value) {
    if (value == null) {
      return;
    }
    _language = value;
    _code = _templateFor(value);
    notifyListeners();
  }

  void updateCode(String value) {
    _code = value;
  }

  void updateInput(String value) {
    _input = value;
  }

  Future<void> submitObjective() async {
    final question = _selectedQuestion;
    if (question == null) {
      return;
    }
    _submitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.submitPracticeAnswer(
        questionId: question.id,
        answer: _answer.trim(),
      );
      _resultMessage = result.message;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '提交失败，请稍后重试';
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<void> runCode({required bool debug}) async {
    final question = _selectedQuestion;
    if (question == null) {
      return;
    }
    _running = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.submitPracticeAnswer(
        questionId: question.id,
        mode: debug ? 'debug' : 'submit',
        language: _language,
        code: _code,
        input: _input,
      );
      _resultMessage = result.message.isEmpty
          ? result.data['stdout']?.toString() ??
                result.data['stderr']?.toString() ??
                result.status
          : result.message;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '运行失败，请稍后重试';
    } finally {
      _running = false;
      notifyListeners();
    }
  }

  static String _templateFor(String language) {
    switch (language) {
      case 'python':
        return 'import sys\n\n# 在这里开始编写你的代码\n';
      case 'c':
        return '#include <stdio.h>\n\nint main(void) {\n  // 在这里开始编写你的代码\n  return 0;\n}\n';
      case 'cpp':
        return '#include <bits/stdc++.h>\nusing namespace std;\n\nint main() {\n  // 在这里开始编写你的代码\n  return 0;\n}\n';
      case 'java':
      default:
        return 'import java.util.*;\n\npublic class Main {\n  public static void main(String[] args) {\n    Scanner scanner = new Scanner(System.in);\n    // 在这里开始编写你的代码\n  }\n}\n';
    }
  }
}
