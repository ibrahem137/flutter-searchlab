import 'dart:math';

import 'package:dio/dio.dart';

import '../domain/page_result.dart';
import '../domain/search_query.dart';
import 'sample_catalog.dart';

class FakeCatalogApi {
  int delayMs = 500;
  bool offline = false;
  bool failNext = false;
  int requestCount = 0;
  Future<PageResult> fetch(
      SearchQuery query, int page, CancelToken token) async {
    if (page < 1) throw ArgumentError.value(page, 'page', 'Must be positive');
    requestCount++;
    final delay = delayMs;
    // Cancellation-aware fake transport, without an external server.
    for (var elapsed = 0; elapsed < delay; elapsed += 25) {
      await Future<void>.delayed(
          Duration(milliseconds: min(25, delay - elapsed)));
      if (token.isCancelled) {
        throw DioException(
            requestOptions: RequestOptions(path: '/books'),
            type: DioExceptionType.cancel);
      }
    }
    if (token.isCancelled) {
      throw DioException(
          requestOptions: RequestOptions(path: '/books'),
          type: DioExceptionType.cancel);
    }
    if (offline || failNext) {
      failNext = false;
      throw DioException(
          requestOptions: RequestOptions(path: '/books'),
          type: DioExceptionType.connectionError,
          message: 'Simulated network failure');
    }
    final needle = query.text.trim().toLowerCase();
    final matches = sampleBooks
        .where((b) =>
            (needle.isEmpty ||
                '${b.title} ${b.author}'.toLowerCase().contains(needle)) &&
            (query.center == 'All' || b.center == query.center) &&
            (query.category == 'All' || b.category == query.category))
        .toList();
    if (query.sort == 'Newest') {
      matches.sort((a, b) => b.year.compareTo(a.year) != 0
          ? b.year.compareTo(a.year)
          : a.id.compareTo(b.id));
    } else if (query.sort == 'Oldest') {
      matches.sort((a, b) => a.year.compareTo(b.year) != 0
          ? a.year.compareTo(b.year)
          : a.id.compareTo(b.id));
    } else {
      matches.sort((a, b) => a.title.compareTo(b.title));
    }
    const size = 12;
    final start = (page - 1) * size;
    return PageResult(
        start >= matches.length ? [] : matches.skip(start).take(size).toList(),
        start + size < matches.length);
  }
}
