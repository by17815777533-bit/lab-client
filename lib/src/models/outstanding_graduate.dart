import '../core/utils/date_time_formatter.dart';

class OutstandingGraduate {
  OutstandingGraduate({
    required this.id,
    required this.labId,
    required this.name,
    required this.major,
    required this.graduationYear,
    required this.description,
    required this.avatarUrl,
    required this.company,
    required this.position,
    required this.createTime,
    required this.updateTime,
  });

  final int id;
  final int? labId;
  final String name;
  final String? major;
  final String? graduationYear;
  final String? description;
  final String? avatarUrl;
  final String? company;
  final String? position;
  final DateTime? createTime;
  final DateTime? updateTime;

  String get initials =>
      name.trim().isEmpty ? '优' : name.trim().substring(0, 1);
  String get destinationLabel {
    final companyText = (company ?? '').trim();
    final positionText = (position ?? '').trim();
    if (companyText.isEmpty && positionText.isEmpty) {
      return '暂未填写去向';
    }
    if (companyText.isEmpty) {
      return positionText;
    }
    if (positionText.isEmpty) {
      return companyText;
    }
    return '$companyText · $positionText';
  }

  factory OutstandingGraduate.fromJson(Map<String, dynamic> json) {
    return OutstandingGraduate(
      id: (json['id'] as num?)?.toInt() ?? 0,
      labId: (json['labId'] as num?)?.toInt(),
      name: json['name']?.toString() ?? '',
      major: json['major']?.toString(),
      graduationYear: json['graduationYear']?.toString(),
      description: json['description']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      company: json['company']?.toString(),
      position: json['position']?.toString(),
      createTime: DateTimeFormatter.tryParse(json['createTime']),
      updateTime: DateTimeFormatter.tryParse(json['updateTime']),
    );
  }
}
