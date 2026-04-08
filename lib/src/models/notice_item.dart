import '../core/utils/date_time_formatter.dart';

class NoticeItem {
  NoticeItem({
    required this.id,
    required this.title,
    required this.content,
    required this.publishScope,
    required this.collegeName,
    required this.labName,
    required this.publisherName,
    required this.publishTime,
  });

  final int id;
  final String title;
  final String content;
  final String? publishScope;
  final String? collegeName;
  final String? labName;
  final String? publisherName;
  final DateTime? publishTime;

  String get scopeLabel {
    switch (publishScope) {
      case 'school':
        return '学校';
      case 'college':
        return '学院';
      case 'lab':
        return '实验室';
      default:
        return publishScope ?? '公告';
    }
  }

  factory NoticeItem.fromJson(Map<String, dynamic> json) {
    return NoticeItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      publishScope: json['publishScope']?.toString(),
      collegeName: json['collegeName']?.toString(),
      labName: json['labName']?.toString(),
      publisherName: json['publisherName']?.toString(),
      publishTime: DateTimeFormatter.tryParse(json['publishTime']),
    );
  }
}
