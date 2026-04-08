class AttendanceSummary {
  AttendanceSummary({
    required this.weeklyRate,
    required this.monthlyRate,
    required this.presentCount,
    required this.lateCount,
    required this.makeupCount,
    required this.absentCount,
  });

  final int weeklyRate;
  final int monthlyRate;
  final int presentCount;
  final int lateCount;
  final int makeupCount;
  final int absentCount;

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      weeklyRate: (json['weeklyRate'] as num?)?.toInt() ?? 0,
      monthlyRate: (json['monthlyRate'] as num?)?.toInt() ?? 0,
      presentCount: (json['presentCount'] as num?)?.toInt() ?? 0,
      lateCount: (json['lateCount'] as num?)?.toInt() ?? 0,
      makeupCount: (json['makeupCount'] as num?)?.toInt() ?? 0,
      absentCount: (json['absentCount'] as num?)?.toInt() ?? 0,
    );
  }
}
