import 'package:flutter/foundation.dart';

import '../../models/notice_item.dart';
import '../../repositories/notice_repository.dart';

class NoticesController extends ChangeNotifier {
  NoticesController(this._noticeRepository);

  final NoticeRepository _noticeRepository;

  bool _loading = false;
  String? _keyword;
  String? _scope;
  int _pageNum = 1;
  int _pageSize = 10;
  int _total = 0;
  List<NoticeItem> _items = <NoticeItem>[];

  bool get loading => _loading;
  String? get keyword => _keyword;
  String? get scope => _scope;
  int get pageNum => _pageNum;
  int get total => _total;
  int get totalPages => _total == 0 ? 1 : (_total / _pageSize).ceil();
  List<NoticeItem> get items => _items;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    try {
      final result = await _noticeRepository.fetchPage(
        pageNum: _pageNum,
        pageSize: _pageSize,
        keyword: _keyword,
        publishScope: _scope,
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

  Future<void> applyFilter({String? keyword, String? scope}) async {
    _keyword = (keyword ?? '').trim().isEmpty ? null : keyword!.trim();
    _scope = scope;
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
