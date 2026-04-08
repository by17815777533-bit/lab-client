import '../core/utils/date_time_formatter.dart';

class ForumComment {
  ForumComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.authorName,
    required this.authorAvatar,
    required this.createTime,
  });

  final int id;
  final int? postId;
  final int? userId;
  final String content;
  final String? authorName;
  final String? authorAvatar;
  final DateTime? createTime;

  String get initials {
    final value = (authorName ?? '').trim();
    return value.isEmpty ? '匿' : value.substring(0, 1);
  }

  factory ForumComment.fromJson(Map<String, dynamic> json) {
    final author = json['author'];
    final authorMap = author is Map ? author.cast<String, dynamic>() : null;

    return ForumComment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      postId: (json['postId'] as num?)?.toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      content: json['content']?.toString() ?? '',
      authorName: authorMap?['realName']?.toString(),
      authorAvatar: authorMap?['avatar']?.toString(),
      createTime: DateTimeFormatter.tryParse(json['createTime']),
    );
  }
}
