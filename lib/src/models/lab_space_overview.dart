import 'attendance_summary.dart';
import 'lab_member_summary.dart';
import 'lab_summary.dart';
import 'space_file_item.dart';

class LabSpaceOverview {
  LabSpaceOverview({
    required this.lab,
    required this.memberCount,
    required this.members,
    required this.attendanceSummary,
    required this.recentFiles,
  });

  final LabSummary lab;
  final int memberCount;
  final List<LabMemberSummary> members;
  final AttendanceSummary? attendanceSummary;
  final List<SpaceFileItem> recentFiles;

  factory LabSpaceOverview.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'] as List<dynamic>? ?? const <dynamic>[];
    final rawFiles = json['recentFiles'] as List<dynamic>? ?? const <dynamic>[];

    return LabSpaceOverview(
      lab: LabSummary.fromJson(json['lab'] as Map<String, dynamic>),
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      members: rawMembers
          .whereType<Map>()
          .map(
            (item) => LabMemberSummary.fromJson(item.cast<String, dynamic>()),
          )
          .toList(),
      attendanceSummary: json['attendanceSummary'] is Map<String, dynamic>
          ? AttendanceSummary.fromJson(
              json['attendanceSummary'] as Map<String, dynamic>,
            )
          : json['attendanceSummary'] is Map
          ? AttendanceSummary.fromJson(
              (json['attendanceSummary'] as Map).cast<String, dynamic>(),
            )
          : null,
      recentFiles: rawFiles
          .whereType<Map>()
          .map((item) => SpaceFileItem.fromJson(item.cast<String, dynamic>()))
          .toList(),
    );
  }
}
