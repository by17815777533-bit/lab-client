class FileUrlResolver {
  static String resolve({required String baseUrl, required String? rawUrl}) {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return '';
    }

    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }

    final normalizedBaseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final normalizedPath = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';

    if (normalizedPath.startsWith('/uploads/')) {
      return '$normalizedBaseUrl/api/file/view?path=${Uri.encodeComponent(normalizedPath)}';
    }

    return '$normalizedBaseUrl$normalizedPath';
  }
}
