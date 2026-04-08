import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/delivery_record.dart';
import '../../models/paged_result.dart';
import '../../models/user_profile.dart';
import '../../repositories/delivery_repository.dart';

class DeliveryManagementController extends ChangeNotifier {
  DeliveryManagementController({
    required DeliveryRepository repository,
    required UserProfile profile,
    String? initialRealName,
    String? initialStudentId,
    int? initialAuditStatus,
  }) : _repository = repository,
       _profile = profile,
       _realName = (initialRealName ?? '').trim(),
       _studentId = (initialStudentId ?? '').trim(),
       _auditStatus = initialAuditStatus;

  final DeliveryRepository _repository;
  final UserProfile _profile;

  bool _loading = false;
  bool _submitting = false;
  String? _errorMessage;
  PagedResult<DeliveryRecord>? _page;

  int _pageNum = 1;
  final int _pageSize = 10;
  String _realName;
  String _studentId;
  int? _auditStatus;

  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get errorMessage => _errorMessage;
  UserProfile get profile => _profile;
  List<DeliveryRecord> get deliveries => _page?.records ?? <DeliveryRecord>[];
  int get pageNum => _pageNum;
  int get totalPages => _page?.pages ?? 0;
  int get total => _page?.total ?? 0;
  String get realName => _realName;
  String get studentId => _studentId;
  int? get auditStatus => _auditStatus;
  bool get canAudit => _profile.labManager;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _page = await _repository.fetchDeliveries(
        pageNum: _pageNum,
        pageSize: _pageSize,
        realName: _realName.isEmpty ? null : _realName,
        studentId: _studentId.isEmpty ? null : _studentId,
        auditStatus: _auditStatus,
      );
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '投递记录加载失败，请稍后重试';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  void updateFilters({String? realName, String? studentId, int? auditStatus}) {
    _realName = (realName ?? _realName).trim();
    _studentId = (studentId ?? _studentId).trim();
    _auditStatus = auditStatus;
    _pageNum = 1;
    notifyListeners();
  }

  void clearFilters() {
    _realName = '';
    _studentId = '';
    _auditStatus = null;
    _pageNum = 1;
    notifyListeners();
  }

  Future<void> search() => load();

  Future<void> previousPage() async {
    if (_pageNum <= 1) {
      return;
    }
    _pageNum -= 1;
    await load();
  }

  Future<void> nextPage() async {
    if (_page != null && _pageNum >= _page!.pages) {
      return;
    }
    _pageNum += 1;
    await load();
  }

  Future<bool> reviewDelivery({
    required DeliveryRecord record,
    required bool approve,
    required String remark,
  }) async {
    _submitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (approve) {
        await _repository.auditDelivery(
          id: record.id,
          auditStatus: 1,
          auditRemark: remark,
        );
        await _repository.admitDelivery(record.id);
      } else {
        await _repository.auditDelivery(
          id: record.id,
          auditStatus: 2,
          auditRemark: remark,
        );
      }
      await load();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      await load();
      return false;
    } catch (_) {
      _errorMessage = '投递处理失败，请稍后重试';
      await load();
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
