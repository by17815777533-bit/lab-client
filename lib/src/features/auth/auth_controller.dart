import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/storage/session_storage.dart';
import '../../models/user_profile.dart';
import '../../models/user_session.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/profile_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required SessionStorage storage,
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
  }) : _storage = storage,
       _authRepository = authRepository,
       _profileRepository = profileRepository;

  final SessionStorage _storage;
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;

  bool _initializing = true;
  bool _busy = false;
  String? _errorMessage;
  UserSession? _session;
  UserProfile? _profile;

  bool get initializing => _initializing;
  bool get busy => _busy;
  bool get isAuthenticated => _session != null && _profile != null;
  String? get errorMessage => _errorMessage;
  UserSession? get session => _session;
  UserProfile? get profile => _profile;

  Future<void> initialize() async {
    _session = _storage.readUserSession();
    _profile = _storage.readUserProfile();

    if (_session == null) {
      _initializing = false;
      notifyListeners();
      return;
    }

    try {
      final refreshedProfile = await _profileRepository.fetchProfile();
      _profile = refreshedProfile;
      await _storage.saveUserProfile(refreshedProfile);
      _errorMessage = null;
    } on ApiException catch (error) {
      if (_profile == null) {
        await _storage.clearAuth();
        _session = null;
      } else {
        _errorMessage = error.message;
      }
    } finally {
      _initializing = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextSession = await _authRepository.login(
        username: username,
        password: password,
      );
      _session = nextSession;
      await _storage.saveUserSession(nextSession);

      final nextProfile = await _profileRepository.fetchProfile();
      _profile = nextProfile;
      await _storage.saveUserProfile(nextProfile);
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    final nextProfile = await _profileRepository.fetchProfile();
    _profile = nextProfile;
    await _storage.saveUserProfile(nextProfile);
    notifyListeners();
  }

  Future<void> applyProfile(UserProfile profile) async {
    _profile = profile;
    await _storage.saveUserProfile(profile);
    notifyListeners();
  }

  Future<void> logout({bool remote = true}) async {
    _busy = true;
    notifyListeners();

    try {
      if (remote) {
        await _authRepository.logout();
      }
    } catch (_) {
      // Ignore logout failures and clear local state regardless.
    } finally {
      await _storage.clearAuth();
      _session = null;
      _profile = null;
      _errorMessage = null;
      _busy = false;
      notifyListeners();
    }
  }
}
