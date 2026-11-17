import 'book.dart';

class PageResult {
  final List<Book> items;
  final bool hasMore;
  PageResult(List<Book> items, this.hasMore) : items = List.unmodifiable(items);
}
