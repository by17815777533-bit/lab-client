import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../models/attendance_record.dart';
import '../../models/attendance_summary.dart';
import '../../models/lab_daily_attendance_member.dart';
import '../../models/lab_member_summary.dart';
import '../../models/lab_space_overview.dart';
import '../../models/paged_result.dart';
import '../../models/space_file_item.dart';
import '../../models/space_folder_node.dart';
import '../../models/user_profile.dart';
import '../../repositories/lab_space_repository.dart';

class WorkspaceController extends ChangeNotifier {
  WorkspaceController({
    required LabSpaceRepository repository,
    required UserProfile profile,
  }) : _repository = repository,
       _profile = profile;

  final LabSpaceRepository _repository;
  final UserProfile _profile;

  LabSpaceOverview? _overview;
  List<LabMemberSummary> _activeMembers = <LabMemberSummary>[];
  List<SpaceFolderNode> _folders = <SpaceFolderNode>[];
  List<SpaceFileItem> _recentFiles = <SpaceFileItem>[];
  List<LabDailyAttendanceMember> _dailyAttendance =
      <LabDailyAttendanceMember>[];
  PagedResult<SpaceFileItem>? _filesPage;
  PagedResult<AttendanceRecord>? _attendancePage;
  AttendanceSummary? _attendanceSummary;
  bool _loading = false;
  bool _loadingFiles = false;
  bool _loadingAttendance = false;
  bool _loadingDailyAttendance = false;
  bool _signingIn = false;
  bool _uploadingFile = false;
  String? _errorMessage;
  int? _selectedFolderId;
  int _filePageNum = 1;
  final int _filePageSize = 10;
  int _attendancePageNum = 1;
  final int _attendancePageSize = 8;
  int? _fileArchiveFlag;
  String _fileKeyword = '';
  int _signStatus = 1;
  String _signReason = '';
  String _dailyAttendanceDate = DateTimeFormatter.date(DateTime.now());
  final Set<int> _savingAttendanceUserIds = <int>{};
  final Set<int> _updatingArchiveFileIds = <int>{};

  bool get hasLab => _profile.labId != null;
  bool get canUploadFiles => _profile.isStudent || _profile.isAdmin;
  bool get canArchiveFiles => _profile.isAdmin;
  bool get canViewDailyAttendance => !_profile.isStudent;
  bool get canConfirmDailyAttendance => _profile.isAdmin;
  bool get loading => _loading;
  bool get loadingFiles => _loadingFiles;
  bool get loadingAttendance => _loadingAttendance;
  bool get loadingDailyAttendance => _loadingDailyAttendance;
  bool get signingIn => _signingIn;
  bool get uploadingFile => _uploadingFile;
  String? get errorMessage => _errorMessage;
  LabSpaceOverview? get overview => _overview;
  AttendanceSummary? get attendanceSummary =>
      _overview?.attendanceSummary ?? _attendanceSummary;
  List<LabMemberSummary> get activeMembers => _activeMembers.isNotEmpty
      ? _activeMembers
      : (_overview?.members ?? const <LabMemberSummary>[]);
  List<SpaceFolderNode> get folders => _folders;
  List<SpaceFileItem> get recentFiles => _recentFiles.isNotEmpty
      ? _recentFiles
      : (_overview?.recentFiles ?? const <SpaceFileItem>[]);
  List<LabDailyAttendanceMember> get dailyAttendance => _dailyAttendance;
  PagedResult<SpaceFileItem>? get filesPage => _filesPage;
  PagedResult<AttendanceRecord>? get attendancePage => _attendancePage;
  int? get selectedFolderId => _selectedFolderId;
  int get filePageNum => _filePageNum;
  int get filePageSize => _filePageSize;
  int get fileTotalPages => _filesPage?.pages ?? 0;
  int get fileTotal => _filesPage?.total ?? 0;
  int get attendancePageNum => _attendancePageNum;
  int get attendancePageSize => _attendancePageSize;
  int get attendanceTotalPages => _attendancePage?.pages ?? 0;
  int get attendanceTotal => _attendancePage?.total ?? 0;
  int? get fileArchiveFlag => _fileArchiveFlag;
  String get fileKeyword => _fileKeyword;
  int get signStatus => _signStatus;
  String get signReason => _signReason;
  String get currentDate => DateTimeFormatter.date(DateTime.now());
  String get dailyAttendanceDate => _dailyAttendanceDate;

  bool isSavingAttendance(int userId) =>
      _savingAttendanceUserIds.contains(userId);
  bool isUpdatingArchive(int fileId) =>
      _updatingArchiveFileIds.contains(fileId);

