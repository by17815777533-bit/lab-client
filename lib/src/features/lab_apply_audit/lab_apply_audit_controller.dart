import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/paged_result.dart';
import '../../repositories/lab_apply_audit_repository.dart';
import 'lab_apply_audit_models.dart';

class LabApplyAuditController extends ChangeNotifier {
  LabApplyAuditController({
    required LabApplyAuditRepository repository,
    required bool requireLabSelection,
    int? initialLabId,
  }) : _repository = repository,
       _requireLabSelection = requireLabSelection,
       _labId = initialLabId;

  final LabApplyAuditRepository _repository;
  final bool _requireLabSelection;

  bool _loading = false;
  bool _submitting = false;
  String? _errorMessage;
  int _pageNum = 1;
  final int _pageSize = 10;
  int? _labId;
  String? _statusFilter;
  String _keyword = '';
  PagedResult<LabApplyAuditRecord>? _page;

  bool get loading => _loading;
  bool get submitting => _submitting;
  bool get requireLabSelection => _requireLabSelection;
  String? get errorMessage => _errorMessage;
  int get pageNum => _pageNum;
  int get pageSize => _pageSize;
  int? get labId => _labId;
  String? get statusFilter => _statusFilter;
  String get keyword => _keyword;
  int get total => _page?.total ?? 0;
  int get totalPages => _page?.pages ?? 0;
  List<LabApplyAuditRecord> get records =>
      _page?.records ?? <LabApplyAuditRecord>[];

  Future<void> load() async {
    if (_requireLabSelection && _labId == null) {
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
        keyword: _keyword.trim().isEmpty ? null : _keyword.trim(),
      );
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '申请列表加载失败，请稍后重试';
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
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    if (_statusFilter == status) {
      return;
    }
    _statusFilter = status;
    _pageNum = 1;
    notifyListeners();
  }

  void setKeyword(String value) {
    final next = value.trim();
    if (_keyword == next) {
      return;
    }
    _keyword = next;
    _pageNum = 1;
    notifyListeners();
  }

  void resetFilters({int? initialLabId}) {
    _labId = initialLabId;
    _statusFilter = null;
    _keyword = '';
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
    required String action,
    String? auditComment,
  }) async {
    _submitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.auditApplication(
        id: id,
        action: action,
        auditComment: auditComment,
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
