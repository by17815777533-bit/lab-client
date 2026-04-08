import '../core/network/api_client.dart';
import '../models/equipment_borrow_record.dart';
import '../models/equipment_item.dart';
import '../models/paged_result.dart';

class EquipmentRepository {
  EquipmentRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PagedResult<EquipmentItem>> fetchEquipmentList({
    int pageNum = 1,
    int pageSize = 10,
    int? labId,
    String? name,
    int? status,
  }) async {
    final response = await _apiClient.get(
      '/api/equipment/list',
      queryParameters: <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize,
        'labId': labId,
        'name': name,
        'status': status,
      },
    );
    return PagedResult<EquipmentItem>.fromJson(
      response as Map<String, dynamic>,
      EquipmentItem.fromJson,
    );
  }

  Future<void> createEquipment({
    required String name,
    required String type,
    String? serialNumber,
    String? imageUrl,
    String? description,
    int status = 0,
  }) {
    return _apiClient.post(
      '/api/equipment/add',
      data: <String, dynamic>{
        'name': name,
        'type': type,
        'serialNumber': serialNumber,
        'imageUrl': imageUrl,
        'description': description,
        'status': status,
      },
    );
  }

  Future<void> updateEquipment({
    required int id,
    required String name,
    required String type,
    String? serialNumber,
    String? imageUrl,
    String? description,
    int status = 0,
  }) {
    return _apiClient.put(
      '/api/equipment/update',
      data: <String, dynamic>{
        'id': id,
        'name': name,
        'type': type,
        'serialNumber': serialNumber,
        'imageUrl': imageUrl,
        'description': description,
        'status': status,
      },
    );
  }

  Future<void> deleteEquipment(int id) {
    return _apiClient.delete('/api/equipment/$id');
  }

  Future<void> submitBorrow({
    required int equipmentId,
    required String reason,
    String? expectedReturnTime,
  }) {
    return _apiClient.post(
      '/api/equipment/borrow',
      data: <String, dynamic>{
        'equipmentId': equipmentId,
        'reason': reason,
        'expectedReturnTime': expectedReturnTime,
      },
    );
  }

  Future<PagedResult<EquipmentBorrowRecord>> fetchBorrowList({
    int pageNum = 1,
    int pageSize = 10,
    int? userId,
    int? equipmentId,
    int? labId,
    int? status,
  }) async {
    final response = await _apiClient.get(
      '/api/equipment/borrow/list',
      queryParameters: <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize,
        'userId': userId,
        'equipmentId': equipmentId,
        'labId': labId,
        'status': status,
      },
    );
    return PagedResult<EquipmentBorrowRecord>.fromJson(
      response as Map<String, dynamic>,
      EquipmentBorrowRecord.fromJson,
    );
  }

  Future<PagedResult<EquipmentBorrowRecord>> fetchMyBorrowList({
    int pageNum = 1,
    int pageSize = 10,
    int? status,
  }) async {
    final response = await _apiClient.get(
      '/api/equipment/borrow/my',
      queryParameters: <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize,
        'status': status,
      },
    );
    return PagedResult<EquipmentBorrowRecord>.fromJson(
      response as Map<String, dynamic>,
      EquipmentBorrowRecord.fromJson,
    );
  }

  Future<void> auditBorrow({required int id, required int status}) {
    return _apiClient.post(
      '/api/equipment/borrow/audit',
      data: <String, dynamic>{'id': id, 'status': status},
    );
  }

  Future<void> confirmReturn({required int id}) {
    return _apiClient.post(
      '/api/equipment/borrow/return',
      data: <String, dynamic>{'id': id},
    );
  }
}
