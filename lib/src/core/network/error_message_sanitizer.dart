class ErrorMessageSanitizer {
  static String sanitize(String? raw, {String fallback = '请求失败，请稍后重试'}) {
    final message = raw?.trim() ?? '';
    if (message.isEmpty) {
      return fallback;
    }

    final normalized = message.toLowerCase();

    if (_containsAny(normalized, <String>[
      'sqlsyntaxerrorexception',
      'error querying database',
      'bad sql grammar',
      'table \'',
      'nested exception',
      'cause:',
      '###',
    ])) {
      return '当前服务正在维护，请稍后再试';
    }

    if (_containsAny(normalized, <String>[
      'gradpath service request failed',
      'connection refused',
      'localhost:8080',
      'service returned an empty response',
      'service returned an invalid response',
      'service error',
    ])) {
      return '当前智能练习服务暂时不可用，请稍后再试';
    }

    if (_containsAny(normalized, <String>[
      'access denied',
      'forbidden',
      '权限',
      '无权',
    ])) {
      return '当前账号暂无访问权限';
    }

    if (_containsAny(normalized, <String>[
      'user not found',
      'unauthorized',
      'token',
      'login expired',
    ])) {
      return '登录状态已失效，请重新登录';
    }

    if (message.contains('\n')) {
      return fallback;
    }

    return message;
  }

  static bool _containsAny(String source, List<String> patterns) {
    for (final pattern in patterns) {
      if (source.contains(pattern)) {
        return true;
      }
    }
    return false;
  }
}
