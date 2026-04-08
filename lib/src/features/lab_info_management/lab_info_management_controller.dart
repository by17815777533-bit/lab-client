import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/lab_summary.dart';
import '../../repositories/lab_repository.dart';

class LabInfoManagementController extends ChangeNotifier {
  LabInfoManagementController({
    required LabRepository repository,
    required int labId,
  }) : _repository = repository,
       _labId = labId;

  final LabRepository _repository;
  final int _labId;

  bool _loading = false;
  bool _saving = false;
  String? _errorMessage;
  LabSummary? _lab;

  bool get loading => _loading;
  bool get saving => _saving;
  String? get errorMessage => _errorMessage;
  LabSummary? get lab => _lab;
  int get labId => _labId;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _lab = await _repository.fetchLabDetail(_labId);
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '实验室信息加载失败，请稍后重试';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  Future<bool> saveLabInfo({
    required String labName,
    String? labCode,
    int? collegeId,
    String? labDesc,
    String? teacherName,
    String? location,
    String? contactEmail,
    String? requireSkill,
    required int recruitNum,
    required int currentNum,
    required int status,
    String? foundingDate,
    String? awards,
    String? basicInfo,
    String? advisors,
    String? currentAdmins,
  }) async {
    _saving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateManagedLabInfo(
        id: _labId,
        labName: labName,
        labCode: labCode,
        collegeId: collegeId,
        labDesc: labDesc,
        teacherName: teacherName,
        location: location,
        contactEmail: contactEmail,
        requireSkill: requireSkill,
        recruitNum: recruitNum,
        currentNum: currentNum,
        status: status,
        foundingDate: foundingDate,
        awards: awards,
        basicInfo: basicInfo,
        advisors: advisors,
        currentAdmins: currentAdmins,
      );
      await load();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '实验室信息保存失败，请稍后重试';
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
