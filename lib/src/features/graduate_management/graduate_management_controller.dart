import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/outstanding_graduate.dart';
import '../../models/paged_result.dart';
import '../../models/user_profile.dart';
import '../../repositories/graduate_repository.dart';

class GraduateManagementController extends ChangeNotifier {
  GraduateManagementController({
    required GraduateRepository repository,
    required UserProfile profile,
  }) : _repository = repository,
       _profile = profile;

  final GraduateRepository _repository;
  final UserProfile _profile;

  bool _loading = false;
  bool _saving = false;
  bool _deleting = false;
  String? _errorMessage;
  PagedResult<OutstandingGraduate>? _page;
  int _pageNum = 1;
  final int _pageSize = 10;

  bool get loading => _loading;
  bool get saving => _saving;
  bool get deleting => _deleting;
  String? get errorMessage => _errorMessage;
  UserProfile get profile => _profile;
  List<OutstandingGraduate> get graduates =>
      _page?.records ?? <OutstandingGraduate>[];
  int get pageNum => _pageNum;
  int get totalPages => _page?.pages ?? 0;
  int get total => _page?.total ?? 0;
  bool get canManage => _profile.labManager;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _page = await _repository.fetchGraduates(
        pageNum: _pageNum,
        pageSize: _pageSize,
        labId: _profile.labId,
      );
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '优秀毕业生加载失败，请稍后重试';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

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

  Future<bool> saveGraduate({
    int? id,
    required String name,
    required String major,
    required String graduationYear,
    String? company,
    String? position,
    String? description,
    String? avatarUrl,
  }) async {
    _saving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (id == null) {
        await _repository.addGraduate(
          name: name,
          major: major,
          graduationYear: graduationYear,
          company: company,
          position: position,
          description: description,
          avatarUrl: avatarUrl,
        );
      } else {
        await _repository.updateGraduate(
          id: id,
          labId: _profile.labId,
          name: name,
          major: major,
          graduationYear: graduationYear,
          company: company,
          position: position,
          description: description,
          avatarUrl: avatarUrl,
        );
      }
      await load();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '优秀毕业生保存失败，请稍后重试';
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteGraduate(int id) async {
    _deleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteGraduate(id);
      final targetPage = graduates.length <= 1 && _pageNum > 1
          ? _pageNum - 1
          : _pageNum;
      _pageNum = targetPage;
      await load();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '优秀毕业生删除失败，请稍后重试';
      return false;
    } finally {
      _deleting = false;
      notifyListeners();
    }
  }
}
