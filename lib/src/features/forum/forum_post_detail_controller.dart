import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/forum_comment.dart';
import '../../models/forum_post.dart';
import '../../models/paged_result.dart';
import '../../repositories/forum_repository.dart';

class ForumPostDetailController extends ChangeNotifier {
  ForumPostDetailController({
    required ForumRepository repository,
    required this.postId,
  }) : _repository = repository;

  final ForumRepository _repository;
  final int postId;

  bool _loading = false;
  bool _mutating = false;
  String? _errorMessage;
  ForumPost? _post;
  PagedResult<ForumComment>? _page;
  int _pageNum = 1;
  final int _pageSize = 10;

  bool get loading => _loading;
  bool get mutating => _mutating;
  String? get errorMessage => _errorMessage;
  ForumPost? get post => _post;
  List<ForumComment> get comments => _page?.records ?? <ForumComment>[];
  int get pageNum => _pageNum;
  int get totalPages => _page?.pages ?? 0;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _post = await _repository.fetchPostDetail(postId);
      _page = await _repository.fetchComments(
        postId: postId,
        pageNum: _pageNum,
        pageSize: _pageSize,
      );
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _post = null;
      _page = null;
    } catch (_) {
      _errorMessage = '帖子详情加载失败，请稍后重试';
      _post = null;
      _page = null;
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
    if (_page == null || _pageNum >= _page!.pages) {
      return;
    }
    _pageNum += 1;
    await load();
  }

  Future<bool> toggleLike() async {
    _mutating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.toggleLike(postId);
      await load();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '点赞失败，请稍后重试';
      return false;
    } finally {
      _mutating = false;
      notifyListeners();
    }
  }

  Future<bool> createComment(String content) async {
    _mutating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.createComment(postId: postId, content: content);
      _pageNum = 1;
      await load();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '评论失败，请稍后重试';
      return false;
    } finally {
      _mutating = false;
      notifyListeners();
    }
  }

  Future<bool> deletePost() async {
    _mutating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deletePost(postId);
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '删除失败，请稍后重试';
      return false;
    } finally {
      _mutating = false;
      notifyListeners();
    }
  }

  Future<bool> togglePinned() async {
    final post = _post;
    if (post == null) {
      return false;
    }
    _mutating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.setPinned(postId, !post.isPinned);
      await load();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '操作失败，请稍后重试';
      return false;
    } finally {
      _mutating = false;
      notifyListeners();
    }
  }

  Future<bool> toggleEssence() async {
    final post = _post;
    if (post == null) {
      return false;
    }
    _mutating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.setEssence(postId, !post.isEssence);
      await load();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '操作失败，请稍后重试';
      return false;
    } finally {
      _mutating = false;
      notifyListeners();
    }
  }

  Future<bool> deleteComment(int id) async {
    _mutating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteComment(id);
      await load();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '删除评论失败，请稍后重试';
      return false;
    } finally {
      _mutating = false;
      notifyListeners();
    }
  }
}
