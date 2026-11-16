import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() => runApp(const SearchLabApp());

const categories = ['All', 'Technology', 'History', 'Literature', 'Research'];

const centers = [
  'All',
  'Aleppo University',
  'Culture Directorate',
  'Cultural Center'
];
const titles = [
  'Artificial Intelligence Fundamentals',
  'History of Aleppo',
  'Modern Arabic Literature',
  'Cultural Heritage Studies',
  'Introduction to Programming',
  'Machine Learning Basics',
  'Syrian Architecture',
  'Research Methods',
  'Networks and Security',
  'Poetry and Society',
  'Digital Libraries',
  'Data Science Handbook',
];
final sampleBooks = List.generate(
    120,
    (i) => Book(
          i + 1,
          '${titles[i % titles.length]}${i >= titles.length ? ' · Vol ${i ~/ titles.length + 1}' : ''}',
          [
            'Ibrahem Alhuossien',
            'Wael Habbal',
            'Omar Hasan',
            'Lina Darwish'
          ][i % 4],
          centers[1 + i % 3],
          categories[1 + i % 4],
          2000 + i % 27,
        ));

class Book {
  final int id;
  final String title, author, center, category;
  final int year;
  const Book(
      this.id, this.title, this.author, this.center, this.category, this.year);
}

class CacheLab extends StatefulWidget {
  final VoidCallback onUpdate;
  const CacheLab({super.key, required this.onUpdate});
  @override
  State<CacheLab> createState() => _CacheLabState();
}

class FakeCatalogApi {
  final Dio dio =
      Dio(); // Uses Dio cancellation semantics, with simulated transport.
  int delayMs = 500;
  bool offline = false;
  bool failNext = false;
  int requestCount = 0;
  Future<PageResult> fetch(
      SearchQuery query, int page, CancelToken token) async {
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

class LabHome extends StatefulWidget {
  const LabHome({super.key});
  @override
  State<LabHome> createState() => _LabHomeState();
}

class NetworkLab extends StatefulWidget {
  final VoidCallback onUpdate;
  const NetworkLab({super.key, required this.onUpdate});
  @override
  State<NetworkLab> createState() => _NetworkLabState();
}

class PageResult {
  final List<Book> items;
  final bool hasMore;
  const PageResult(this.items, this.hasMore);
}

class SearchCubit extends Cubit<SearchState> {
  final FakeCatalogApi api;
  final Map<String, List<Book>> memoryCache = {};
  Timer? _debounce;
  CancelToken? _token;
  int _generation = 0;
  bool debounceEnabled = true;
  bool cancellationEnabled = true;
  bool generationGuardEnabled = true;
  bool cacheEnabled = true;
  SearchCubit(this.api) : super(const SearchState()) {
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
    if (state.loading ||
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
          source: 'fresh network'));
    } on DioException catch (e) {
      if (isClosed || (generationGuardEnabled && generation != _generation)) {
        return;
      }
      if (CancelToken.isCancel(e)) return;
      emit(state.copyWith(
          loadingMore: false, error: e.message ?? 'Load more failed'));
    }
  }

