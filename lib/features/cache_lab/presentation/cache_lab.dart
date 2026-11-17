import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../search/presentation/cubit/search_cubit.dart';
import '../../search/presentation/cubit/search_state.dart';

class CacheLab extends StatefulWidget {
  const CacheLab({super.key});
  @override
  State<CacheLab> createState() => _CacheLabState();
}

class _CacheLabState extends State<CacheLab> {
  @override
  Widget build(BuildContext context) {
    final c = context.read<SearchCubit>();
    return BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) =>
            ListView(padding: const EdgeInsets.all(20), children: [
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
                    c.clearCache();
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
            ]));
  }
}
