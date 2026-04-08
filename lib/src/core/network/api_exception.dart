import 'package:dio/dio.dart';

import 'error_message_sanitizer.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromDio(DioException error) {
    final responseData = error.response?.data;
    String? responseMessage;

    if (responseData is Map) {
      responseMessage = responseData['message']?.toString();
    } else if (responseData is String && responseData.trim().isNotEmpty) {
      responseMessage = responseData;
    }

    return ApiException(
      ErrorMessageSanitizer.sanitize(
        responseMessage,
        fallback: _resolveFallbackMessage(error),
      ),
      statusCode: error.response?.statusCode,
    );
  }

  static String _resolveFallbackMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '请求超时，请稍后重试';
      case DioExceptionType.connectionError:
        return '网络连接失败，请检查网络状态后重试';
      case DioExceptionType.badResponse:
        return '服务器返回异常，请稍后重试';
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.badCertificate:
        return '证书校验失败';
      case DioExceptionType.unknown:
        return '请求失败，请稍后重试';
    }
  }

  @override
  String toString() => message;
}
