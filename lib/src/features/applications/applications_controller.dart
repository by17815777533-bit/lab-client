import 'package:flutter/foundation.dart';

import '../../models/lab_application.dart';
import '../../repositories/application_repository.dart';

class ApplicationsController extends ChangeNotifier {
  ApplicationsController(this._applicationRepository);

  final ApplicationRepository _applicationRepository;

  bool _loading = false;
  String? _statusFilter;
  int _pageNum = 1;
  int _pageSize = 10;
  int _total = 0;
  List<LabApplication> _items = <LabApplication>[];

  bool get loading => _loading;
  String? get statusFilter => _statusFilter;
  int get pageNum => _pageNum;
  int get pageSize => _pageSize;
  int get total => _total;
  int get totalPages => _total == 0 ? 1 : (_total / _pageSize).ceil();
  List<LabApplication> get items => _items;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    try {
      final result = await _applicationRepository.fetchMyApplications(
        pageNum: _pageNum,
        pageSize: _pageSize,
        status: _statusFilter,
      );
      _items = result.records;
      _total = result.total;
      _pageNum = result.pageNum;
      _pageSize = result.pageSize;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(String? value) async {
    _statusFilter = value;
    _pageNum = 1;
    await load();
  }

  Future<void> nextPage() async {
    if (_pageNum >= totalPages) {
      return;
    }
    _pageNum += 1;
    await load();
  }

  Future<void> previousPage() async {
    if (_pageNum <= 1) {
      return;
    }
    _pageNum -= 1;
    await load();
  }
}
