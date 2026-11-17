import 'package:flutter/material.dart';
import '../../data/sample_catalog.dart';
import '../../domain/search_query.dart';

class SearchFilters extends StatelessWidget {
  final SearchQuery query;
  final ValueChanged<SearchQuery> onChanged;
  final VoidCallback onClear;
  const SearchFilters(
      {super.key,
      required this.query,
      required this.onChanged,
      required this.onClear});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) =>
            Wrap(spacing: 8, runSpacing: 6, children: [
          _choice(
              'Center',
              query.center,
              centers,
              (v) => onChanged(query.copyWith(center: v)),
              constraints.maxWidth),
          _choice(
              'Category',
              query.category,
              categories,
              (v) => onChanged(query.copyWith(category: v)),
              constraints.maxWidth),
          _choice('Sort', query.sort, const ['Newest', 'Oldest', 'Title'],
              (v) => onChanged(query.copyWith(sort: v)), constraints.maxWidth),
          OutlinedButton(onPressed: onClear, child: const Text('Clear')),
        ]),
      );

  Widget _choice(String label, String value, List<String> options,
          ValueChanged<String> changed, double maxWidth) =>
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: DropdownButton<String>(
          value: value,
          items: options
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text('$label: $e', overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (v) {
            if (v != null) changed(v);
          },
        ),
      );
}
