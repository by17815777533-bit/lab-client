import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../features/lab_create_apply/lab_create_apply_models.dart';
import '../../models/paged_result.dart';
import '../../models/user_profile.dart';
import '../../repositories/attendance_workflow_repository.dart';
import 'attendance_management_models.dart';

class AttendanceManagementController extends ChangeNotifier {
  AttendanceManagementController({
    required AttendanceWorkflowRepository repository,
    required UserProfile profile,
  }) : _repository = repository,
       _profile = profile {
    if (_profile.collegeManager && !_profile.schoolDirector) {
      _collegeId = _profile.managedCollegeId;
    }
  }

  final AttendanceWorkflowRepository _repository;
  final UserProfile _profile;

  bool _loading = false;
  bool _loadingTasks = false;
  bool _loadingSession = false;
  bool _savingTask = false;
  bool _savingSchedules = false;
  bool _publishingTask = false;
  bool _reviewingRecord = false;
  bool _uploadingPhoto = false;
  bool _assigningDuty = false;

  String? _errorMessage;
  String? _sessionHint;

  AttendanceWorkflowSummary? _summary;
  PagedResult<AttendanceTaskItem>? _taskPage;
  AttendanceLabCurrentSession? _currentSession;
  List<LabCreateApplyCollegeOption> _collegeOptions =
      <LabCreateApplyCollegeOption>[];

  int _pageNum = 1;
  final int _pageSize = 10;
  int? _collegeId;
  String _keyword = '';

  bool get loading => _loading;
  bool get loadingTasks => _loadingTasks;
  bool get loadingSession => _loadingSession;
  bool get savingTask => _savingTask;
  bool get savingSchedules => _savingSchedules;
  bool get publishingTask => _publishingTask;
  bool get reviewingRecord => _reviewingRecord;
  bool get uploadingPhoto => _uploadingPhoto;
  bool get assigningDuty => _assigningDuty;
  String? get errorMessage => _errorMessage;
  String? get sessionHint => _sessionHint;
  UserProfile get profile => _profile;

  bool get canViewSummary => _profile.isAdmin;
  bool get canManageTasks => _profile.schoolDirector || _profile.collegeManager;
  bool get canViewCurrentSession => _profile.isTeacher || _profile.labManager;
  bool get canReviewRecords => _profile.isAdmin && _profile.labManager;
  bool get canUploadPhoto => _profile.isAdmin && _profile.labManager;
  bool get canAssignDuty =>
      canViewCurrentSession &&
      (_profile.schoolDirector || _profile.collegeManager);

  AttendanceWorkflowSummary? get summary => _summary;
  PagedResult<AttendanceTaskItem>? get taskPage => _taskPage;
  AttendanceLabCurrentSession? get currentSession => _currentSession;
  List<LabCreateApplyCollegeOption> get collegeOptions => _collegeOptions;
  List<AttendanceTaskItem> get tasks => _taskPage?.records ?? <AttendanceTaskItem>[];
  int get pageNum => _pageNum;
  int get pageSize => _pageSize;
  int get total => _taskPage?.total ?? 0;
  int get totalPages => _taskPage?.pages ?? 0;
  int? get collegeId => _collegeId;
  String get keyword => _keyword;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.wait<void>(<Future<void>>[
      if (_profile.schoolDirector) _loadCollegeOptions(),
      if (canViewSummary) _loadSummary(),
      if (canManageTasks) _loadTasks(pageNum: 1),
      if (canViewCurrentSession) _loadCurrentSession(),
    ]);

    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() => load();

  void setCollegeId(int? value) {
    if (!canManageTasks || (_profile.collegeManager && !_profile.schoolDirector)) {
      return;
    }
    if (_collegeId == value) {
      return;
    }
    _collegeId = value;
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

  Future<void> searchTasks() async {
    if (!canManageTasks) {
      return;
    }
    await _loadTasks(pageNum: 1);
  }

  Future<void> previousPage() async {
    if (_pageNum <= 1) {
      return;
    }
    await _loadTasks(pageNum: _pageNum - 1);
  }

  Future<void> nextPage() async {
    if (_taskPage != null && _pageNum >= _taskPage!.pages) {
      return;
    }
    await _loadTasks(pageNum: _pageNum + 1);
  }

  Future<bool> saveTask({
    int? id,
    required int? collegeId,
    required String semesterName,
    required String taskName,
    String? description,
    required String startDate,
    required String endDate,
  }) async {
    _savingTask = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.saveTask(
        id: id,
        collegeId: collegeId,
        semesterName: semesterName,
        taskName: taskName,
        description: description,
        startDate: startDate,
        endDate: endDate,
      );
      await Future.wait<void>(<Future<void>>[
        _loadTasks(pageNum: _pageNum),
        if (canViewSummary) _loadSummary(),
      ]);
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '保存考勤任务失败，请稍后重试';
      return false;
    } finally {
      _savingTask = false;
      notifyListeners();
    }
  }

