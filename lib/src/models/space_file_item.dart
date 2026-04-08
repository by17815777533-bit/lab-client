import '../core/utils/date_time_formatter.dart';

class SpaceFileItem {
  SpaceFileItem({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.folderName,
    required this.uploadUserName,
    required this.fileSize,
    required this.archiveFlag,
    required this.createTime,
  });

  final int id;
  final String fileName;
  final String? fileUrl;
  final String? folderName;
  final String? uploadUserName;
  final int fileSize;
  final int archiveFlag;
  final DateTime? createTime;

  bool get isArchived => archiveFlag == 1;

  factory SpaceFileItem.fromJson(Map<String, dynamic> json) {
    return SpaceFileItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fileName: json['fileName']?.toString() ?? '',
      fileUrl: json['fileUrl']?.toString(),
      folderName: json['folderName']?.toString(),
      uploadUserName: json['uploadUserName']?.toString(),
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      archiveFlag: (json['archiveFlag'] as num?)?.toInt() ?? 0,
      createTime: DateTimeFormatter.tryParse(json['createTime']),
    );
  }
}
