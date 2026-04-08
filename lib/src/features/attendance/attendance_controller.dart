import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/paged_result.dart';
import '../../repositories/attendance_workflow_repository.dart';
import 'attendance_models.dart';

class AttendanceController extends ChangeNotifier {
  AttendanceController(this._repository);

  final AttendanceWorkflowRepository _repository;

  bool _loading = false;
  bool _loadingHistory = false;
  bool _signingIn = false;
  bool _requestingMakeup = false;
  String? _errorMessage;
  AttendanceCurrentSession? _currentSession;
  PagedResult<AttendanceHistoryRecord>? _historyPage;
  int _historyPageNum = 1;
  final int _historyPageSize = 8;

  bool get loading => _loading;
  bool get loadingHistory => _loadingHistory;
  bool get signingIn => _signingIn;
  bool get requestingMakeup => _requestingMakeup;
  String? get errorMessage => _errorMessage;
  AttendanceCurrentSession? get currentSession => _currentSession;
  PagedResult<AttendanceHistoryRecord>? get historyPage => _historyPage;
  int get historyPageNum => _historyPageNum;
  int get historyPageSize => _historyPageSize;
  int get historyTotal => _historyPage?.total ?? 0;
  int get historyTotalPages => _historyPage?.pages ?? 0;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.wait(<Future<void>>[
      _loadCurrentSession(),
      _loadHistory(pageNum: 1),
    ]);

    _loading = false;
    notifyListeners();
  }

  Future<void> refreshHistory() async {
    _loadingHistory = true;
    _errorMessage = null;
    notifyListeners();

    await _loadHistory(pageNum: _historyPageNum);

    _loadingHistory = false;
    notifyListeners();
  }

  Future<bool> submitSignIn({required String signCode, String? remark}) async {
    _signingIn = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.signIn(
        signCode: signCode.trim(),
        remark: remark?.trim().isEmpty == true ? null : remark?.trim(),
      );
      await load();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '签到提交失败，请稍后重试';
      return false;
    } finally {
      _signingIn = false;
      notifyListeners();
    }
  }

  Future<bool> submitMakeup({String? remark}) async {
    _requestingMakeup = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.requestMakeup(
        remark: remark?.trim().isEmpty == true ? null : remark?.trim(),
      );
      await load();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '补签申请提交失败，请稍后重试';
      return false;
    } finally {
      _requestingMakeup = false;
      notifyListeners();
    }
  }

  Future<void> nextHistoryPage() async {
    if (_historyPageNum >= historyTotalPages && historyTotalPages > 0) {
      return;
    }
    _historyPageNum += 1;
    await refreshHistory();
  }

  Future<void> previousHistoryPage() async {
    if (_historyPageNum <= 1) {
      return;
    }
    _historyPageNum -= 1;
    await refreshHistory();
  }

  Future<void> _loadCurrentSession() async {
    try {
      _currentSession = await _repository.fetchCurrentSession();
    } on ApiException catch (error) {
      _errorMessage ??= error.message;
    } catch (_) {
      _errorMessage ??= '当前会话加载失败，请稍后重试';
    }
  }

  Future<void> _loadHistory({required int pageNum}) async {
    try {
      _historyPageNum = pageNum;
      _historyPage = await _repository.fetchHistory(
        pageNum: pageNum,
        pageSize: _historyPageSize,
      );
    } on ApiException catch (error) {
      _errorMessage ??= error.message;
    } catch (_) {
      _errorMessage ??= '考勤记录加载失败，请稍后重试';
    }
  }
}
