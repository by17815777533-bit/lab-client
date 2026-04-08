import 'package:dio/dio.dart';

import '../../features/settings/app_settings_controller.dart';
import '../storage/session_storage.dart';
import 'api_exception.dart';
import 'error_message_sanitizer.dart';

class ApiClient {
  ApiClient({
    required SessionStorage storage,
    required AppSettingsController settingsController,
  }) : _storage = storage,
       _settingsController = settingsController,
       _dio = Dio(
         BaseOptions(
           connectTimeout: const Duration(seconds: 15),
           receiveTimeout: const Duration(seconds: 20),
           sendTimeout: const Duration(seconds: 20),
           responseType: ResponseType.json,
         ),
       );

  final SessionStorage _storage;
  final AppSettingsController _settingsController;
  final Dio _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _request(
      () => _dio.get(
        path,
        queryParameters: _compactMap(queryParameters),
        options: _buildOptions(),
      ),
    );
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      () => _dio.post(
        path,
        data: data,
        queryParameters: _compactMap(queryParameters),
        options: _buildOptions(),
      ),
    );
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      () => _dio.put(
        path,
        data: data,
        queryParameters: _compactMap(queryParameters),
        options: _buildOptions(),
      ),
    );
  }

  Future<dynamic> delete(String path, {Map<String, dynamic>? queryParameters}) {
    return _request(
      () => _dio.delete(
        path,
        queryParameters: _compactMap(queryParameters),
        options: _buildOptions(),
      ),
    );
  }

  Future<dynamic> upload(
    String path, {
    required MultipartFile file,
    String fieldName = 'file',
    Map<String, dynamic>? fields,
  }) {
    final payload = <String, dynamic>{..._compactMap(fields), fieldName: file};

    return _request(
      () => _dio.post(
        path,
        data: FormData.fromMap(payload),
        options: _buildOptions(contentType: 'multipart/form-data'),
      ),
    );
  }

  Options _buildOptions({String? contentType}) {
    final headers = <String, dynamic>{};
    final token = _storage.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return Options(headers: headers, contentType: contentType);
  }

  Future<dynamic> _request(Future<Response<dynamic>> Function() action) async {
    try {
      _dio.options.baseUrl = _settingsController.baseUrl;
      final response = await action();
      final body = _asMap(response.data);
      final code = body['code'];

      if (code == 200) {
        return body['data'];
      }

      throw ApiException(
        ErrorMessageSanitizer.sanitize(body['message']?.toString()),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    throw ApiException('接口返回了无法识别的数据格式');
  }

  Map<String, dynamic> _compactMap(Map<String, dynamic>? value) {
    if (value == null) {
      return const <String, dynamic>{};
    }
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      if (entry.value != null) {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }
}