  Future<void> refreshAll() async {
    if (!hasLab) {
      _clearState();
      notifyListeners();
      return;
    }

    _loading = true;
    _errorMessage = null;
    notifyListeners();

    await _safeRun(_loadOverview);
    await _safeRun(_loadMembers);
    await _safeRun(_loadFolders);
    await _safeRun(_loadRecentFiles);
    await _safeRun(() => _loadFiles(pageNum: 1));
    if (_profile.isStudent) {
      await _safeRun(() => _loadAttendance(pageNum: 1));
    } else {
      _attendancePage = null;
    }
    if (canViewDailyAttendance) {
      await _safeRun(_loadDailyAttendance);
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> refreshFiles() async {
    if (!hasLab) {
      return;
    }

    _loadingFiles = true;
    _errorMessage = null;
    notifyListeners();

    await _safeRun(() => _loadFiles(pageNum: _filePageNum));
    await _safeRun(_loadRecentFiles);

    _loadingFiles = false;
    notifyListeners();
  }

  Future<void> refreshAttendance() async {
    if (!hasLab || !_profile.isStudent) {
      return;
    }

    _loadingAttendance = true;
    _errorMessage = null;
    notifyListeners();

    await _safeRun(() => _loadAttendance(pageNum: _attendancePageNum));

    _loadingAttendance = false;
    notifyListeners();
  }

  Future<void> refreshDailyAttendance() async {
    if (!hasLab || !canViewDailyAttendance) {
      return;
    }

    _loadingDailyAttendance = true;
    _errorMessage = null;
    notifyListeners();

    await _safeRun(_loadDailyAttendance);
    await _safeRun(_loadOverview);

    _loadingDailyAttendance = false;
    notifyListeners();
  }

  void setSelectedFolder(int? folderId) {
    if (_selectedFolderId == folderId) {
      return;
    }
    _selectedFolderId = folderId;
    notifyListeners();
  }

  void setFileKeyword(String value) {
    _fileKeyword = value.trim();
    notifyListeners();
  }

  void setFileArchiveFlag(int? value) {
    _fileArchiveFlag = value;
    notifyListeners();
  }

  void setSignStatus(int value) {
    _signStatus = value;
    notifyListeners();
  }

  void setSignReason(String value) {
    _signReason = value;
    notifyListeners();
  }

  void setDailyAttendanceDate(DateTime value) {
    final next = DateTimeFormatter.date(value);
    if (_dailyAttendanceDate == next) {
      return;
    }
    _dailyAttendanceDate = next;
    notifyListeners();
  }

  Future<bool> signIn() async {
    if (!hasLab) {
      _errorMessage = '当前账号尚未加入实验室';
      notifyListeners();
      return false;
    }

    _signingIn = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.signIn(
        attendanceDate: currentDate,
        status: _signStatus,
        reason: _signReason.trim().isEmpty ? null : _signReason.trim(),
      );
      await refreshAttendance();
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

  Future<bool> uploadFile(PlatformFile file) async {
    if (!hasLab) {
      _errorMessage = '当前账号尚未加入实验室';
      notifyListeners();
      return false;
    }
    if (!canUploadFiles) {
      _errorMessage = '当前账号暂无上传权限';
      notifyListeners();
      return false;
    }

    final folderId = _selectedFolderId ?? _firstFolderId();
    if (folderId == null) {
      _errorMessage = '请先选择一个资料目录';
      notifyListeners();
      return false;
    }

    _uploadingFile = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.uploadFile(
        file: file,
        folderId: folderId,
        labId: _profile.labId,
        archiveFlag: 0,
      );
      await _safeRun(_loadOverview);
      await refreshFiles();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '文件上传失败，请稍后重试';
      return false;
    } finally {
      _uploadingFile = false;
      notifyListeners();
    }
  }

  Future<bool> toggleArchive(SpaceFileItem file) async {
    if (!canArchiveFiles) {
      _errorMessage = '当前账号暂无归档权限';
      notifyListeners();
      return false;
    }

    _updatingArchiveFileIds.add(file.id);
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateFileArchive(
        fileId: file.id,
        archiveFlag: file.isArchived ? 0 : 1,
      );
      await _safeRun(_loadOverview);
      await _safeRun(_loadRecentFiles);
      await _safeRun(() => _loadFiles(pageNum: _filePageNum));
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = file.isArchived ? '取消归档失败，请稍后重试' : '归档失败，请稍后重试';
      return false;
    } finally {
      _updatingArchiveFileIds.remove(file.id);
      notifyListeners();
    }
  }

  Future<bool> confirmDailyAttendance({
    required int userId,
    required int status,
    String? reason,
  }) async {
    if (!canConfirmDailyAttendance) {
      _errorMessage = '当前账号暂无确认权限';
      notifyListeners();
      return false;
    }

    _savingAttendanceUserIds.add(userId);
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.confirmAttendance(
        labId: _profile.labId,
        userId: userId,
        attendanceDate: _dailyAttendanceDate,
        status: status,
        reason: reason?.trim().isEmpty ?? true ? null : reason!.trim(),
      );
      await _safeRun(_loadDailyAttendance);
      await _safeRun(_loadOverview);
      await _safeRun(_loadAttendanceSummary);
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '考勤确认失败，请稍后重试';
      return false;
    } finally {
      _savingAttendanceUserIds.remove(userId);
      notifyListeners();
    }
  }

