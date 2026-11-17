import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/search_query.dart';
import '../cubit/search_cubit.dart';
import '../cubit/search_state.dart';
import '../widgets/book_tile.dart';
import '../widgets/search_filters.dart';

class SearchPage extends StatefulWidget {
  final ValueChanged<int> onFavorite;
  final Set<int> favorites;
  const SearchPage(
      {super.key, required this.onFavorite, required this.favorites});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final scroll = ScrollController();
  final searchController = TextEditingController();
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SearchCubit, SearchState>(builder: (context, s) {
        final cubit = context.read<SearchCubit>();
        return Column(children: [
          Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search title or author',
                        border: OutlineInputBorder()),
                    onChanged: (v) => cubit.updateQuery(
                        s.query.copyWith(text: v),
                        debounce: true)),
                const SizedBox(height: 8),
                SearchFilters(
                    query: s.query,
                    onChanged: cubit.updateQuery,
                    onClear: () {
                      searchController.clear();
                      cubit.updateQuery(const SearchQuery());
                    }),
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
                        return BookTile(
                            book: b,
                            isFavorite: widget.favorites.contains(b.id),
                            onFavorite: () => widget.onFavorite(b.id));
                      })),
        ]);
      });
  @override
  void dispose() {
    searchController.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    searchController.text = context.read<SearchCubit>().state.query.text;
    scroll.addListener(() {
      if (scroll.hasClients && scroll.position.extentAfter < 250) {
        context.read<SearchCubit>().loadMore();
      }
    });
  }
}
