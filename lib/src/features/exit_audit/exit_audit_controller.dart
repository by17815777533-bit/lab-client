import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/paged_result.dart';
import '../../repositories/exit_audit_repository.dart';
import 'exit_audit_models.dart';

class ExitAuditController extends ChangeNotifier {
  ExitAuditController({required ExitAuditRepository repository, int? labId})
    : _repository = repository,
      _labId = labId;

  final ExitAuditRepository _repository;

  bool _loading = false;
  bool _submitting = false;
  String? _errorMessage;
  int _pageNum = 1;
  final int _pageSize = 8;
  int? _labId;
  int? _statusFilter;
  String _studentName = '';
  PagedResult<ExitAuditApplicationRecord>? _page;

  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get errorMessage => _errorMessage;
  int get pageNum => _pageNum;
  int get pageSize => _pageSize;
  int? get labId => _labId;
  int? get statusFilter => _statusFilter;
  String get studentName => _studentName;
  int get total => _page?.total ?? 0;
  int get totalPages => _page?.pages ?? 0;
  List<ExitAuditApplicationRecord> get records =>
      _page?.records ?? <ExitAuditApplicationRecord>[];

  Future<void> load() async {
    if (_labId == null) {
      _page = null;
      _errorMessage = '请先选择实验室编号';
      notifyListeners();
      return;
    }

    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _page = await _repository.fetchApplications(
        pageNum: _pageNum,
        pageSize: _pageSize,
        labId: _labId,
        status: _statusFilter,
        realName: _studentName.trim().isEmpty ? null : _studentName.trim(),
      );
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '审核列表加载失败，请稍后重试';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  void setLabId(int? labId) {
    if (_labId == labId) {
      return;
    }
    _labId = labId;
    _pageNum = 1;
    _page = null;
    notifyListeners();
  }

  void setStatusFilter(int? status) {
    if (_statusFilter == status) {
      return;
    }
    _statusFilter = status;
    _pageNum = 1;
    notifyListeners();
  }

  void setStudentName(String value) {
    final next = value.trim();
    if (_studentName == next) {
      return;
    }
    _studentName = next;
    _pageNum = 1;
    notifyListeners();
  }

  void resetFilters() {
    _statusFilter = null;
    _studentName = '';
    _pageNum = 1;
    notifyListeners();
  }

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

  Future<bool> audit({
    required int id,
    required int status,
    String? auditRemark,
  }) async {
    _submitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.auditApplication(
        id: id,
        status: status,
        auditRemark: auditRemark,
      );
      await load();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '提交审核结果失败，请稍后重试';
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
