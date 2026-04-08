import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/paged_result.dart';
import '../../repositories/lab_exit_application_repository.dart';
import 'exit_application_models.dart';

class ExitApplicationController extends ChangeNotifier {
  ExitApplicationController(this._repository);

  final LabExitApplicationRepository _repository;

  bool _loading = false;
  bool _submitting = false;
  String? _errorMessage;
  int _pageNum = 1;
  final int _pageSize = 8;
  PagedResult<LabExitApplicationRecord>? _page;

  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get errorMessage => _errorMessage;
  int get pageNum => _pageNum;
  int get pageSize => _pageSize;
  int get total => _page?.total ?? 0;
  int get totalPages => _page?.pages ?? 0;
  List<LabExitApplicationRecord> get records =>
      _page?.records ?? <LabExitApplicationRecord>[];

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _page = await _repository.fetchMyApplications(
        pageNum: _pageNum,
        pageSize: _pageSize,
      );
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '加载退出申请记录失败，请稍后重试';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  Future<void> previousPage() async {
    if (_pageNum <= 1) {
      return;
    }
    _pageNum -= 1;
    await load();
  }

  Future<void> nextPage() async {
    if (_page != null && _pageNum >= _page!.pages) {
      return;
    }
    _pageNum += 1;
    await load();
  }

  Future<bool> submit({required String reason}) async {
    _submitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.submitExitApplication(reason: reason);
      _pageNum = 1;
      await load();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '提交退出申请失败，请稍后重试';
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