  Future<bool> publishTask(int taskId) async {
    _publishingTask = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.publishTask(taskId);
      await Future.wait<void>(<Future<void>>[
        _loadTasks(pageNum: _pageNum),
        if (canViewSummary) _loadSummary(),
        if (canViewCurrentSession) _loadCurrentSession(),
      ]);
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '发布考勤任务失败，请稍后重试';
      return false;
    } finally {
      _publishingTask = false;
      notifyListeners();
    }
  }

  Future<List<AttendanceScheduleItem>> loadTaskSchedules(int taskId) {
    return _repository.fetchTaskSchedules(taskId);
  }

  Future<bool> saveTaskSchedules(
    int taskId,
    List<AttendanceScheduleItem> schedules,
  ) async {
    _savingSchedules = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.saveTaskSchedules(taskId, schedules);
      await Future.wait<void>(<Future<void>>[
        _loadTasks(pageNum: _pageNum),
        if (canViewSummary) _loadSummary(),
      ]);
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '保存排班失败，请稍后重试';
      return false;
    } finally {
      _savingSchedules = false;
      notifyListeners();
    }
  }

  Future<void> refreshCurrentSession() async {
    if (!canViewCurrentSession) {
      return;
    }

    _loadingSession = true;
    _errorMessage = null;
    _sessionHint = null;
    notifyListeners();

    await _loadCurrentSession();

    _loadingSession = false;
    notifyListeners();
  }

  Future<bool> reviewRecord({
    required int sessionId,
    required int userId,
    required String signStatus,
    String? remark,
  }) async {
    _reviewingRecord = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.reviewLabRecord(
        sessionId: sessionId,
        userId: userId,
        signStatus: signStatus,
        remark: remark,
      );
      await Future.wait<void>(<Future<void>>[
        _loadCurrentSession(),
        if (canViewSummary) _loadSummary(),
      ]);
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '保存考勤结果失败，请稍后重试';
      return false;
    } finally {
      _reviewingRecord = false;
      notifyListeners();
    }
  }

  Future<bool> uploadPhoto(PlatformFile file, {String? remark}) async {
    _uploadingPhoto = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.uploadCurrentSessionPhoto(file: file, remark: remark);
      await Future.wait<void>(<Future<void>>[
        _loadCurrentSession(),
        if (canViewSummary) _loadSummary(),
      ]);
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '上传现场照片失败，请稍后重试';
      return false;
    } finally {
      _uploadingPhoto = false;
      notifyListeners();
    }
  }

  Future<bool> assignCurrentUserDuty({String? remark}) async {
    final session = _currentSession;
    if (session == null) {
      _errorMessage = '当前没有可设置值班的会话';
      notifyListeners();
      return false;
    }

    _assigningDuty = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.setSessionDuty(
        sessionId: session.id,
        dutyAdminUserId: _profile.id,
        remark: remark,
      );
      await _loadCurrentSession();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '设置值班失败，请稍后重试';
      return false;
    } finally {
      _assigningDuty = false;
      notifyListeners();
    }
  }

  Future<void> _loadCollegeOptions() async {
    try {
      _collegeOptions = await _repository.fetchCollegeOptions();
    } on ApiException catch (error) {
      _errorMessage ??= error.message;
    } catch (_) {
      _errorMessage ??= '学院选项加载失败，请稍后重试';
    }
  }

  Future<void> _loadSummary() async {
    try {
      _summary = await _repository.fetchSummary(labId: _profile.labId);
    } on ApiException catch (error) {
      _errorMessage ??= error.message;
    } catch (_) {
      _errorMessage ??= '统计摘要加载失败，请稍后重试';
    }
  }

  Future<void> _loadTasks({required int pageNum}) async {
    _loadingTasks = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _pageNum = pageNum;
      _taskPage = await _repository.fetchTaskPage(
        pageNum: pageNum,
        pageSize: _pageSize,
        collegeId: _collegeId,
        keyword: _keyword.isEmpty ? null : _keyword,
      );
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '考勤任务加载失败，请稍后重试';
    } finally {
      _loadingTasks = false;
      notifyListeners();
    }
  }

  Future<void> _loadCurrentSession() async {
    _loadingSession = true;
    _sessionHint = null;
    notifyListeners();

    try {
      _currentSession = await _repository.fetchCurrentLabSession();
    } on ApiException catch (error) {
      _currentSession = null;
      _sessionHint = _mapSessionHint(error.message);
    } catch (_) {
      _currentSession = null;
      _sessionHint = '当前没有进行中的考勤会话';
    } finally {
      _loadingSession = false;
      notifyListeners();
    }
  }

  String _mapSessionHint(String message) {
    if (message.contains('No published attendance task')) {
      return '今日还没有可用的考勤任务。';
    }
    if (message.contains('No attendance schedule')) {
      return '今日还没有配置考勤排班。';
    }
    if (message.contains('not bound to a managed lab')) {
      return '当前账号未绑定可管理的实验室。';
    }
    return message;
  }
}
