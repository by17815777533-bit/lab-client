import '../core/utils/date_time_formatter.dart';

class WrittenExamNotification {
  WrittenExamNotification({
    required this.id,
    required this.title,
    required this.content,
    required this.read,
    required this.createTime,
  });

  final int id;
  final String title;
  final String content;
  final bool read;
  final DateTime? createTime;

  factory WrittenExamNotification.fromJson(Map<String, dynamic> json) {
    return WrittenExamNotification(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '笔试通知',
      content: json['content']?.toString() ?? '',
      read: json['isRead'] == true || json['readStatus'] == 1,
      createTime: DateTimeFormatter.tryParse(
        json['createTime'] ?? json['publishTime'],
      ),
    );
  }
}
