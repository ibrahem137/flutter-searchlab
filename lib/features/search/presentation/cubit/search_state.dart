import '../../domain/book.dart';
import '../../domain/search_query.dart';

class SearchState {
  final SearchQuery query;
  final List<Book> items;
  final bool loading, loadingMore, hasMore;
  final int page, generation;
  final String? error;
  final String source;
  SearchState(
      {this.query = const SearchQuery(),
      List<Book> items = const [],
      this.loading = false,
      this.loadingMore = false,
      this.hasMore = true,
      this.page = 0,
      this.error,
      this.source = 'none',
      this.generation = 0})
      : items = List.unmodifiable(items);
  SearchState copyWith(
          {SearchQuery? query,
          List<Book>? items,
          bool? loading,
          bool? loadingMore,
          bool? hasMore,
          int? page,
          String? error,
          bool clearError = false,
          String? source,
          int? generation}) =>
      SearchState(
          query: query ?? this.query,
          items: items ?? this.items,
          loading: loading ?? this.loading,
          loadingMore: loadingMore ?? this.loadingMore,
          hasMore: hasMore ?? this.hasMore,
          page: page ?? this.page,
          error: clearError ? null : error ?? this.error,
          source: source ?? this.source,
          generation: generation ?? this.generation);
}
