import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user_profile.dart';
import '../../models/user_session.dart';
import '../config/app_environment.dart';

class SessionStorage {
  SessionStorage._(this._preferences);

  static const String _baseUrlKey = 'app.base_url';
  static const String _sessionKey = 'auth.session';
  static const String _profileKey = 'auth.profile';

  final SharedPreferences _preferences;

  static Future<SessionStorage> create() async {
    final preferences = await SharedPreferences.getInstance();
    return SessionStorage._(preferences);
  }

  String get baseUrl {
    final rawValue = _preferences.getString(_baseUrlKey);
    return AppEnvironment.normalizeBaseUrl(
      rawValue ?? AppEnvironment.defaultBaseUrl,
    );
  }

  String? get token => readUserSession()?.token;

  Future<void> setBaseUrl(String value) async {
    await _preferences.setString(
      _baseUrlKey,
      AppEnvironment.normalizeBaseUrl(value),
    );
  }

  UserSession? readUserSession() {
    final rawValue = _preferences.getString(_sessionKey);
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }

    try {
      return UserSession.fromJson(jsonDecode(rawValue) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUserSession(UserSession session) async {
    await _preferences.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  UserProfile? readUserProfile() {
    final rawValue = _preferences.getString(_profileKey);
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }

    try {
      return UserProfile.fromJson(jsonDecode(rawValue) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    await _preferences.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<void> clearAuth() async {
    await _preferences.remove(_sessionKey);
    await _preferences.remove(_profileKey);
  }
}
