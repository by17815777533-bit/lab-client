import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/equipment_borrow_record.dart';
import '../../models/equipment_item.dart';
import '../../models/paged_result.dart';
import '../../repositories/equipment_repository.dart';

class EquipmentAdminController extends ChangeNotifier {
  EquipmentAdminController({
    required EquipmentRepository repository,
    int? labId,
  }) : _repository = repository,
       _labId = labId;

  final EquipmentRepository _repository;

  bool _loadingEquipment = false;
  bool _loadingBorrowRecords = false;
  bool _submitting = false;
  String? _errorMessage;

  int _equipmentPageNum = 1;
  final int _equipmentPageSize = 10;
  int _borrowPageNum = 1;
  final int _borrowPageSize = 10;

  int? _labId;
  String _equipmentName = '';
  int? _equipmentStatus;
  int? _borrowStatus;
  PagedResult<EquipmentItem>? _equipmentPage;
  PagedResult<EquipmentBorrowRecord>? _borrowPage;

  bool get loadingEquipment => _loadingEquipment;
  bool get loadingBorrowRecords => _loadingBorrowRecords;
  bool get submitting => _submitting;
  String? get errorMessage => _errorMessage;
  int get equipmentPageNum => _equipmentPageNum;
  int get equipmentPageSize => _equipmentPageSize;
  int get borrowPageNum => _borrowPageNum;
  int get borrowPageSize => _borrowPageSize;
  int? get labId => _labId;
  String get equipmentName => _equipmentName;
  int? get equipmentStatus => _equipmentStatus;
  int? get borrowStatus => _borrowStatus;
  int get equipmentTotal => _equipmentPage?.total ?? 0;
  int get equipmentTotalPages => _equipmentPage?.pages ?? 0;
  int get borrowTotal => _borrowPage?.total ?? 0;
  int get borrowTotalPages => _borrowPage?.pages ?? 0;
  List<EquipmentItem> get equipmentItems =>
      _equipmentPage?.records ?? <EquipmentItem>[];
  List<EquipmentBorrowRecord> get borrowRecords =>
      _borrowPage?.records ?? <EquipmentBorrowRecord>[];

  Future<void> refreshAll() async {
    await Future.wait(<Future<void>>[loadEquipment(), loadBorrowRecords()]);
  }

  Future<void> loadEquipment() async {
    _loadingEquipment = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _equipmentPage = await _repository.fetchEquipmentList(
        pageNum: _equipmentPageNum,
        pageSize: _equipmentPageSize,
        labId: _labId,
        name: _equipmentName.trim().isEmpty ? null : _equipmentName.trim(),
        status: _equipmentStatus,
      );
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '设备列表加载失败，请稍后重试';
    } finally {
      _loadingEquipment = false;
      notifyListeners();
    }
  }

  Future<void> loadBorrowRecords() async {
    _loadingBorrowRecords = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _borrowPage = await _repository.fetchBorrowList(
        pageNum: _borrowPageNum,
        pageSize: _borrowPageSize,
        labId: _labId,
        status: _borrowStatus,
      );
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '借用记录加载失败，请稍后重试';
    } finally {
      _loadingBorrowRecords = false;
      notifyListeners();
    }
  }

  void setLabId(int? value) {
    if (_labId == value) {
      return;
    }
    _labId = value;
    _equipmentPageNum = 1;
    _borrowPageNum = 1;
    notifyListeners();
  }

  void setEquipmentName(String value) {
    final next = value.trim();
    if (_equipmentName == next) {
      return;
    }
    _equipmentName = next;
    _equipmentPageNum = 1;
    notifyListeners();
  }

  void setEquipmentStatus(int? value) {
    if (_equipmentStatus == value) {
      return;
    }
    _equipmentStatus = value;
    _equipmentPageNum = 1;
    notifyListeners();
  }

  void setBorrowStatus(int? value) {
    if (_borrowStatus == value) {
      return;
    }
    _borrowStatus = value;
    _borrowPageNum = 1;
    notifyListeners();
  }

  void resetEquipmentFilters() {
    _equipmentName = '';
    _equipmentStatus = null;
    _equipmentPageNum = 1;
    notifyListeners();
  }

  void resetBorrowFilters() {
    _borrowStatus = null;
    _borrowPageNum = 1;
    notifyListeners();
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

  Future<bool> saveEquipment({
    int? id,
    required String name,
    required String type,
    String? serialNumber,
    String? imageUrl,
    String? description,
    required int status,
  }) async {
    _submitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (id == null) {
        await _repository.createEquipment(
          name: name,
          type: type,
          serialNumber: serialNumber,
          imageUrl: imageUrl,
          description: description,
          status: status,
        );
      } else {
        await _repository.updateEquipment(
          id: id,
          name: name,
          type: type,
          serialNumber: serialNumber,
          imageUrl: imageUrl,
          description: description,
          status: status,
        );
      }
      await loadEquipment();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = id == null ? '新增设备失败' : '更新设备失败';
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<bool> deleteEquipment(int id) async {
    _submitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteEquipment(id);
      await loadEquipment();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '删除设备失败，请稍后重试';
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<bool> auditBorrow({required int id, required int status}) async {
    _submitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.auditBorrow(id: id, status: status);
      await loadBorrowRecords();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '提交审核结果失败，请稍后重试';
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<bool> confirmReturn({required int id}) async {
    _submitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.confirmReturn(id: id);
      await loadBorrowRecords();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = '确认归还失败，请稍后重试';
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
