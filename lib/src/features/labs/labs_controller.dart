import 'package:flutter/foundation.dart';

import '../../models/lab_summary.dart';
import '../../models/outstanding_graduate.dart';
import '../../models/recruit_plan.dart';
import '../../repositories/application_repository.dart';
import '../../repositories/graduate_repository.dart';
import '../../repositories/lab_repository.dart';
import '../../repositories/plan_repository.dart';

class LabsController extends ChangeNotifier {
  LabsController({
    required LabRepository labRepository,
    required PlanRepository planRepository,
    required ApplicationRepository applicationRepository,
    required GraduateRepository graduateRepository,
  }) : _labRepository = labRepository,
       _planRepository = planRepository,
       _applicationRepository = applicationRepository,
       _graduateRepository = graduateRepository;

  final LabRepository _labRepository;
  final PlanRepository _planRepository;
  final ApplicationRepository _applicationRepository;
  final GraduateRepository _graduateRepository;

  bool _loading = false;
  List<LabSummary> _labs = <LabSummary>[];
  List<RecruitPlan> _activePlans = <RecruitPlan>[];

  bool get loading => _loading;
  List<LabSummary> get labs => _labs;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _labRepository.fetchLabs(pageNum: 1, pageSize: 100, status: 1),
        _planRepository.fetchActivePlans(),
      ]);

      _labs = (results[0] as dynamic).records as List<LabSummary>;
      _activePlans = results[1] as List<RecruitPlan>;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  List<RecruitPlan> plansForLab(int labId) {
    return _activePlans.where((item) => item.labId == labId).toList();
  }

  Future<LabSummary> loadLabDetail(int labId) {
    return _labRepository.fetchLabDetail(labId);
  }

  Future<List<OutstandingGraduate>> loadLabGraduates(int labId) async {
    final page = await _graduateRepository.fetchGraduates(
      pageNum: 1,
      pageSize: 12,
      labId: labId,
    );
    return page.records;
  }

  Future<void> submitApplication({
    required int labId,
    required int recruitPlanId,
    required String applyReason,
    String? researchInterest,
    String? skillSummary,
  }) {
    return _applicationRepository.createApplication(
      labId: labId,
      recruitPlanId: recruitPlanId,
      applyReason: applyReason,
      researchInterest: researchInterest,
      skillSummary: skillSummary,
    );
  }
}
