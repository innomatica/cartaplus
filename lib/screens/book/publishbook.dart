import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/cartabloc.dart';
import '../../model/cartabook.dart';

class PublishBook extends StatelessWidget {
  final CartaBook book;
  const PublishBook({required this.book, super.key});

  @override
  Widget build(BuildContext context) {
    final logic = context.watch<CartaBloc>();
    final myLibrary = logic.getMyLibrary();
    if (myLibrary != null && myLibrary.id is String) {
      final index = myLibrary.books.indexWhere((b) => b.bookId == book.bookId);
      return index == -1
          ? IconButton(
              icon: const Icon(Icons.playlist_add_check_rounded),
              // recommend book
              onPressed: () {
                myLibrary.books.add(book);
                logic.updateLibrary(myLibrary);
              },
            )
          : IconButton(
              icon: const Icon(Icons.playlist_remove_rounded),
              // redraw recommendation
              onPressed: () {
                myLibrary.books.removeWhere((b) => b.bookId == book.bookId);
                logic.updateLibrary(myLibrary);
              },
            );
    }
    return const SizedBox(width: 0, height: 0);
  }
}
