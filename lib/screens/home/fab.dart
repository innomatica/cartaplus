import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/cartabloc.dart';
import '../../model/cartabook.dart';
import '../../shared/booksites.dart';
import '../booksite/booksite.dart';
import '../catalog/catalog.dart';
import '../cloud/webdav_navigator.dart';

Widget buildFabDialog(BuildContext context) {
  final iconColor = Theme.of(context).colorScheme.tertiary;
  final logic = context.watch<CartaBloc>();
  return AlertDialog(
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //
        // LibriVox
        //
        TextButton.icon(
          onPressed: () {
            Navigator.pop(context);
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) =>
                  const BookSitePage(url: urlLibriVoxSearchByAuthor),
            ));
          },
          icon: CartaBook.getIconBySource(
            CartaSource.librivox,
            color: iconColor,
          ),
          label: const Text('LibriVox'),
        ),
        //
        // Internet Archive
        //
        TextButton.icon(
          onPressed: () {
            Navigator.pop(context);
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) =>
                  const BookSitePage(url: urlInternetArchiveAudio),
            ));
          },
          icon: CartaBook.getIconBySource(
            CartaSource.archive,
            color: iconColor,
          ),
          label: const Text('Internet Archive'),
        ),
        //
        // Legamus
        //
        TextButton.icon(
          onPressed: () {
            Navigator.pop(context);
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) =>
                  const BookSitePage(url: urlLegamusAllRecordings),
            ));
          },
          icon: CartaBook.getIconBySource(
            CartaSource.legamus,
            color: iconColor,
          ),
          label: const Text('Legamus'),
        ),
        //
        // Libraries
        //
        for (final library in logic.libraries)
          TextButton.icon(
            onPressed: () {
              logic.refreshLibraries();
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(library.title),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: library.books.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            title: Text(
                              library.books[index].title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: logic.uid == library.owner
                                ? null
                                : () =>
                                    logic.addAudioBook(library.books[index]),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            icon: Icon(Icons.group_rounded, color: iconColor),
            label: Text(library.title),
          ),
        // in case of not being signed up for any libraries
        logic.libraries.isEmpty
            ? TextButton.icon(
                onPressed: () =>
                    Navigator.of(context).popAndPushNamed('/settings'),
                icon: Icon(Icons.group_rounded, color: iconColor),
                label: const Text('Community Library'))
            : const SizedBox(width: 0, height: 0),
        //
        // Servers
        //
        for (final server in logic.servers)
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => WebDavNavigator(server: server),
              ));
            },
            icon: CartaBook.getIconBySource(
              CartaSource.cloud,
              color: iconColor,
            ),
            label: Text(server.title),
          ),
        // in case of having no registered servers
        logic.servers.isEmpty
            ? TextButton.icon(
                onPressed: () =>
                    Navigator.of(context).popAndPushNamed('/settings'),
                icon: CartaBook.getIconBySource(CartaSource.cloud,
                    color: iconColor),
                label: const Text('Cloud WebDAV server'),
              )
            : const SizedBox(width: 0, height: 0),
        TextButton.icon(
          onPressed: () {
            Navigator.pop(context);
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const CatalogPage(),
            ));
          },
          icon: Icon(
            Icons.favorite_border_rounded,
            color: iconColor,
          ),
          label: const Text('Carta Favorite Books'),
        ),
      ],
    ),
  );
}
