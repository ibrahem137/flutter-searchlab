import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:searchlab/features/search/data/fake_catalog_api.dart';
import 'package:searchlab/features/search/domain/book.dart';
import 'package:searchlab/features/search/domain/page_result.dart';
import 'package:searchlab/features/search/domain/search_query.dart';
import 'package:searchlab/features/search/presentation/cubit/search_cubit.dart';
import 'package:searchlab/features/search/presentation/cubit/search_state.dart';

class ControlledApi extends FakeCatalogApi {
  final pending = <Completer<PageResult>>[];
  @override
  Future<PageResult> fetch(SearchQuery query, int page, CancelToken token) {
    requestCount++;
    final request = Completer<PageResult>();
    pending.add(request);
    return request.future;
  }
}

const book = Book(1, 'Title', 'Author', 'Center', 'Category', 2026);
Future<void> flush() => Future<void>.value();

void main() {
  test('query equality, copyWith and unambiguous cache identity', () {
    const query = SearchQuery(text: 'a|b', center: 'c');
    expect(query, query.copyWith());
    expect(query.hashCode, query.copyWith().hashCode);
    expect(query.key, isNot(const SearchQuery(text: 'a', center: 'b|c').key));
    expect(query.copyWith(sort: 'Title').text, 'a|b');
  });
  test('state owns an immutable results snapshot', () {
    final items = <Book>[book];
    final state = SearchState(items: items);
    items.clear();
    expect(state.items, [book]);
    expect(() => state.items.clear(), throwsUnsupportedError);
  });
  test('initial load, duplicate pagination and deduplication', () async {
    final api = ControlledApi();
    final cubit = SearchCubit(api);
    expect(cubit.state.loading, isTrue);
    api.pending[0].complete(PageResult([book], true));
    await flush();
    expect(cubit.state.page, 1);
    final more = cubit.loadMore();
    await cubit.loadMore();
    expect(api.pending.length, 2);
    api.pending[1].complete(PageResult([book], false));
    await more;
    expect(cubit.state.items.length, 1);
    expect(cubit.state.page, 2);
    await cubit.loadMore();
    expect(api.pending.length, 2);
    await cubit.close();
  });
  test('out-of-order response cannot replace a newer query', () async {
    final api = ControlledApi();
    final cubit = SearchCubit(api)..cancellationEnabled = false;
    cubit.updateQuery(const SearchQuery(text: 'new'));
    api.pending[1].complete(PageResult([], false));
    await flush();
    api.pending[0].complete(PageResult([book], true));
    await flush();
    expect(cubit.state.query.text, 'new');
    expect(cubit.state.items, isEmpty);
    await cubit.close();
  });
  test('refresh invalidates in-flight pagination', () async {
    final api = ControlledApi();
    final cubit = SearchCubit(api);
    api.pending[0].complete(PageResult([book], true));
    await flush();
    final more = cubit.loadMore();
    final refresh = cubit.refresh();
    api.pending[2].complete(PageResult([], false));
    await refresh;
    api.pending[1].complete(PageResult([book], false));
    await more;
    expect(cubit.state.page, 1);
    expect(cubit.state.items, isEmpty);
    await cubit.close();
  });
  testWidgets('debounce invalidates immediately and fires only the final input',
      (tester) async {
    final api = ControlledApi();
    final cubit = SearchCubit(api)..cancellationEnabled = false;
    cubit.updateQuery(const SearchQuery(text: 'a'), debounce: true);
    api.pending[0].complete(PageResult([book], true));
    await tester.pump();
    expect(cubit.state.items, isEmpty);
    await tester.pump(const Duration(milliseconds: 200));
    cubit.updateQuery(const SearchQuery(text: 'ab'), debounce: true);
    await tester.pump(const Duration(milliseconds: 399));
    expect(api.pending.length, 1);
    await tester.pump(const Duration(milliseconds: 1));
    expect(api.pending.length, 2);
    api.pending[1].complete(PageResult([], false));
    await tester.pump();
    await cubit.close();
  });
  test('offline refresh retains cached items and clears loading', () async {
    final api = FakeCatalogApi()..delayMs = 0;
    final cubit = SearchCubit(api);
    await flush();
    expect(cubit.state.items.length, 12);
    api.offline = true;
    await cubit.refresh();
    expect(cubit.state.source, 'offline cache');
    expect(cubit.state.items.length, 12);
    expect(cubit.state.error, isNotNull);
    expect(cubit.state.loading, isFalse);
    await cubit.close();
  });
  test('unexpected transport error resolves loading; retry succeeds', () async {
    final api = ControlledApi();
    final cubit = SearchCubit(api);
    api.pending[0].completeError(StateError('broken transport'));
    await flush();
    expect(cubit.state.loading, isFalse);
    expect(cubit.state.error, isNotNull);
    final retry = cubit.refresh();
    api.pending[1].complete(PageResult([], false));
    await retry;
    expect(cubit.state.error, isNull);
    await cubit.close();
  });
  testWidgets('closing cancels debounce and ignores late completions',
      (tester) async {
    final api = ControlledApi();
    final cubit = SearchCubit(api);
    cubit.updateQuery(const SearchQuery(text: 'a'), debounce: true);
    await cubit.close();
    api.pending[0].complete(PageResult([book], true));
    await tester.pump(const Duration(seconds: 1));
    expect(api.pending.length, 1);
  });
}
