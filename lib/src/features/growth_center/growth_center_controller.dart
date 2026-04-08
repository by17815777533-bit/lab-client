import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/growth_center_models.dart';
import '../../repositories/growth_center_repository.dart';

class GrowthCenterController extends ChangeNotifier {
  GrowthCenterController(this._repository);

  final GrowthCenterRepository _repository;

  bool _loading = false;
  bool _submitting = false;
  String? _errorMessage;
  GrowthDashboard? _dashboard;
  GrowthAssessmentQuestionSet? _questionSet;
  GrowthTrackDetail? _selectedTrackDetail;
  String? _selectedTrackCode;
  final Map<int, String> _answers = <int, String>{};

  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get errorMessage => _errorMessage;
  GrowthDashboard? get dashboard => _dashboard;
  GrowthAssessmentQuestionSet? get questionSet => _questionSet;
  GrowthTrackDetail? get selectedTrackDetail => _selectedTrackDetail;
  String? get selectedTrackCode => _selectedTrackCode;
  Map<int, String> get answers => Map<int, String>.unmodifiable(_answers);
  bool get hasResult => _dashboard?.hasResult == true;
  List<GrowthTrackSummary> get tracks => _dashboard?.tracks ?? <GrowthTrackSummary>[];
  GrowthResultView? get latestResult => _dashboard?.latestResult;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboard = await _repository.fetchDashboard();
      if (_dashboard!.hasResult) {
        final trackCode =
            _selectedTrackCode ?? _dashboard!.latestResult?.topTracks.firstOrNull?.code;
        if (trackCode != null && trackCode.isNotEmpty) {
          await _loadTrackDetail(trackCode, silent: true);
        }
      } else {
        _questionSet = await _repository.fetchAssessmentQuestions();
      }
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '成长中心加载失败，请稍后重试';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  void selectAnswer(int questionId, String optionKey) {
    _answers[questionId] = optionKey;
    notifyListeners();
  }

  Future<void> selectTrack(String trackCode) async {
    await _loadTrackDetail(trackCode);
  }

  Future<void> _loadTrackDetail(String trackCode, {bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _selectedTrackCode = trackCode;
      _selectedTrackDetail = await _repository.fetchTrackDetail(trackCode);
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '路径详情加载失败，请稍后重试';
    } finally {
      if (!silent) {
        _loading = false;
      }
      notifyListeners();
    }
  }

  Future<bool> submitAssessment() async {
    final questionSet = _questionSet;
    if (questionSet == null) {
      _errorMessage = '当前没有可提交的测评题目';
      notifyListeners();
      return false;
    }
    final missing = questionSet.questions.firstWhere(
      (question) => !_answers.containsKey(question.id),
      orElse: () => GrowthAssessmentQuestionView(
        id: 0,
        questionNo: null,
        dimension: null,
        title: '',
        description: null,
        options: const <GrowthAssessmentOptionView>[],
      ),
    );
    if (missing.id != 0) {
      _errorMessage = '请先完成第 ${missing.questionNo ?? '-'} 题';
      notifyListeners();
      return false;
    }

    _submitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.submitAssessment(
        versionNo: questionSet.versionNo,
        answers: questionSet.questions
            .map(
              (item) => <String, dynamic>{
                'questionId': item.id,
                'optionKey': _answers[item.id],
              },
            )
            .toList(growable: false),
      );
      _dashboard = GrowthDashboard(
        hasResult: true,
        assessmentVersion: questionSet.versionNo,
        tracks: _dashboard?.tracks ?? <GrowthTrackSummary>[],
        latestResult: result,
      );
      final topCode = result.topTracks.isNotEmpty ? result.topTracks.first.code : null;
      if (topCode != null) {
        await _loadTrackDetail(topCode, silent: true);
      }
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '成长测评提交失败，请稍后重试';
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<void> restartAssessment() async {
    _answers.clear();
    _selectedTrackDetail = null;
    _selectedTrackCode = null;
    _dashboard = GrowthDashboard(
      hasResult: false,
      assessmentVersion: _dashboard?.assessmentVersion ?? 1,
      tracks: _dashboard?.tracks ?? <GrowthTrackSummary>[],
      latestResult: null,
    );
    try {
      _questionSet = await _repository.fetchAssessmentQuestions();
      _errorMessage = null;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '成长测评加载失败，请稍后重试';
    }
    notifyListeners();
  }
}
