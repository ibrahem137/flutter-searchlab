import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:searchlab/features/search/data/fake_catalog_api.dart';
import 'package:searchlab/features/search/data/sample_catalog.dart';
import 'package:searchlab/features/search/domain/search_query.dart';

void main() {
  test('catalog retains 120 books and twelve-item pages', () async {
    final api = FakeCatalogApi()..delayMs = 0;
    final result = await api.fetch(const SearchQuery(), 1, CancelToken());
    expect(sampleBooks.length, 120);
    expect(result.items.length, 12);
    expect(result.hasMore, isTrue);
    expect(result.items.first.year, 2026);
  });
  test('combined filters and case-insensitive author search', () async {
    final api = FakeCatalogApi()..delayMs = 0;
    final result = await api.fetch(
        const SearchQuery(
          text: 'IBRAHEM',
          category: 'Technology',
          center: 'Aleppo University',
        ),
        1,
        CancelToken());
    expect(result.items, isNotEmpty);
    expect(
        result.items.every((b) =>
            b.author == 'Ibrahem Alhuossien' &&
            b.category == 'Technology' &&
            b.center == 'Aleppo University'),
        isTrue);
  });
  test('failure is consumed once', () async {
    final api = FakeCatalogApi()
      ..delayMs = 0
      ..failNext = true;
    await expectLater(api.fetch(const SearchQuery(), 1, CancelToken()),
        throwsA(isA<DioException>()));
    expect((await api.fetch(const SearchQuery(), 1, CancelToken())).items,
        isNotEmpty);
  });
}
