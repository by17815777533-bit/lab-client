import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/lab_summary.dart';
import '../../models/paged_result.dart';
import '../../models/recruit_plan.dart';
import '../../models/user_profile.dart';
import '../../repositories/lab_repository.dart';
import '../../repositories/plan_repository.dart';

class RecruitPlanManagementController extends ChangeNotifier {
  RecruitPlanManagementController({
    required PlanRepository repository,
    required LabRepository labRepository,
    required UserProfile profile,
  }) : _repository = repository,
       _labRepository = labRepository,
       _profile = profile {
    _selectedLabId = profile.labId;
  }

  final PlanRepository _repository;
  final LabRepository _labRepository;
  final UserProfile _profile;

  bool _loading = false;
  bool _saving = false;
  bool _deleting = false;
  String? _errorMessage;

  PagedResult<RecruitPlan>? _page;
  List<LabSummary> _labOptions = <LabSummary>[];

  int _pageNum = 1;
  final int _pageSize = 10;
  int? _selectedLabId;
  String? _status;
  String _keyword = '';

  bool get loading => _loading;
  bool get saving => _saving;
  bool get deleting => _deleting;
  String? get errorMessage => _errorMessage;
  UserProfile get profile => _profile;
  List<RecruitPlan> get records => _page?.records ?? <RecruitPlan>[];
  List<LabSummary> get labOptions => _labOptions;
  int get pageNum => _pageNum;
  int get total => _page?.total ?? 0;
  int get totalPages => _page?.pages ?? 0;
  String get keyword => _keyword;
  String? get status => _status;
  int? get selectedLabId => _selectedLabId;
  bool get canSelectLab => _profile.schoolDirector || _profile.labId == null;
  bool get requireLabSelection =>
      !_profile.schoolDirector && _profile.labId == null;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.wait<void>(<Future<void>>[
      if (canSelectLab) _loadLabOptions(),
      if (!requireLabSelection || _selectedLabId != null)
        _loadPlans(pageNum: _pageNum),
    ]);

    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() => load();

  void setSelectedLabId(int? value) {
    if (!canSelectLab && value != _profile.labId) {
      return;
    }
    if (_selectedLabId == value) {
      return;
    }
    _selectedLabId = value;
    _pageNum = 1;
    notifyListeners();
  }

  void setStatus(String? value) {
    if (_status == value) {
      return;
    }
    _status = value;
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

  Future<void> search() async {
    if (requireLabSelection && _selectedLabId == null) {
      _page = null;
      _errorMessage = '请先选择实验室';
      notifyListeners();
      return;
    }
    await _loadPlans(pageNum: 1);
  }

  Future<void> previousPage() async {
    if (_pageNum <= 1) {
      return;
    }
    await _loadPlans(pageNum: _pageNum - 1);
  }

  Future<void> nextPage() async {
    if (_pageNum >= (_page?.pages ?? 0)) {
      return;
    }
    await _loadPlans(pageNum: _pageNum + 1);
  }

  Future<bool> savePlan({
    int? id,
    required int labId,
    required String title,
    required String startTime,
    required String endTime,
    required int quota,
    String? requirement,
    required String status,
  }) async {
    _saving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (id == null) {
        await _repository.createPlan(
          labId: labId,
          title: title,
          startTime: startTime,
          endTime: endTime,
          quota: quota,
          requirement: requirement,
          status: status,
        );
      } else {
        await _repository.updatePlan(
          id: id,
          labId: labId,
          title: title,
          startTime: startTime,
          endTime: endTime,
          quota: quota,
          requirement: requirement,
          status: status,
        );
      }
      await _loadPlans(pageNum: _pageNum);
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '保存招新计划失败，请稍后重试';
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<bool> deletePlan(int id) async {
    _deleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deletePlan(id);
      final targetPage = records.length <= 1 && _pageNum > 1
          ? _pageNum - 1
          : _pageNum;
      await _loadPlans(pageNum: targetPage);
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '删除招新计划失败，请稍后重试';
      return false;
    } finally {
      _deleting = false;
      notifyListeners();
    }
  }

  Future<void> _loadPlans({required int pageNum}) async {
    try {
      _pageNum = pageNum;
      _page = await _repository.fetchPlanPage(
        pageNum: pageNum,
        pageSize: _pageSize,
        labId: canSelectLab ? _selectedLabId : _profile.labId,
        status: _status,
        keyword: _keyword.isEmpty ? null : _keyword,
      );
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '招新计划加载失败，请稍后重试';
    }
  }

  Future<void> _loadLabOptions() async {
    try {
      final page = await _labRepository.fetchLabs(pageSize: 100);
      _labOptions = page.records
          .where((LabSummary item) {
            if (_profile.schoolDirector) {
              return true;
            }
            if (_profile.managedCollegeId != null) {
              return item.collegeId == _profile.managedCollegeId;
            }
            return true;
          })
          .toList(growable: false);
    } on ApiException catch (error) {
      _errorMessage ??= error.message;
    } catch (_) {
      _errorMessage ??= '实验室列表加载失败，请稍后重试';
    }
  }
}
