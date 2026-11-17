import 'package:flutter/material.dart';
import '../../domain/book.dart';

class BookTile extends StatelessWidget {
  final Book book;
  final bool isFavorite;
  final VoidCallback onFavorite;
  const BookTile(
      {super.key,
      required this.book,
      required this.isFavorite,
      required this.onFavorite});

  @override
  Widget build(BuildContext context) => ListTile(
        leading: const Icon(Icons.menu_book_outlined),
        title: Text(book.title),
        subtitle: Text(
            '${book.author} · ${book.center}\n${book.category} · ${book.year}'),
        isThreeLine: true,
        trailing: IconButton(
            onPressed: onFavorite,
            tooltip: isFavorite ? 'Remove favorite' : 'Add favorite',
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border)),
      );
}
