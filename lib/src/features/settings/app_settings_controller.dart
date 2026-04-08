import 'package:flutter/foundation.dart';

import '../../core/config/app_environment.dart';
import '../../core/storage/session_storage.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController(this._storage) : _baseUrl = _storage.baseUrl;

  final SessionStorage _storage;
  String _baseUrl;

  String get baseUrl => _baseUrl;

  Future<bool> updateBaseUrl(String rawValue) async {
    final normalizedValue = AppEnvironment.normalizeBaseUrl(rawValue);
    if (normalizedValue == _baseUrl) {
      return false;
    }

    _baseUrl = normalizedValue;
    await _storage.setBaseUrl(normalizedValue);
    notifyListeners();
    return true;
  }
}
