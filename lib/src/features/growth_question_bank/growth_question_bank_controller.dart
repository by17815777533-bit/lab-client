import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/paged_result.dart';
import '../../models/practice_question_bank_item.dart';
import '../../repositories/growth_center_repository.dart';

class GrowthQuestionBankController extends ChangeNotifier {
  GrowthQuestionBankController(this._repository);

  final GrowthCenterRepository _repository;

  bool _loading = false;
  bool _saving = false;
  bool _deleting = false;
  String? _errorMessage;
  PagedResult<PracticeQuestionBankItem>? _page;
  int _pageNum = 1;
  final int _pageSize = 10;
  String _trackCode = '';
  String _questionType = '';
  String _keyword = '';

  bool get loading => _loading;
  bool get saving => _saving;
  bool get deleting => _deleting;
  String? get errorMessage => _errorMessage;
  List<PracticeQuestionBankItem> get records =>
      _page?.records ?? <PracticeQuestionBankItem>[];
  int get pageNum => _pageNum;
  int get totalPages => _page?.pages ?? 0;
  int get total => _page?.total ?? 0;
  String get trackCode => _trackCode;
  String get questionType => _questionType;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _page = await _repository.fetchAdminQuestionBank(
        pageNum: _pageNum,
        pageSize: _pageSize,
        trackCode: _trackCode.isEmpty ? null : _trackCode,
        questionType: _questionType.isEmpty ? null : _questionType,
        keyword: _keyword.trim().isEmpty ? null : _keyword.trim(),
      );
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '题库加载失败，请稍后重试';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  void updateTrackCode(String? value) {
    _trackCode = value ?? '';
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

  Future<PracticeQuestionBankItem?> fetchDetail(int id) async {
    try {
      return await _repository.fetchAdminQuestionDetail(id);
    } on ApiException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return null;
    } catch (_) {
      _errorMessage = '题目详情加载失败，请稍后重试';
      notifyListeners();
      return null;
    }
  }

  Future<bool> saveQuestion(PracticeQuestionBankItem item) async {
    _saving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.saveAdminQuestion(item);
      await load();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '题目保存失败，请稍后重试';
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteQuestion(int id) async {
    _deleting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.deleteAdminQuestion(id);
      await load();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '题目删除失败，请稍后重试';
      return false;
    } finally {
      _deleting = false;
      notifyListeners();
    }
  }
}
