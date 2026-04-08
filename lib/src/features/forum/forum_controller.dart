import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/forum_post.dart';
import '../../models/paged_result.dart';
import '../../repositories/forum_repository.dart';

class ForumController extends ChangeNotifier {
  ForumController(this._repository);

  final ForumRepository _repository;

  bool _loading = false;
  bool _submitting = false;
  String? _errorMessage;
  PagedResult<ForumPost>? _page;
  int _pageNum = 1;
  final int _pageSize = 10;
  bool _essenceOnly = false;
  String _keyword = '';

  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get errorMessage => _errorMessage;
  List<ForumPost> get posts => _page?.records ?? <ForumPost>[];
  int get pageNum => _pageNum;
  int get totalPages => _page?.pages ?? 0;
  int get total => _page?.total ?? 0;
  bool get essenceOnly => _essenceOnly;
  String get keyword => _keyword;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _page = await _repository.fetchPosts(
        pageNum: _pageNum,
        pageSize: _pageSize,
        keyword: _keyword.trim().isEmpty ? null : _keyword.trim(),
        isEssence: _essenceOnly ? true : null,
      );
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _page = null;
    } catch (_) {
      _errorMessage = '论坛内容加载失败，请稍后重试';
      _page = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  void setKeyword(String value) {
    _keyword = value;
  }

  Future<void> search() async {
    _pageNum = 1;
    await load();
  }

  Future<void> updateEssenceOnly(bool value) async {
    if (value == _essenceOnly) {
      return;
    }
    _essenceOnly = value;
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
    if (_page == null || _pageNum >= _page!.pages) {
      return;
    }
    _pageNum += 1;
    await load();
  }

  Future<bool> createPost({
    required String title,
    required String content,
  }) async {
    _submitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.createPost(title: title, content: content);
      _pageNum = 1;
      await load();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '发帖失败，请稍后重试';
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