  Future<void> refresh() async {
    _debounce?.cancel();
    final generation = ++_generation;
    final query = state.query;
    final cached = cacheEnabled ? memoryCache[query.key] : null;
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
        memoryCache[query.key] = result.items;
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
      if (CancelToken.isCancel(e)) return;
      emit(SearchState(
          query: query,
          items: cached ?? [],
          page: cached == null ? 0 : 1,
          hasMore: false,
          source: cached == null ? 'none' : 'offline cache',
          error: e.message ?? 'Network error',
          generation: generation));
    }
  }

  void updateQuery(SearchQuery next, {bool debounce = false}) {
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

class SearchLabApp extends StatelessWidget {
  const SearchLabApp({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => SearchCubit(FakeCatalogApi()),
        child: MaterialApp(
            title: 'SearchLab',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
                colorScheme:
                    ColorScheme.fromSeed(seedColor: const Color(0xFF087F8C)),
                useMaterial3: true),
            home: const LabHome()),
      );
}

class SearchPage extends StatefulWidget {
  final ValueChanged<int> onFavorite;
  final Set<int> favorites;
  const SearchPage(
      {super.key, required this.onFavorite, required this.favorites});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class SearchQuery {
  final String text, center, category, sort;
  const SearchQuery(
      {this.text = '',
      this.center = 'All',
      this.category = 'All',
      this.sort = 'Newest'});
  String get key => '$text|$center|$category|$sort';
  SearchQuery copyWith(
          {String? text, String? center, String? category, String? sort}) =>
      SearchQuery(
          text: text ?? this.text,
          center: center ?? this.center,
          category: category ?? this.category,
          sort: sort ?? this.sort);
}

class SearchState {
  final SearchQuery query;
  final List<Book> items;
  final bool loading, loadingMore, hasMore;
  final int page, generation;
  final String? error;
  final String source;
  const SearchState(
      {this.query = const SearchQuery(),
      this.items = const [],
      this.loading = false,
      this.loadingMore = false,
      this.hasMore = true,
      this.page = 0,
      this.error,
      this.source = 'none',
      this.generation = 0});
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

class SessionLab extends StatelessWidget {
  final int user;
  final Set<int> favorites;
  final ValueChanged<int> onUser;
  const SessionLab(
      {super.key,
      required this.user,
      required this.favorites,
      required this.onUser});
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Session Isolation Lab',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
        const Text(
            'Two simulated users have separate favorites. This is an in-memory UI demo, not production authentication or secure persistent storage.'),
        const SizedBox(height: 20),
        SegmentedButton<int>(segments: const [
          ButtonSegment(value: 1, label: Text('User A')),
          ButtonSegment(value: 2, label: Text('User B'))
        ], selected: {
          user
        }, onSelectionChanged: (v) => onUser(v.first)),
        const SizedBox(height: 20),
        Text(
            'Favorites for User ${user == 1 ? 'A' : 'B'}: ${favorites.length}'),
        ...favorites.map((id) => ListTile(
            leading: const Icon(Icons.favorite),
            title: Text(sampleBooks.firstWhere((b) => b.id == id).title))),
        const SizedBox(height: 12),
        const Text(
            'Production note: private cache keys must include user/session scope; cancel requests and invalidate session generations on logout.'),
      ]);
}

class _CacheLabState extends State<CacheLab> {
  @override
  Widget build(BuildContext context) {
    final c = context.read<SearchCubit>();
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Cache & Offline Lab',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
      const Text(
          'This starter demonstrates memory cache and stale-while-revalidate. Persistent SQLite is a planned extension, not implemented yet.'),
      const SizedBox(height: 20),
      SwitchListTile(
          title: const Text('Enable memory cache'),
          value: c.cacheEnabled,
          onChanged: (v) => setState(() => c.cacheEnabled = v)),
      SwitchListTile(
          title: const Text('Simulated offline mode'),
          value: c.api.offline,
          onChanged: (v) => setState(() => c.api.offline = v)),
      Text('Cached query keys: ${c.memoryCache.length}'),
      const SizedBox(height: 12),
      FilledButton(
          onPressed: () {
            c.refresh();
            setState(() {});
          },
          child: const Text('Refresh current search')),
      OutlinedButton(
          onPressed: () {
            c.memoryCache.clear();
            setState(() {});
          },
          child: const Text('Clear memory cache')),
      OutlinedButton(
          onPressed: () {
            c.api.failNext = true;
            c.refresh();
          },
          child: const Text('Simulate next request failure')),
      const Text(
          'Demo: search while online → enable offline → refresh. Previously cached first-page results remain visible with a stale/offline indicator.'),
    ]);
  }
}

class _LabHomeState extends State<LabHome> {
  int tab = 0;
  int user = 1;
  final favorites = <int, Set<int>>{1: {}, 2: {}};
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SearchCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('SearchLab · Flutter Demo'), actions: [
        Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: Text('Requests: ${cubit.api.requestCount}'))),
      ]),
      body: IndexedStack(index: tab, children: [
        SearchPage(
            onFavorite: (id) => setState(() => favorites[user]!.contains(id)
                ? favorites[user]!.remove(id)
                : favorites[user]!.add(id)),
            favorites: favorites[user]!),
        NetworkLab(onUpdate: () => setState(() {})),
        CacheLab(onUpdate: () => setState(() {})),
        SessionLab(
            user: user,
            favorites: favorites[user]!,
            onUser: (next) => setState(() => user = next)),
      ]),
      bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
            NavigationDestination(
                icon: Icon(Icons.network_check), label: 'Network'),
            NavigationDestination(icon: Icon(Icons.storage), label: 'Cache'),
            NavigationDestination(
                icon: Icon(Icons.person_outline), label: 'Session'),
          ]),
    );
  }
}

