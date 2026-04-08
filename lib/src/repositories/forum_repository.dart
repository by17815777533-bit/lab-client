import '../core/network/api_client.dart';
import '../models/forum_comment.dart';
import '../models/forum_post.dart';
import '../models/paged_result.dart';

class ForumRepository {
  ForumRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PagedResult<ForumPost>> fetchPosts({
    int pageNum = 1,
    int pageSize = 10,
    String? keyword,
    bool? isEssence,
  }) async {
    final response = await _apiClient.get(
      '/api/forum/post/list',
      queryParameters: <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize,
        'keyword': keyword,
        'isEssence': isEssence,
      },
    );

    return PagedResult<ForumPost>.fromJson(
      response as Map<String, dynamic>,
      ForumPost.fromJson,
    );
  }

  Future<ForumPost> fetchPostDetail(int id) async {
    final response = await _apiClient.get('/api/forum/post/$id');
    return ForumPost.fromJson(response as Map<String, dynamic>);
  }

  Future<PagedResult<ForumComment>> fetchComments({
    required int postId,
    int pageNum = 1,
    int pageSize = 10,
  }) async {
    final response = await _apiClient.get(
      '/api/forum/comment/list',
      queryParameters: <String, dynamic>{
        'postId': postId,
        'pageNum': pageNum,
        'pageSize': pageSize,
      },
    );

    return PagedResult<ForumComment>.fromJson(
      response as Map<String, dynamic>,
      ForumComment.fromJson,
    );
  }

  Future<void> createPost({required String title, required String content}) {
    return _apiClient.post(
      '/api/forum/post/add',
      data: <String, dynamic>{'title': title, 'content': content},
    );
  }

  Future<void> deletePost(int id) {
    return _apiClient.delete('/api/forum/post/$id');
  }

  Future<void> setPinned(int id, bool value) {
    return _apiClient.put(
      '/api/forum/post/$id/pin',
      queryParameters: <String, dynamic>{'isPinned': value},
    );
  }

  Future<void> setEssence(int id, bool value) {
    return _apiClient.put(
      '/api/forum/post/$id/essence',
      queryParameters: <String, dynamic>{'isEssence': value},
    );
  }

  Future<void> toggleLike(int id) {
    return _apiClient.post('/api/forum/post/$id/like');
  }

  Future<void> createComment({required int postId, required String content}) {
    return _apiClient.post(
      '/api/forum/comment/add',
      data: <String, dynamic>{'postId': postId, 'content': content},
    );
  }

  Future<void> deleteComment(int id) {
    return _apiClient.delete('/api/forum/comment/$id');
  }
}
