import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/fake_catalog_api.dart';
import '../../data/catalog_failure.dart';
import '../../domain/book.dart';
import '../../domain/search_query.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final FakeCatalogApi api;
  final Map<String, List<Book>> _memoryCache = {};
  Map<String, List<Book>> get memoryCache => Map.unmodifiable(_memoryCache);

  void clearCache() => _memoryCache.clear();
  Timer? _debounce;
  CancelToken? _token;
  int _generation = 0;
  bool debounceEnabled = true;
  bool cancellationEnabled = true;
  bool generationGuardEnabled = true;
  bool cacheEnabled = true;
  SearchCubit(this.api) : super(SearchState()) {
    refresh();
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    _token?.cancel();
    ++_generation;
    return super.close();
  }

  Future<void> loadMore() async {
    if (isClosed ||
        state.loading ||
        state.loadingMore ||
        !state.hasMore ||
        state.page == 0) {
      return;
    }
    final generation = _generation;
    final query = state.query;
    final nextPage = state.page + 1;
    final token = _token ?? CancelToken();
    emit(state.copyWith(loadingMore: true, clearError: true));
    try {
      final result = await api.fetch(query, nextPage, token);
      if (isClosed || (generationGuardEnabled && generation != _generation)) {
        return;
      }
      final seen = state.items.map((e) => e.id).toSet();
      final merged = [
        ...state.items,
        ...result.items.where((e) => seen.add(e.id))
      ];
      emit(state.copyWith(
          items: merged,
          page: nextPage,
          hasMore: result.hasMore,
          loadingMore: false,
          source: 'fresh network',
          clearError: true));
    } on DioException catch (e) {
      if (isClosed || (generationGuardEnabled && generation != _generation)) {
        return;
      }
      if (CancelToken.isCancel(e)) {
        emit(state.copyWith(loading: false, loadingMore: false));
        return;
      }
      emit(state.copyWith(loadingMore: false, error: catalogFailureMessage(e)));
    } catch (_) {
      if (!isClosed && (!generationGuardEnabled || generation == _generation)) {
        emit(state.copyWith(
            loadingMore: false,
            error: 'Unable to load more books. Please retry.'));
      }
    }
  }

  Future<void> refresh() async {
    if (isClosed) return;
    _debounce?.cancel();
    final generation = ++_generation;
    final query = state.query;
    final cached = cacheEnabled ? _memoryCache[query.key] : null;
    if (cancellationEnabled) _token?.cancel();
    final token = CancelToken();
    _token = token;
    emit(SearchState(
        query: query,
        items: cached ?? [],
        loading: true,
        source: cached == null ? 'network' : 'stale cache',
        generation: generation));
    try {
      final result = await api.fetch(query, 1, token);
      if (isClosed || (generationGuardEnabled && generation != _generation)) {
        return;
      }
      if (cacheEnabled) {
        _memoryCache[query.key] = result.items;
      }
      emit(SearchState(
          query: query,
          items: result.items,
          page: 1,
          hasMore: result.hasMore,
          source: 'fresh network',
          generation: generation));
    } on DioException catch (e) {
      if (isClosed || (generationGuardEnabled && generation != _generation)) {
        return;
      }
      if (CancelToken.isCancel(e)) {
        emit(state.copyWith(loading: false, loadingMore: false));
        return;
      }
      emit(SearchState(
          query: query,
          items: cached ?? [],
          page: cached == null ? 0 : 1,
          hasMore: false,
          source: cached == null ? 'none' : 'offline cache',
          error: catalogFailureMessage(e),
          generation: generation));
    } catch (_) {
      if (!isClosed && (!generationGuardEnabled || generation == _generation)) {
        emit(state.copyWith(
            loading: false,
            loadingMore: false,
            error: 'Unable to load books. Please retry.'));
      }
    }
  }

  void updateQuery(SearchQuery next, {bool debounce = false}) {
    if (isClosed || next == state.query) return;
    ++_generation; // Invalidate old results immediately, even during debounce.
    _debounce?.cancel();
    if (cancellationEnabled) _token?.cancel();
    emit(SearchState(query: next, generation: _generation));
    if (debounce && debounceEnabled) {
      _debounce = Timer(const Duration(milliseconds: 400), refresh);
    } else {
      refresh();
    }
  }
}