class _NetworkLabState extends State<NetworkLab> {
  @override
  Widget build(BuildContext context) {
    final c = context.read<SearchCubit>();
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Network Playground',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
      const Text(
          'Disable protections to demonstrate incorrect results. Restore all switches afterward.'),
      const SizedBox(height: 20),
      Text('Simulated latency: ${c.api.delayMs} ms'),
      Slider(
          value: c.api.delayMs.toDouble(),
          min: 0,
          max: 2000,
          divisions: 20,
          onChanged: (v) => setState(() => c.api.delayMs = v.round())),
      SwitchListTile(
          title: const Text('Debouncing (400 ms)'),
          value: c.debounceEnabled,
          onChanged: (v) => setState(() => c.debounceEnabled = v)),
      SwitchListTile(
          title: const Text('Cancel previous request'),
          value: c.cancellationEnabled,
          onChanged: (v) => setState(() => c.cancellationEnabled = v)),
      SwitchListTile(
          title: const Text('Generation guard'),
          subtitle: const Text('Reject stale responses'),
          value: c.generationGuardEnabled,
          onChanged: (v) => setState(() => c.generationGuardEnabled = v)),
      const Divider(),
      Text('Requests sent: ${c.api.requestCount}'),
      FilledButton(
          onPressed: () {
            c.api.requestCount = 0;
            setState(() {});
          },
          child: const Text('Reset request counter')),
      const SizedBox(height: 12),
      const Text(
          'Demo: turn off Debouncing, Cancellation and Generation Guard. Search quickly, then restore the protections and repeat.'),
    ]);
  }
}

class _SearchPageState extends State<SearchPage> {
  final scroll = ScrollController();
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SearchCubit, SearchState>(builder: (context, s) {
        final cubit = context.read<SearchCubit>();
        return Column(children: [
          Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                TextField(
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search title or author',
                        border: OutlineInputBorder()),
                    onChanged: (v) => cubit.updateQuery(
                        s.query.copyWith(text: v),
                        debounce: true)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  _choice('Center', s.query.center, centers,
                      (v) => cubit.updateQuery(s.query.copyWith(center: v))),
                  _choice('Category', s.query.category, categories,
                      (v) => cubit.updateQuery(s.query.copyWith(category: v))),
                  _choice(
                      'Sort',
                      s.query.sort,
                      const ['Newest', 'Oldest', 'Title'],
                      (v) => cubit.updateQuery(s.query.copyWith(sort: v))),
                  OutlinedButton(
                      onPressed: () => cubit.updateQuery(const SearchQuery()),
                      child: const Text('Clear')),
                ]),
                const SizedBox(height: 6),
                Text(
                    'Source: ${s.source} · Generation: ${s.generation} · Page: ${s.page}',
                    style: Theme.of(context).textTheme.labelSmall),
              ])),
          if (s.loading) const LinearProgressIndicator(),
          if (s.error != null)
            MaterialBanner(content: Text(s.error!), actions: [
              TextButton(onPressed: cubit.refresh, child: const Text('Retry'))
            ]),
          Expanded(
              child: s.items.isEmpty && !s.loading
                  ? const Center(
                      child: Text('No results · try different filters'))
                  : ListView.builder(
                      controller: scroll,
                      itemCount: s.items.length + (s.loadingMore ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i == s.items.length) {
                          return const Padding(
                              padding: EdgeInsets.all(16),
                              child:
                                  Center(child: CircularProgressIndicator()));
                        }
                        final b = s.items[i];
                        return ListTile(
                            leading: const Icon(Icons.menu_book_outlined),
                            title: Text(b.title),
                            subtitle: Text(
                                '${b.author} · ${b.center}\n${b.category} · ${b.year}'),
                            isThreeLine: true,
                            trailing: IconButton(
                                onPressed: () => widget.onFavorite(b.id),
                                icon: Icon(widget.favorites.contains(b.id)
                                    ? Icons.favorite
                                    : Icons.favorite_border)));
                      })),
        ]);
      });
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    scroll.addListener(() {
      if (scroll.hasClients && scroll.position.extentAfter < 250) {
        context.read<SearchCubit>().loadMore();
      }
    });
  }

  Widget _choice(String label, String value, List<String> options,
          ValueChanged<String> changed) =>
      DropdownButton<String>(
          value: value,
          items: options
              .map((e) => DropdownMenuItem(value: e, child: Text('$label: $e')))
              .toList(),
          onChanged: (v) {
            if (v != null) changed(v);
          });
}
