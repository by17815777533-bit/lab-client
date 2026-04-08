import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/admin_student_record.dart';
import '../../models/paged_result.dart';
import '../../models/user_profile.dart';
import '../../repositories/student_management_repository.dart';

class StudentManagementController extends ChangeNotifier {
  StudentManagementController({
    required StudentManagementRepository repository,
    required UserProfile profile,
  }) : _repository = repository,
       _profile = profile;

  final StudentManagementRepository _repository;
  final UserProfile _profile;

  bool _loading = false;
  bool _deleting = false;
  String? _errorMessage;
  PagedResult<AdminStudentRecord>? _page;

  int _pageNum = 1;
  final int _pageSize = 10;
  String _keyword = '';
  String _realName = '';
  String _studentId = '';
  String _major = '';

  bool get loading => _loading;
  bool get deleting => _deleting;
  String? get errorMessage => _errorMessage;
  UserProfile get profile => _profile;
  List<AdminStudentRecord> get students =>
      _page?.records ?? <AdminStudentRecord>[];
  int get pageNum => _pageNum;
  int get totalPages => _page?.pages ?? 0;
  int get total => _page?.total ?? 0;
  String get keyword => _keyword;
  String get realName => _realName;
  String get studentId => _studentId;
  String get major => _major;
  bool get canDeleteStudents => _profile.schoolDirector;
  bool get scopedToLab => !_profile.schoolDirector && _profile.labId != null;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _page = await _repository.fetchStudents(
        pageNum: _pageNum,
        pageSize: _pageSize,
        keyword: _keyword.isEmpty ? null : _keyword,
        realName: _realName.isEmpty ? null : _realName,
        studentId: _studentId.isEmpty ? null : _studentId,
        major: _major.isEmpty ? null : _major,
      );
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '学生列表加载失败，请稍后重试';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  void updateFilters({
    String? keyword,
    String? realName,
    String? studentId,
    String? major,
  }) {
    _keyword = (keyword ?? _keyword).trim();
    _realName = (realName ?? _realName).trim();
    _studentId = (studentId ?? _studentId).trim();
    _major = (major ?? _major).trim();
    _pageNum = 1;
    notifyListeners();
  }

  void resetFilters() {
    _keyword = '';
    _realName = '';
    _studentId = '';
    _major = '';
    _pageNum = 1;
    notifyListeners();
  }

  Future<void> search() => load();

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

  Future<bool> deleteStudent(int id) async {
    _deleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteStudent(id);
      final targetPage = students.length <= 1 && _pageNum > 1
          ? _pageNum - 1
          : _pageNum;
      _pageNum = targetPage;
      await load();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '学生账号删除失败，请稍后重试';
      return false;
    } finally {
      _deleting = false;
      notifyListeners();
    }
  }
}
