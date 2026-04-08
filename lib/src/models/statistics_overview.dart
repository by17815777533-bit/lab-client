import '../core/utils/date_time_formatter.dart';

class StatisticsMetric {
  StatisticsMetric({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;
}

class StatisticsSeriesItem {
  StatisticsSeriesItem({required this.name, required this.value});

  final String name;
  final double value;

  factory StatisticsSeriesItem.fromJson(Map<String, dynamic> json) {
    return StatisticsSeriesItem(
      name: json['name']?.toString() ?? '',
      value: _asDouble(json['value']),
    );
  }
}

class StatisticsRecentApply {
  StatisticsRecentApply({
    required this.id,
    required this.studentName,
    required this.studentId,
    required this.labName,
    required this.status,
    required this.createTime,
  });

  final int id;
  final String studentName;
  final String studentId;
  final String? labName;
  final String status;
  final DateTime? createTime;

  factory StatisticsRecentApply.fromJson(Map<String, dynamic> json) {
    return StatisticsRecentApply(
      id: _asInt(json['id']),
      studentName: json['studentName']?.toString() ?? '-',
      studentId: json['studentId']?.toString() ?? '-',
      labName: json['labName']?.toString(),
      status: json['status']?.toString() ?? '',
      createTime: DateTimeFormatter.tryParse(json['createTime']),
    );
  }
}

class StatisticsPendingItem {
  StatisticsPendingItem({
    required this.label,
    required this.value,
    required this.description,
    required this.route,
  });

  final String label;
  final double value;
  final String description;
  final String? route;

  factory StatisticsPendingItem.fromJson(Map<String, dynamic> json) {
    return StatisticsPendingItem(
      label: json['label']?.toString() ?? json['name']?.toString() ?? '-',
      value: _asDouble(json['value']),
      description: json['description']?.toString() ?? '',
      route: json['route']?.toString(),
    );
  }
}

class StatisticsOverview {
  StatisticsOverview({
    required this.raw,
    required this.scopeType,
    required this.scopeName,
    required this.heroMetrics,
    required this.applyStatus,
    required this.collegeDistribution,
    required this.hotLabs,
    required this.memberTypeDistribution,
    required this.monthlyApplyTrend,
    required this.monthlyAttendanceTrend,
    required this.teacherGuidanceRanking,
    required this.recentApplies,
    required this.recruitConversionRanking,
    required this.activityRanking,
    required this.collegeComparison,
    required this.pendingApprovals,
    required this.pendingApprovalTotal,
    required this.attendanceRate,
  });

  final Map<String, dynamic> raw;
  final String scopeType;
  final String scopeName;
  final List<StatisticsMetric> heroMetrics;
  final List<StatisticsSeriesItem> applyStatus;
  final List<StatisticsSeriesItem> collegeDistribution;
  final List<StatisticsSeriesItem> hotLabs;
  final List<StatisticsSeriesItem> memberTypeDistribution;
  final List<StatisticsSeriesItem> monthlyApplyTrend;
  final List<StatisticsSeriesItem> monthlyAttendanceTrend;
  final List<StatisticsSeriesItem> teacherGuidanceRanking;
  final List<StatisticsRecentApply> recentApplies;
  final List<StatisticsSeriesItem> recruitConversionRanking;
  final List<StatisticsSeriesItem> activityRanking;
  final List<StatisticsSeriesItem> collegeComparison;
  final List<StatisticsPendingItem> pendingApprovals;
  final double pendingApprovalTotal;
  final double attendanceRate;

  bool get isSchool => scopeType == 'school';
  bool get isCollege => scopeType == 'college';
  bool get isLab => scopeType == 'lab';

  factory StatisticsOverview.fromJson(Map<String, dynamic> json) {
    final scopeType = json['scopeType']?.toString() ?? 'lab';
    final scopeName = json['scopeName']?.toString() ?? '统计工作台';
    final attendanceRate = _asDouble(json['attendanceRate']);
    final pendingApprovalTotal = _asDouble(json['pendingApprovalTotal']);

    return StatisticsOverview(
      raw: json,
      scopeType: scopeType,
      scopeName: scopeName,
      heroMetrics: _buildMetrics(json, scopeType, attendanceRate),
      applyStatus: _seriesList(json['applyStatus']),
      collegeDistribution: _seriesList(json['collegeDistribution']),
      hotLabs: _seriesList(json['hotLabs']),
      memberTypeDistribution: _seriesList(
        json['memberTypeDistribution'] ?? json['memberRoles'],
      ),
      monthlyApplyTrend: _seriesList(json['monthlyApplyTrend']),
      monthlyAttendanceTrend: _seriesList(json['monthlyAttendanceTrend']),
      teacherGuidanceRanking: _seriesList(json['teacherGuidanceRanking']),
      recentApplies: _recentApplyList(json['recentApplies']),
      recruitConversionRanking: _seriesList(json['recruitConversionRanking']),
      activityRanking: _seriesList(json['activityRanking']),
      collegeComparison: _seriesList(json['collegeComparison']),
      pendingApprovals: _pendingList(json['pendingApprovals']),
      pendingApprovalTotal: pendingApprovalTotal,
      attendanceRate: attendanceRate,
    );
  }

  static List<StatisticsMetric> _buildMetrics(
    Map<String, dynamic> json,
    String scopeType,
    double attendanceRate,
  ) {
    if (scopeType == 'school') {
      return <StatisticsMetric>[
        _metric('实验室总数', _value(json['labCount']), '全校纳入管理的实验室'),
        _metric('正式成员', _value(json['formalMemberCount']), '实验室在组成员总量'),
        _metric('月出勤率', '${attendanceRate.toStringAsFixed(0)}%', '全校出勤综合表现'),
        _metric('资料文件', _value(json['fileCount']), '实验室空间累计文件数'),
        _metric('待办事项', _value(json['pendingApprovalTotal']), '学校层面的审批待办总数'),
      ];
    }

    if (scopeType == 'college') {
      return <StatisticsMetric>[
        _metric('实验室总数', _value(json['labCount']), '本学院纳入治理的实验室'),
        _metric('正式成员', _value(json['formalMemberCount']), '本学院实验室在组成员总量'),
        _metric('月出勤率', '${attendanceRate.toStringAsFixed(0)}%', '本学院出勤综合表现'),
        _metric('资料文件', _value(json['fileCount']), '本学院资料空间累计文件数'),
        _metric('待办事项', _value(json['pendingApprovalTotal']), '本学院当前待处理事项'),
      ];
    }

    return <StatisticsMetric>[
      _metric('成员规模', _value(json['memberCount']), '当前实验室有效成员数'),
      _metric('申请总量', _value(json['applyCount']), '收到的全部申请'),
      _metric('待办事项', _value(json['pendingApprovalTotal']), '当前实验室待处理事项'),
      _metric('月出勤率', '${attendanceRate.toStringAsFixed(0)}%', '当前实验室出勤表现'),
      _metric('资料文件', _value(json['fileCount']), '实验室空间文件数'),
    ];
  }

  static StatisticsMetric _metric(String label, String value, String hint) {
    return StatisticsMetric(label: label, value: value, hint: hint);
  }

  static List<StatisticsSeriesItem> _seriesList(dynamic value) {
    return _mapList(
      value,
    ).map(StatisticsSeriesItem.fromJson).toList(growable: false);
  }

  static List<StatisticsRecentApply> _recentApplyList(dynamic value) {
    return _mapList(
      value,
    ).map(StatisticsRecentApply.fromJson).toList(growable: false);
  }

  static List<StatisticsPendingItem> _pendingList(dynamic value) {
    return _mapList(
      value,
    ).map(StatisticsPendingItem.fromJson).toList(growable: false);
  }
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }
  final raw = value;
  return raw
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList(growable: false);
}

String _value(dynamic value) {
  if (value == null) {
    return '0';
  }
  if (value is num) {
    if (value is int) {
      return value.toString();
    }
    final fixed = value.toStringAsFixed(2);
    return fixed.endsWith('.00') ? fixed.substring(0, fixed.length - 3) : fixed;
  }
  return value.toString();
}

int _asInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
