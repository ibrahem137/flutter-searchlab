import 'dart:convert';

class SearchQuery {
  final String text, center, category, sort;
  const SearchQuery(
      {this.text = '',
      this.center = 'All',
      this.category = 'All',
      this.sort = 'Newest'});
  String get key => jsonEncode([text, center, category, sort]);
  SearchQuery copyWith(
          {String? text, String? center, String? category, String? sort}) =>
      SearchQuery(
          text: text ?? this.text,
          center: center ?? this.center,
          category: category ?? this.category,
          sort: sort ?? this.sort);
  @override
  bool operator ==(Object other) =>
      other is SearchQuery &&
      text == other.text &&
      center == other.center &&
      category == other.category &&
      sort == other.sort;

  @override
  int get hashCode => Object.hash(text, center, category, sort);
}
