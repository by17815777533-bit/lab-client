import '../core/network/api_client.dart';
import '../models/delivery_record.dart';
import '../models/paged_result.dart';

class DeliveryRepository {
  DeliveryRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PagedResult<DeliveryRecord>> fetchDeliveries({
    int pageNum = 1,
    int pageSize = 10,
    int? labId,
    String? realName,
    String? studentId,
    int? auditStatus,
  }) async {
    final response = await _apiClient.get(
      '/api/delivery/list',
      queryParameters: <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize,
        'labId': labId,
        'realName': realName,
        'studentId': studentId,
        'auditStatus': auditStatus,
      },
    );

    return PagedResult<DeliveryRecord>.fromJson(
      response as Map<String, dynamic>,
      DeliveryRecord.fromJson,
    );
  }

  Future<void> auditDelivery({
    required int id,
    required int auditStatus,
    String? auditRemark,
  }) {
    return _apiClient.post(
      '/api/delivery/audit/$id',
      queryParameters: <String, dynamic>{
        'auditStatus': auditStatus,
        'auditRemark': auditRemark,
      },
    );
  }

  Future<void> admitDelivery(int id) {
    return _apiClient.post('/api/delivery/admit/$id');
  }
}
