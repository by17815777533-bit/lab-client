import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/lab_summary.dart';
import '../../repositories/admin_management_repository.dart';
import '../../repositories/lab_repository.dart';
import '../admin_management/admin_management_models.dart';

class AdminAccountsController extends ChangeNotifier {
  AdminAccountsController({
    required AdminManagementRepository repository,
    required LabRepository labRepository,
  }) : _repository = repository,
       _labRepository = labRepository;

  final AdminManagementRepository _repository;
  final LabRepository _labRepository;

  bool _loading = false;
  bool _saving = false;
  bool _deleting = false;
  String? _errorMessage;
  String _keyword = '';

  List<AdminManagerUser> _admins = <AdminManagerUser>[];
  List<LabSummary> _labs = <LabSummary>[];

  bool get loading => _loading;
  bool get saving => _saving;
  bool get deleting => _deleting;
  String? get errorMessage => _errorMessage;
  String get keyword => _keyword;
  List<LabSummary> get labs => _labs;

  List<AdminManagerUser> get admins {
    if (_keyword.isEmpty) {
      return _admins;
    }
    final normalized = _keyword.toLowerCase();
    return _admins
        .where((AdminManagerUser item) {
          return item.realName.toLowerCase().contains(normalized) ||
              item.username.toLowerCase().contains(normalized) ||
              (item.email ?? '').toLowerCase().contains(normalized) ||
              (item.phone ?? '').toLowerCase().contains(normalized) ||
              (item.college ?? '').toLowerCase().contains(normalized);
        })
        .toList(growable: false);
  }

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.wait<void>(<Future<void>>[_loadAdmins(), _loadLabs()]);

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

  Future<bool> saveAdmin({
    int? id,
    String? username,
    String? password,
    required String realName,
    required String email,
    required String phone,
    required int labId,
  }) async {
    _saving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (id == null) {
        await _repository.addAdmin(
          username: username ?? '',
          password: password ?? '',
          realName: realName,
          email: email,
          phone: phone,
          labId: labId,
        );
      } else {
        await _repository.updateAdmin(
          id: id,
          password: (password ?? '').trim().isEmpty ? null : password!.trim(),
          realName: realName,
          email: email,
          phone: phone,
          labId: labId,
        );
      }
      await _loadAdmins();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '管理员账号保存失败，请稍后重试';
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAdmin(int id) async {
    _deleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteAdmin(id);
      await _loadAdmins();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '管理员账号删除失败，请稍后重试';
      return false;
    } finally {
      _deleting = false;
      notifyListeners();
    }
  }

  Future<void> _loadAdmins() async {
    try {
      _admins = await _repository.fetchAdminAccounts();
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '管理员账号加载失败，请稍后重试';
    }
  }

  Future<void> _loadLabs() async {
    try {
      final page = await _labRepository.fetchLabs(pageSize: 100);
      _labs = page.records;
    } on ApiException catch (error) {
      _errorMessage ??= error.message;
    } catch (_) {
      _errorMessage ??= '实验室列表加载失败，请稍后重试';
    }
  }
}
