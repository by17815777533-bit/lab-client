import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/gradpath_question.dart';
import '../../models/gradpath_track.dart';
import '../../models/paged_result.dart';
import '../../repositories/gradpath_repository.dart';
import 'gradpath_catalog.dart';

class GradPathController extends ChangeNotifier {
  GradPathController(this._repository);

  final GradPathRepository _repository;

  bool _loading = false;
  bool _generating = false;
  bool _running = false;
  bool _analyzing = false;
  String? _errorMessage;
  GradPathConfig? _config;
  PagedResult<GradPathQuestion>? _page;
  GradPathQuestion? _selectedQuestion;
  int _pageNum = 1;
  final int _pageSize = 8;
  String _keyword = '';
  String _selectedTrackCode = gradPathTracks.first.code;
  String _selectedLanguage = resolveGradPathTrack(null).preferredLanguage;
  String _code = _templateFor(resolveGradPathTrack(null).preferredLanguage);
  String _customInput = '';
  String? _resultText;
  String? _analysisText;
  bool _lastRunPassed = false;

  bool get loading => _loading;
  bool get generating => _generating;
  bool get running => _running;
  bool get analyzing => _analyzing;
  String? get errorMessage => _errorMessage;
  GradPathConfig? get config => _config;
  List<GradPathTrackMeta> get tracks => gradPathTracks;
  List<GradPathQuestion> get questions =>
      _page?.records ?? <GradPathQuestion>[];
  GradPathQuestion? get selectedQuestion => _selectedQuestion;
  int get pageNum => _pageNum;
  int get totalPages => _page?.pages ?? 0;
  int get total => _page?.total ?? 0;
  String get keyword => _keyword;
  String get selectedTrackCode => _selectedTrackCode;
  String get selectedLanguage => _selectedLanguage;
  String get code => _code;
  String get customInput => _customInput;
  String? get resultText => _resultText;
  String? get analysisText => _analysisText;
  bool get lastRunPassed => _lastRunPassed;
  GradPathTrackMeta get selectedTrackMeta =>
      resolveGradPathTrack(_selectedQuestion?.trackCode ?? _selectedTrackCode);

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _config = await _repository.fetchConfig();
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '智能练习配置加载失败，请稍后重试';
    }

    try {
      _page = await _repository.fetchQuestions(
        pageNum: _pageNum,
        pageSize: _pageSize,
        trackCode: _selectedTrackCode,
        keyword: _keyword.trim().isEmpty ? null : _keyword.trim(),
      );
      if (_page!.records.isEmpty) {
        _selectedQuestion = null;
        _resultText = null;
        _analysisText = null;
      } else if (_selectedQuestion == null ||
          !_page!.records.any(
            (GradPathQuestion item) => item.id == _selectedQuestion!.id,
          )) {
        await selectQuestion(_page!.records.first.id, silentLoading: true);
      }
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _page = null;
      _selectedQuestion = null;
    } catch (_) {
      _errorMessage = '智能练习题目加载失败，请稍后重试';
      _page = null;
      _selectedQuestion = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  void setKeyword(String value) {
    _keyword = value;
  }

  Future<void> search() async {
    _pageNum = 1;
    await load();
  }

  Future<void> updateTrackCode(String? value) async {
    if (value == null || value == _selectedTrackCode) {
      return;
    }
    _selectedTrackCode = value;
    _pageNum = 1;
    final track = resolveGradPathTrack(value);
    if (_selectedQuestion == null) {
      _selectedLanguage = track.preferredLanguage;
      _code = _templateFor(_selectedLanguage);
    }
    await load();
  }

  Future<void> nextPage() async {
    if (_page == null || _pageNum >= _page!.pages) {
      return;
    }
    _pageNum += 1;
    await load();
  }

  Future<void> previousPage() async {
    if (_pageNum <= 1) {
      return;
    }
    _pageNum -= 1;
    await load();
  }

  Future<void> selectQuestion(
    int questionId, {
    bool silentLoading = false,
  }) async {
    if (!silentLoading) {
      _loading = true;
      notifyListeners();
    }

    try {
      final question = await _repository.fetchQuestionDetail(questionId);
      _selectedQuestion = question;
      _selectedLanguage = _resolveLanguage(question);
      _code = _templateFor(_selectedLanguage);
      _customInput = question.sampleInput ?? '';
      _resultText = null;
      _analysisText = null;
      _lastRunPassed = false;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '题目详情加载失败，请稍后重试';
    } finally {
      if (!silentLoading) {
        _loading = false;
      }
      notifyListeners();
    }
  }

  Future<bool> generateQuestion(String keyword) async {
    final value = keyword.trim();
    if (value.isEmpty) {
      _errorMessage = '请输入题目关键词后再生成';
      notifyListeners();
      return false;
    }

    _generating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final question = await _repository.generateQuestion(
        keyword: value,
        trackCode: _selectedTrackCode,
      );
      _selectedQuestion = question;
      _selectedLanguage = _resolveLanguage(question);
      _code = _templateFor(_selectedLanguage);
      _customInput = question.sampleInput ?? '';
      _resultText = '已生成新题，可以直接开始作答。';
      _analysisText = null;
      _lastRunPassed = false;
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '题目生成失败，请稍后重试';
      return false;
    } finally {
      _generating = false;
      notifyListeners();
    }
  }

  void updateLanguage(String? value) {
    if (value == null || value == _selectedLanguage) {
      return;
    }
    _selectedLanguage = value;
    _code = _templateFor(value);
    notifyListeners();
  }

  void updateCode(String value) {
    _code = value;
  }

  void updateCustomInput(String value) {
    _customInput = value;
  }

  Future<void> runDebug() async {
    final question = _selectedQuestion;
    if (question == null) {
      return;
    }

    _running = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.debugCode(
        questionTitle: question.title,
        code: _code,
        language: _selectedLanguage,
        input: _customInput.trim().isEmpty
            ? question.sampleInput
            : _customInput,
        trackCode: question.trackCode,
      );
      _resultText = _summarizeResult(result);
      _analysisText = null;
      _lastRunPassed = _detectPassed(result);
    } on ApiException catch (error) {
      _resultText = error.message;
      _lastRunPassed = false;
    } catch (_) {
      _resultText = '调试运行失败，请稍后重试';
      _lastRunPassed = false;
    } finally {
      _running = false;
      notifyListeners();
    }
  }

  Future<void> submit() async {
    final question = _selectedQuestion;
    if (question == null) {
      return;
    }

    _running = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.submitCode(
        questionId: question.id,
        questionTitle: question.title,
        code: _code,
        language: _selectedLanguage,
        trackCode: question.trackCode,
      );
      _resultText = _summarizeResult(result);
      _analysisText = null;
      _lastRunPassed = _detectPassed(result);
    } on ApiException catch (error) {
      _resultText = error.message;
      _lastRunPassed = false;
    } catch (_) {
      _resultText = '提交失败，请稍后重试';
      _lastRunPassed = false;
    } finally {
      _running = false;
      notifyListeners();
    }
  }

  Future<void> analyze() async {
    final question = _selectedQuestion;
    if (question == null || (_resultText ?? '').trim().isEmpty) {
      return;
    }

    _analyzing = true;
    notifyListeners();

    try {
      final result = await _repository.analyzeCode(
        questionTitle: question.title,
        code: _code,
        errorMsg: _resultText!,
        output: question.sampleOutput ?? '',
      );
      _analysisText = _summarizeResult(result);
    } on ApiException catch (error) {
      _analysisText = error.message;
    } catch (_) {
      _analysisText = '分析失败，请稍后重试';
    } finally {
      _analyzing = false;
      notifyListeners();
    }
  }

  String _resolveLanguage(GradPathQuestion question) {
    if (question.allowedLanguages.isNotEmpty) {
      return question.allowedLanguages.first;
    }
    return resolveGradPathTrack(question.trackCode).preferredLanguage;
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

  String _summarizeResult(Map<String, dynamic> result) {
    for (final key in <String>[
      'message',
      'msg',
      'stdout',
      'stderr',
      'output',
      'analysis',
      'result',
    ]) {
      final value = result[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    if (result['data'] is Map) {
      final nested = (result['data'] as Map).map(
        (key, value) => MapEntry(key.toString(), value),
      );
      return _summarizeResult(nested);
    }

    return const JsonEncoder.withIndent('  ').convert(result);
  }

  bool _detectPassed(Map<String, dynamic> result) {
    final normalized = _summarizeResult(result).toLowerCase();
    return normalized.contains('accepted') ||
        normalized.contains('pass') ||
        normalized.contains('通过');
  }
}
