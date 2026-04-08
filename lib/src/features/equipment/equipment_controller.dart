import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/equipment_borrow_record.dart';
import '../../models/equipment_item.dart';
import '../../models/paged_result.dart';
import '../../models/user_profile.dart';
import '../../repositories/equipment_repository.dart';

class EquipmentController extends ChangeNotifier {
  EquipmentController({
    required EquipmentRepository repository,
    required UserProfile profile,
  }) : _repository = repository,
       _profile = profile;

  final EquipmentRepository _repository;
  final UserProfile _profile;

  bool _loadingEquipment = false;
  bool _loadingBorrowRecords = false;
  bool _submittingBorrow = false;
  String? _equipmentErrorMessage;
  String? _borrowErrorMessage;
  int _equipmentPageNum = 1;
  final int _equipmentPageSize = 8;
  int _borrowPageNum = 1;
  final int _borrowPageSize = 8;
  int? _borrowStatusFilter;
  String _equipmentKeyword = '';
  PagedResult<EquipmentItem>? _equipmentPage;
  PagedResult<EquipmentBorrowRecord>? _borrowPage;
  final Map<int, EquipmentItem> _equipmentCache = <int, EquipmentItem>{};

  bool get loadingEquipment => _loadingEquipment;
  bool get loadingBorrowRecords => _loadingBorrowRecords;
  bool get submittingBorrow => _submittingBorrow;
  String? get equipmentErrorMessage => _equipmentErrorMessage;
  String? get borrowErrorMessage => _borrowErrorMessage;
  int get equipmentPageNum => _equipmentPageNum;
  int get equipmentPageSize => _equipmentPageSize;
  int get equipmentTotal => _equipmentPage?.total ?? 0;
  int get equipmentTotalPages => _equipmentPage?.pages ?? 0;
  int get borrowPageNum => _borrowPageNum;
  int get borrowPageSize => _borrowPageSize;
  int get borrowTotal => _borrowPage?.total ?? 0;
  int get borrowTotalPages => _borrowPage?.pages ?? 0;
  int? get borrowStatusFilter => _borrowStatusFilter;
  String get equipmentKeyword => _equipmentKeyword;
  List<EquipmentItem> get equipmentItems =>
      _equipmentPage?.records ?? <EquipmentItem>[];
  List<EquipmentBorrowRecord> get borrowRecords =>
      _borrowPage?.records ?? <EquipmentBorrowRecord>[];
  bool get canBorrow => _profile.labId != null && _profile.isStudent;
  int? get labId => _profile.labId;
  UserProfile get profile => _profile;

  Future<void> load() async {
    await Future.wait<void>(<Future<void>>[
      loadEquipment(),
      loadBorrowRecords(),
    ]);
  }

  Future<void> refresh() => load();

  Future<void> loadEquipment() async {
    if (_profile.labId == null) {
      _equipmentPage = PagedResult<EquipmentItem>(
        records: <EquipmentItem>[],
        total: 0,
        pageNum: 1,
        pageSize: _equipmentPageSize,
        pages: 0,
      );
      _equipmentErrorMessage = null;
      notifyListeners();
      return;
    }

    _loadingEquipment = true;
    _equipmentErrorMessage = null;
    notifyListeners();

    try {
      _equipmentPage = await _repository.fetchEquipmentList(
        pageNum: _equipmentPageNum,
        pageSize: _equipmentPageSize,
        labId: _profile.labId,
        name: _equipmentKeyword.isEmpty ? null : _equipmentKeyword,
      );
      for (final item in _equipmentPage!.records) {
        _equipmentCache[item.id] = item;
      }
    } on ApiException catch (error) {
      _equipmentErrorMessage = error.message;
    } catch (_) {
      _equipmentErrorMessage = '设备列表加载失败，请稍后重试';
    } finally {
      _loadingEquipment = false;
      notifyListeners();
    }
  }

  Future<void> loadBorrowRecords() async {
    if (!_profile.isStudent) {
      _borrowPage = PagedResult<EquipmentBorrowRecord>(
        records: <EquipmentBorrowRecord>[],
        total: 0,
        pageNum: 1,
        pageSize: _borrowPageSize,
        pages: 0,
      );
      _borrowErrorMessage = null;
      notifyListeners();
      return;
    }

    _loadingBorrowRecords = true;
    _borrowErrorMessage = null;
    notifyListeners();

    try {
      _borrowPage = await _repository.fetchMyBorrowList(
        pageNum: _borrowPageNum,
        pageSize: _borrowPageSize,
        status: _borrowStatusFilter,
      );
    } on ApiException catch (error) {
      _borrowErrorMessage = error.message;
    } catch (_) {
      _borrowErrorMessage = '借用记录加载失败，请稍后重试';
    } finally {
      _loadingBorrowRecords = false;
      notifyListeners();
    }
  }

  Future<void> searchEquipment(String value) async {
    final next = value.trim();
    if (_equipmentKeyword == next && _equipmentPageNum == 1) {
      return;
    }
    _equipmentKeyword = next;
    _equipmentPageNum = 1;
    await loadEquipment();
  }

  Future<void> clearEquipmentKeyword() async {
    if (_equipmentKeyword.isEmpty) {
      return;
    }
    _equipmentKeyword = '';
    _equipmentPageNum = 1;
    await loadEquipment();
  }

  Future<void> previousEquipmentPage() async {
    if (_equipmentPageNum <= 1) {
      return;
    }
    _equipmentPageNum -= 1;
    await loadEquipment();
  }

  Future<void> nextEquipmentPage() async {
    if (_equipmentPage != null && _equipmentPageNum >= _equipmentPage!.pages) {
      return;
    }
    _equipmentPageNum += 1;
    await loadEquipment();
  }

  Future<void> setBorrowStatusFilter(int? status) async {
    if (_borrowStatusFilter == status) {
      return;
    }
    _borrowStatusFilter = status;
    _borrowPageNum = 1;
    await loadBorrowRecords();
  }

  Future<void> previousBorrowPage() async {
    if (_borrowPageNum <= 1) {
      return;
    }
    _borrowPageNum -= 1;
    await loadBorrowRecords();
  }

  Future<void> nextBorrowPage() async {
    if (_borrowPage != null && _borrowPageNum >= _borrowPage!.pages) {
      return;
    }
    _borrowPageNum += 1;
    await loadBorrowRecords();
  }

  Future<bool> submitBorrow({
    required int equipmentId,
    required String reason,
    required DateTime expectedReturnTime,
  }) async {
    _submittingBorrow = true;
    _equipmentErrorMessage = null;
    _borrowErrorMessage = null;
    notifyListeners();

    try {
      await _repository.submitBorrow(
        equipmentId: equipmentId,
        reason: reason,
        expectedReturnTime: expectedReturnTime.toIso8601String(),
      );
      await Future.wait<void>(<Future<void>>[
        loadEquipment(),
        loadBorrowRecords(),
      ]);
      return true;
    } on ApiException catch (error) {
      _borrowErrorMessage = error.message;
      return false;
    } catch (_) {
      _borrowErrorMessage = '提交借用申请失败，请稍后重试';
      return false;
    } finally {
      _submittingBorrow = false;
      notifyListeners();
    }
  }

  String equipmentName(int? equipmentId) {
    if (equipmentId == null) {
      return '设备';
    }
    return _equipmentCache[equipmentId]?.name ?? '设备 #$equipmentId';
  }
}
