import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/latest_lab_application.dart';
import '../../repositories/lab_apply_audit_repository.dart';
import '../../models/statistics_overview.dart';
import '../../repositories/statistics_repository.dart';

class StatisticsController extends ChangeNotifier {
  StatisticsController({
    required StatisticsRepository repository,
    required LabApplyAuditRepository labApplyAuditRepository,
    int? labId,
  }) : _repository = repository,
       _labApplyAuditRepository = labApplyAuditRepository,
       _labId = labId;

  final StatisticsRepository _repository;
  final LabApplyAuditRepository _labApplyAuditRepository;
  int? _labId;

  bool _loading = false;
  String? _errorMessage;
  StatisticsOverview? _overview;
  List<LatestLabApplication> _latestApplications = <LatestLabApplication>[];

  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  StatisticsOverview? get overview => _overview;
  int? get labId => _labId;
  List<LatestLabApplication> get latestApplications => _latestApplications;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _repository.fetchOverview(labId: _labId),
        _labApplyAuditRepository.fetchLatestApplications(
          limit: 6,
          labId: _labId,
        ),
      ]);
      _overview = results[0] as StatisticsOverview;
      _latestApplications = results[1] as List<LatestLabApplication>;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '统计数据加载失败，请稍后重试';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  void useLabScope(int? labId) {
    if (_labId == labId) {
      return;
    }
    _labId = labId;
    notifyListeners();
  }
}
