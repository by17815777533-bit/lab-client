import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/paged_result.dart';
import '../../repositories/lab_create_apply_repository.dart';
import 'lab_create_apply_models.dart';

class LabCreateApplyController extends ChangeNotifier {
  LabCreateApplyController(this._repository);

  final LabCreateApplyRepository _repository;

  bool _loading = false;
  bool _submitting = false;
  String? _errorMessage;
  int _pageNum = 1;
  final int _pageSize = 10;
  String? _statusFilter;
  String _keyword = '';
  PagedResult<LabCreateApplyItem>? _page;
  List<LabCreateApplyCollegeOption> _collegeOptions =
      <LabCreateApplyCollegeOption>[];

  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get errorMessage => _errorMessage;
  int get pageNum => _pageNum;
  int get pageSize => _pageSize;
  int get total => _page?.total ?? 0;
  int get totalPages => _page?.pages ?? 0;
  String? get statusFilter => _statusFilter;
  String get keyword => _keyword;
  List<LabCreateApplyItem> get records =>
      _page?.records ?? <LabCreateApplyItem>[];
  List<LabCreateApplyCollegeOption> get collegeOptions => _collegeOptions;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _repository.fetchApplyPage(
          pageNum: _pageNum,
          pageSize: _pageSize,
          status: _statusFilter,
          keyword: _keyword.isEmpty ? null : _keyword,
        ),
        _repository.fetchCollegeOptions(),
      ]);

      _page = results[0] as PagedResult<LabCreateApplyItem>;
      _collegeOptions = results[1] as List<LabCreateApplyCollegeOption>;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '加载实验室创建申请失败，请稍后重试';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  Future<void> applyKeyword(String value) async {
    _keyword = value.trim();
    _pageNum = 1;
    await load();
  }

  Future<void> applyStatus(String? value) async {
    _statusFilter = value;
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
    if (_page != null && _pageNum >= _page!.pages) {
      return;
    }
    _pageNum += 1;
    await load();
  }

  Future<bool> submitApply({
    required int collegeId,
    required String labName,
    required String teacherName,
    String? location,
    String? contactEmail,
    required String researchDirection,
    required String applyReason,
  }) async {
    _submitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.createApply(
        collegeId: collegeId,
        labName: labName,
        teacherName: teacherName,
        location: location,
        contactEmail: contactEmail,
        researchDirection: researchDirection,
        applyReason: applyReason,
      );
      await load();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '提交实验室创建申请失败，请稍后重试';
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  String statusLabel(String? status) {
    switch (status) {
      case 'submitted':
        return '待学院审核';
      case 'college_approved':
        return '待学校审核';
      case 'approved':
        return '已通过';
      case 'rejected':
        return '已驳回';
      case null:
      case '':
        return '全部';
      default:
        return status;
    }
  }
}
