import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../models/guide_option.dart';
import '../../repositories/guide_repository.dart';

class PathGuideController extends ChangeNotifier {
  PathGuideController(this._repository);

  final GuideRepository _repository;

  bool _loading = false;
  String? _errorMessage;
  String _keyword = '';
  List<GuideOption> _options = <GuideOption>[];

  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  String get keyword => _keyword;

  List<GuideOption> get options {
    if (_keyword.isEmpty) {
      return _options;
    }
    final query = _keyword.toLowerCase();
    return _options
        .where((GuideOption item) {
          return item.intention.toLowerCase().contains(query) ||
              item.career.toLowerCase().contains(query) ||
              item.description.toLowerCase().contains(query) ||
              item.courses.any(
                (String value) => value.toLowerCase().contains(query),
              ) ||
              item.books.any(
                (String value) => value.toLowerCase().contains(query),
              ) ||
              item.competitions.any(
                (String value) => value.toLowerCase().contains(query),
              ) ||
              item.certificates.any(
                (String value) => value.toLowerCase().contains(query),
              );
        })
        .toList(growable: false);
  }

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _options = await _repository.fetchOptions();
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '方向指南加载失败，请稍后重试';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  void setKeyword(String value) {
    final next = value.trim();
    if (next == _keyword) {
      return;
    }
    _keyword = next;
    notifyListeners();
  }
}
