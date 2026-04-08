class PagedResult<T> {
  PagedResult({
    required this.records,
    required this.total,
    required this.pageNum,
    required this.pageSize,
    required this.pages,
  });

  final List<T> records;
  final int total;
  final int pageNum;
  final int pageSize;
  final int pages;

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemBuilder,
  ) {
    return PagedResult.fromCustomJson(
      json,
      itemBuilder,
      recordsKey: 'records',
      totalKey: 'total',
      pageNumKey: 'current',
      pageSizeKey: 'size',
      pagesKey: 'pages',
    );
  }

  factory PagedResult.fromCustomJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemBuilder, {
    required String recordsKey,
    required String totalKey,
    required String pageNumKey,
    required String pageSizeKey,
    required String pagesKey,
  }) {
    final rawRecords =
        (json[recordsKey] as List<dynamic>? ?? const <dynamic>[]);
    return PagedResult<T>(
      records: rawRecords
          .whereType<Map>()
          .map((item) => itemBuilder(item.cast<String, dynamic>()))
          .toList(),
      total: (json[totalKey] as num?)?.toInt() ?? 0,
      pageNum: (json[pageNumKey] as num?)?.toInt() ?? 1,
      pageSize: (json[pageSizeKey] as num?)?.toInt() ?? 10,
      pages: (json[pagesKey] as num?)?.toInt() ?? 0,
    );
  }
}
