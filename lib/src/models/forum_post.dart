import '../core/utils/date_time_formatter.dart';

class ForumPost {
  ForumPost({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.isPinned,
    required this.isEssence,
    required this.likeCount,
    required this.commentCount,
    required this.viewCount,
    required this.authorName,
    required this.authorAvatar,
    required this.isLiked,
    required this.createTime,
    required this.updateTime,
  });

  final int id;
  final int? userId;
  final String title;
  final String content;
  final bool isPinned;
  final bool isEssence;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final String? authorName;
  final String? authorAvatar;
  final bool isLiked;
  final DateTime? createTime;
  final DateTime? updateTime;

  String get initials {
    final value = (authorName ?? '').trim();
    return value.isEmpty ? '匿' : value.substring(0, 1);
  }

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    final author = json['author'];
    final authorMap = author is Map ? author.cast<String, dynamic>() : null;

    return ForumPost(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt(),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      isPinned: json['isPinned'] == true,
      isEssence: json['isEssence'] == true,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      authorName: authorMap?['realName']?.toString(),
      authorAvatar: authorMap?['avatar']?.toString(),
      isLiked: json['isLiked'] == true,
      createTime: DateTimeFormatter.tryParse(json['createTime']),
      updateTime: DateTimeFormatter.tryParse(json['updateTime']),
    );
  }
}
