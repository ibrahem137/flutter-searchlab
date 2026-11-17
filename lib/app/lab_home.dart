import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/search/presentation/cubit/search_cubit.dart';
import '../features/search/presentation/cubit/search_state.dart';
import '../features/search/presentation/pages/search_page.dart';
import '../features/network_lab/presentation/network_lab.dart';
import '../features/cache_lab/presentation/cache_lab.dart';
import '../features/session_lab/presentation/session_lab.dart';

class LabHome extends StatefulWidget {
  const LabHome({super.key});
  @override
  State<LabHome> createState() => _LabHomeState();
}

class _LabHomeState extends State<LabHome> {
  int tab = 0;
  int user = 1;
  final favorites = <int, Set<int>>{1: {}, 2: {}};
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SearchCubit>();
    return BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) => Scaffold(
              appBar: AppBar(
                  title: const Text('SearchLab · Flutter Demo'),
                  actions: [
                    Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Center(
                            child:
                                Text('Requests: ${cubit.api.requestCount}'))),
                  ]),
              body: IndexedStack(index: tab, children: [
                SearchPage(
                    onFavorite: (id) => setState(() =>
                        favorites[user]!.contains(id)
                            ? favorites[user]!.remove(id)
                            : favorites[user]!.add(id)),
                    favorites: favorites[user]!),
                NetworkLab(onUpdate: () => setState(() {})),
                const CacheLab(),
                SessionLab(
                    user: user,
                    favorites: favorites[user]!,
                    onUser: (next) => setState(() => user = next)),
              ]),
              bottomNavigationBar: NavigationBar(
                  selectedIndex: tab,
                  onDestinationSelected: (i) => setState(() => tab = i),
                  destinations: const [
                    NavigationDestination(
                        icon: Icon(Icons.search), label: 'Search'),
                    NavigationDestination(
                        icon: Icon(Icons.network_check), label: 'Network'),
                    NavigationDestination(
                        icon: Icon(Icons.storage), label: 'Cache'),
                    NavigationDestination(
                        icon: Icon(Icons.person_outline), label: 'Session'),
                  ]),
            ));
  }
}
