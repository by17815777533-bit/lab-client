class AppEnvironment {
  static const String appName = 'LabLink';
  static const String schoolName = '安徽信息工程学院';
  static const String defaultBaseUrl = 'http://101.35.79.76';
  static const String appVersion = '1.0.0';

  static String normalizeBaseUrl(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return defaultBaseUrl;
    }
    return trimmed.replaceAll(RegExp(r'/+$'), '');
  }
}
