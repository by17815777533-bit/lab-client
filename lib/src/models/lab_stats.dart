class LabStats {
  LabStats({required this.total, required this.byCollege});

  final int total;
  final List<CollegeLabStat> byCollege;

  factory LabStats.fromJson(Map<String, dynamic> json) {
    final rawItems = json['byCollege'] as List<dynamic>? ?? const <dynamic>[];
    return LabStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      byCollege: rawItems
          .whereType<Map>()
          .map((item) => CollegeLabStat.fromJson(item.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class CollegeLabStat {
  CollegeLabStat({
    required this.collegeId,
    required this.collegeName,
    required this.labCount,
  });

  final int? collegeId;
  final String? collegeName;
  final int labCount;

  factory CollegeLabStat.fromJson(Map<String, dynamic> json) {
    return CollegeLabStat(
      collegeId: (json['collegeId'] as num?)?.toInt(),
      collegeName: json['collegeName']?.toString(),
      labCount: (json['labCount'] as num?)?.toInt() ?? 0,
    );
  }
}
