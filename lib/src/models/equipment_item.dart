import '../core/utils/date_time_formatter.dart';

class EquipmentItem {
  EquipmentItem({
    required this.id,
    required this.labId,
    required this.name,
    required this.type,
    required this.serialNumber,
    required this.imageUrl,
    required this.description,
    required this.status,
    required this.createTime,
    required this.updateTime,
  });

  final int id;
  final int? labId;
  final String name;
  final String? type;
  final String? serialNumber;
  final String? imageUrl;
  final String? description;
  final int status;
  final DateTime? createTime;
  final DateTime? updateTime;

  bool get isIdle => status == 0;
  bool get isBorrowed => status == 1;
  bool get isMaintaining => status == 2;

  String get statusLabel {
    switch (status) {
      case 1:
        return '借用中';
      case 2:
        return '维修中';
      default:
        return '空闲';
    }
  }

  factory EquipmentItem.fromJson(Map<String, dynamic> json) {
    return EquipmentItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      labId: (json['labId'] as num?)?.toInt(),
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString(),
      serialNumber: json['serialNumber']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      description: json['description']?.toString(),
      status: (json['status'] as num?)?.toInt() ?? 0,
      createTime: DateTimeFormatter.tryParse(json['createTime']),
      updateTime: DateTimeFormatter.tryParse(json['updateTime']),
    );
  }
}
