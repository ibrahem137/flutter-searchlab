import 'package:flutter/material.dart';
import '../../search/data/sample_catalog.dart';

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
