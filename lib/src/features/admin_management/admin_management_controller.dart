import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../repositories/admin_management_repository.dart';
import 'admin_management_models.dart';

class AdminManagementController extends ChangeNotifier {
  AdminManagementController({required AdminManagementRepository repository})
    : _repository = repository;

  final AdminManagementRepository _repository;

  bool _loading = false;
  bool _assigning = false;
  bool _removing = false;
  String? _errorMessage;
  String _keyword = '';

  List<LabAdminAssignment> _assignments = <LabAdminAssignment>[];
  List<AdminManagerUser> _students = <AdminManagerUser>[];

  bool get loading => _loading;
  bool get assigning => _assigning;
  bool get removing => _removing;
  String? get errorMessage => _errorMessage;
  String get keyword => _keyword;
  List<AdminManagerUser> get students => _students;

  List<LabAdminAssignment> get assignments {
    if (_keyword.isEmpty) {
      return _assignments;
    }
    final normalized = _keyword.toLowerCase();
    return _assignments
        .where((LabAdminAssignment item) {
          return item.lab.labName.toLowerCase().contains(normalized) ||
              (item.lab.labDesc ?? '').toLowerCase().contains(normalized) ||
              (item.admin?.realName ?? '').toLowerCase().contains(normalized) ||
              (item.admin?.username ?? '').toLowerCase().contains(normalized);
        })
        .toList(growable: false);
  }

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.wait<void>(<Future<void>>[
      _loadAssignments(),
      _loadStudents(),
    ]);

    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() => load();

  void setKeyword(String value) {
    final next = value.trim();
    if (_keyword == next) {
      return;
    }
    _keyword = next;
    notifyListeners();
  }

  List<AdminManagerUser> filterStudents(String keyword) {
    final normalized = keyword.trim().toLowerCase();
    if (normalized.isEmpty) {
      return _students;
    }
    return _students
        .where((AdminManagerUser item) {
          return item.realName.toLowerCase().contains(normalized) ||
              item.username.toLowerCase().contains(normalized) ||
              (item.studentId ?? '').toLowerCase().contains(normalized) ||
              (item.college ?? '').toLowerCase().contains(normalized);
        })
        .toList(growable: false);
  }

  Future<bool> assignAdmin({required int labId, required int userId}) async {
    _assigning = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.assignAdminToLab(labId: labId, userId: userId);
      await load();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '指定管理员失败，请稍后重试';
      return false;
    } finally {
      _assigning = false;
      notifyListeners();
    }
  }

  Future<bool> removeAdmin(int labId) async {
    _removing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.removeAdminFromLab(labId);
      await load();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '移除管理员失败，请稍后重试';
      return false;
    } finally {
      _removing = false;
      notifyListeners();
    }
  }

  Future<void> _loadAssignments() async {
    try {
      _assignments = await _repository.fetchLabsWithAdmin();
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '实验室管理员数据加载失败，请稍后重试';
    }
  }

  Future<void> _loadStudents() async {
    try {
      _students = await _repository.fetchStudentCandidates();
    } on ApiException catch (error) {
      _errorMessage ??= error.message;
    } catch (_) {
      _errorMessage ??= '学生候选名单加载失败，请稍后重试';
    }
  }
}
