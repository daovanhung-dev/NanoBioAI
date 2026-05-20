class PaginationResponse<T> {
  final List<T> items;
  final int total;

  PaginationResponse({
    required this.items,
    required this.total,
  });
}