import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/lab_application.dart';
import '../../models/lab_stats.dart';
import '../../models/notice_item.dart';
import '../../models/recruit_plan.dart';
import '../../models/user_profile.dart';
import '../../repositories/application_repository.dart';
import '../../repositories/lab_repository.dart';
import '../../repositories/notice_repository.dart';
import '../../repositories/plan_repository.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({
    required UserProfile profile,
    required PlanRepository planRepository,
    required NoticeRepository noticeRepository,
    required ApplicationRepository applicationRepository,
    required LabRepository labRepository,
  }) : _profile = profile,
       _planRepository = planRepository,
       _noticeRepository = noticeRepository,
       _applicationRepository = applicationRepository,
       _labRepository = labRepository;

  final UserProfile _profile;
  final PlanRepository _planRepository;
  final NoticeRepository _noticeRepository;
  final ApplicationRepository _applicationRepository;
  final LabRepository _labRepository;

  bool _loading = false;
  String? _errorMessage;
  List<RecruitPlan> _activePlans = <RecruitPlan>[];
  List<NoticeItem> _latestNotices = <NoticeItem>[];
  List<LabApplication> _myApplications = <LabApplication>[];
  LabStats? _labStats;

  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  List<RecruitPlan> get activePlans => _activePlans;
  List<NoticeItem> get latestNotices => _latestNotices;
  List<LabApplication> get myApplications => _myApplications;
  LabStats? get labStats => _labStats;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final futures = <Future<dynamic>>[
        _planRepository.fetchActivePlans(),
        _noticeRepository.fetchLatest(limit: 6),
      ];

      if (_profile.isStudent) {
        futures.add(
          _applicationRepository.fetchMyApplications(pageNum: 1, pageSize: 5),
        );
      } else {
        futures.add(_labRepository.fetchLabStats());
      }

      final results = await Future.wait<dynamic>(futures);
      _activePlans = results[0] as List<RecruitPlan>;
      _latestNotices = results[1] as List<NoticeItem>;

      if (_profile.isStudent) {
        _myApplications =
            (results[2] as dynamic).records as List<LabApplication>;
        _labStats = null;
      } else {
        _labStats = results[2] as LabStats;
        _myApplications = <LabApplication>[];
      }
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
