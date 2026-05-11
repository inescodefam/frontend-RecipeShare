class PagedResponse<T> {
  const PagedResponse({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.hasNextPage,
  });

  final List<T> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final bool hasNextPage;

  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) itemFromJson,
  ) {
    final raw = json['items'] as List<dynamic>? ?? const [];
    return PagedResponse(
      items: raw.map((e) => itemFromJson(e as Map<String, dynamic>)).toList(),
      pageNumber: json['pageNumber'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? raw.length,
      totalCount: json['totalCount'] as int? ?? raw.length,
      hasNextPage: json['hasNextPage'] as bool? ?? false,
    );
  }
}
