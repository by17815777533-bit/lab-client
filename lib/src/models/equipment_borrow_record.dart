import '../core/utils/date_time_formatter.dart';

class EquipmentBorrowRecord {
  EquipmentBorrowRecord({
    required this.id,
    required this.equipmentId,
    required this.userId,
    required this.borrowTime,
    required this.returnTime,
    required this.expectedReturnTime,
    required this.pickupTime,
    required this.pickupConfirmedBy,
    required this.returnApplyTime,
    required this.returnConfirmedBy,
    required this.returnConfirmTime,
    required this.acceptanceChecklist,
    required this.reason,
    required this.status,
    required this.createTime,
    required this.updateTime,
  });

  final int id;
  final int? equipmentId;
  final int? userId;
  final DateTime? borrowTime;
  final DateTime? returnTime;
  final DateTime? expectedReturnTime;
  final DateTime? pickupTime;
  final int? pickupConfirmedBy;
  final DateTime? returnApplyTime;
  final int? returnConfirmedBy;
  final DateTime? returnConfirmTime;
  final String? acceptanceChecklist;
  final String? reason;
  final int status;
  final DateTime? createTime;
  final DateTime? updateTime;

  bool get isPending => status == 0;
  bool get isBorrowed => status == 1;
  bool get isRejected => status == 2;
  bool get isReturned => status == 3;
  bool get isPickedUp => status == 4;
  bool get isWaitingReturnCheck => status == 5;
  bool get isOverdue => status == 6;

  String get statusLabel {
    switch (status) {
      case 1:
        return '已借出';
      case 2:
        return '已拒绝';
      case 3:
        return '已归还';
      case 4:
        return '已领用';
      case 5:
        return '待验收';
      case 6:
        return '已逾期';
      default:
        return '申请中';
    }
  }

  factory EquipmentBorrowRecord.fromJson(Map<String, dynamic> json) {
    return EquipmentBorrowRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      equipmentId: (json['equipmentId'] as num?)?.toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      borrowTime: DateTimeFormatter.tryParse(json['borrowTime']),
      returnTime: DateTimeFormatter.tryParse(json['returnTime']),
      expectedReturnTime: DateTimeFormatter.tryParse(
        json['expectedReturnTime'],
      ),
      pickupTime: DateTimeFormatter.tryParse(json['pickupTime']),
      pickupConfirmedBy: (json['pickupConfirmedBy'] as num?)?.toInt(),
      returnApplyTime: DateTimeFormatter.tryParse(json['returnApplyTime']),
      returnConfirmedBy: (json['returnConfirmedBy'] as num?)?.toInt(),
      returnConfirmTime: DateTimeFormatter.tryParse(json['returnConfirmTime']),
      acceptanceChecklist: json['acceptanceChecklist']?.toString(),
      reason: json['reason']?.toString(),
      status: (json['status'] as num?)?.toInt() ?? 0,
      createTime: DateTimeFormatter.tryParse(json['createTime']),
      updateTime: DateTimeFormatter.tryParse(json['updateTime']),
    );
  }
}
