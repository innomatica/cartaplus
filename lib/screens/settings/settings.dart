import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../logic/cartaauth.dart';
import '../../logic/cartabloc.dart';
import 'library.dart';
import 'webdav.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const tilePadding = EdgeInsets.symmetric(horizontal: 16.0);
  final _link = TextEditingController();

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  Future<void> _join(CartaBloc logic) async {
    try {
      await logic.joinLibraryLink(_link.text);
      _link.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Library added')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open library: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<CartaAuth>();
    final logic = context.watch<CartaBloc>();
    final myLibrary = logic.getMyLibrary();
    final titleStyle = TextStyle(color: Theme.of(context).colorScheme.tertiary);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: ListView(children: [
          ListTile(
              title: Text('Email', style: titleStyle),
              subtitle: Text(auth.user?.email ?? '')),
          ListTile(
            title: Text('Sign out', style: titleStyle),
            subtitle: const Text('Your books remain in your Google Drive'),
            onTap: () async {
              await auth.signOut();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          if (logic.syncError != null)
            ListTile(
              title: const Text('Drive sync failed'),
              subtitle: Text(logic.syncError!),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => logic.syncNow(),
              ),
            ),
          ExpansionTile(
            tilePadding: tilePadding,
            childrenPadding: tilePadding,
            title: Text(myLibrary == null ? 'Create My Library' : 'My Library',
                style: titleStyle),
            children: [
              LibrarySettings(userId: auth.uid!, library: myLibrary),
              if (myLibrary?.id != null)
                ListTile(
                  title: const Text('Share library link'),
                  subtitle:
                      const Text('Anyone with the link can read its book list'),
                  trailing: const Icon(Icons.share),
                  onTap: () => Share.share(logic.libraryLink(myLibrary!)),
                ),
            ],
          ),
          ExpansionTile(
            tilePadding: tilePadding,
            childrenPadding: tilePadding,
            title: Text('Shared Libraries', style: titleStyle),
            children: [
              for (final library
                  in logic.libraries.where((l) => l.owner != logic.uid))
                ListTile(
                  title: Text(library.title),
                  subtitle: Text(library.description ?? ''),
                  trailing: IconButton(
                    tooltip: 'Leave library',
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => logic.cancelLibrary(library),
                  ),
                ),
              TextField(
                controller: _link,
                decoration: const InputDecoration(
                  labelText: 'Google Drive library link',
                  hintText: 'https://drive.google.com/file/d/.../view',
                ),
              ),
              TextButton(
                  onPressed: () => _join(logic),
                  child: const Text('Join by link')),
            ],
          ),
          for (final server in logic.servers)
            ExpansionTile(
              tilePadding: tilePadding,
              childrenPadding: tilePadding,
              title: Text(server.title, style: titleStyle),
              children: [WebDavSettings(server: server)],
            ),
          ExpansionTile(
            tilePadding: tilePadding,
            childrenPadding: tilePadding,
            title: Text('Register WebDAV Server', style: titleStyle),
            children: const [WebDavSettings()],
          ),
        ]),
      ),
    );
  }
}