  Future<void> goToFilePage(int pageNum) async {
    if (pageNum < 1) {
      return;
    }
    _filePageNum = pageNum;
    await refreshFiles();
  }

  Future<void> goToAttendancePage(int pageNum) async {
    if (pageNum < 1) {
      return;
    }
    _attendancePageNum = pageNum;
    await refreshAttendance();
  }

  Future<void> _safeRun(Future<void> Function() action) async {
    try {
      await action();
    } on ApiException catch (error) {
      _errorMessage ??= error.message;
    } catch (_) {
      _errorMessage ??= '请求失败，请稍后重试';
    }
  }

  Future<void> _loadOverview() async {
    final labId = _profile.labId;
    if (labId == null) {
      _overview = null;
      _attendanceSummary = null;
      return;
    }

    _overview = await _repository.fetchOverview(labId: labId);
    _attendanceSummary =
        _overview?.attendanceSummary ??
        await _repository.fetchAttendanceSummary(labId: labId);
  }

  Future<void> _loadAttendanceSummary() async {
    final labId = _profile.labId;
    if (labId == null) {
      _attendanceSummary = null;
      return;
    }

    _attendanceSummary = await _repository.fetchAttendanceSummary(labId: labId);
  }

  Future<void> _loadMembers() async {
    final labId = _profile.labId;
    if (labId == null) {
      _activeMembers = <LabMemberSummary>[];
      return;
    }

    _activeMembers = await _repository.fetchActiveMembers(labId: labId);
  }

  Future<void> _loadFolders() async {
    final labId = _profile.labId;
    if (labId == null) {
      _folders = <SpaceFolderNode>[];
      _selectedFolderId = null;
      return;
    }

    _folders = await _repository.fetchFolders(labId: labId);
    _selectedFolderId ??= _firstFolderId();
  }

  Future<void> _loadFiles({required int pageNum}) async {
    final labId = _profile.labId;
    if (labId == null) {
      _filesPage = null;
      return;
    }

    _filePageNum = pageNum;
    _filesPage = await _repository.fetchFiles(
      pageNum: pageNum,
      pageSize: _filePageSize,
      labId: labId,
      folderId: _selectedFolderId,
      archiveFlag: _fileArchiveFlag,
      keyword: _fileKeyword.isEmpty ? null : _fileKeyword,
    );
  }

  Future<void> _loadRecentFiles() async {
    final labId = _profile.labId;
    if (labId == null) {
      _recentFiles = <SpaceFileItem>[];
      return;
    }

    _recentFiles = await _repository.fetchRecentFiles(labId: labId, limit: 6);
  }

  Future<void> _loadAttendance({required int pageNum}) async {
    if (!hasLab || !_profile.isStudent) {
      _attendancePage = null;
      return;
    }

    _attendancePageNum = pageNum;
    _attendancePage = await _repository.fetchMyAttendance(
      pageNum: pageNum,
      pageSize: _attendancePageSize,
    );
  }

  Future<void> _loadDailyAttendance() async {
    final labId = _profile.labId;
    if (labId == null || !canViewDailyAttendance) {
      _dailyAttendance = <LabDailyAttendanceMember>[];
      return;
    }

    _dailyAttendance = await _repository.fetchDailyAttendance(
      labId: labId,
      attendanceDate: _dailyAttendanceDate,
    );
  }

  int? _firstFolderId() {
    final queue = List<SpaceFolderNode>.from(_folders);
    while (queue.isNotEmpty) {
      final node = queue.removeAt(0);
      if (node.id != 0) {
        return node.id;
      }
      queue.addAll(node.children);
    }
    return null;
  }

  void _clearState() {
    _overview = null;
    _activeMembers = <LabMemberSummary>[];
    _folders = <SpaceFolderNode>[];
    _recentFiles = <SpaceFileItem>[];
    _dailyAttendance = <LabDailyAttendanceMember>[];
    _filesPage = null;
    _attendancePage = null;
    _attendanceSummary = null;
    _selectedFolderId = null;
    _filePageNum = 1;
    _attendancePageNum = 1;
    _dailyAttendanceDate = DateTimeFormatter.date(DateTime.now());
    _savingAttendanceUserIds.clear();
    _updatingArchiveFileIds.clear();
    _errorMessage = null;
  }
}
