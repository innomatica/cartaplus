import 'package:cartaplus/model/cartalibrary.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/cartaauth.dart';
import '../../logic/cartabloc.dart';
import '../../shared/flutter_icons.dart';
import 'library.dart';
import 'webdav.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const tilePadding = EdgeInsets.symmetric(horizontal: 16.0);
  late CartaAuth _auth;

  @override
  void initState() {
    _auth = context.read<CartaAuth>();
    super.initState();
  }

  //
  // Cancel Account Dialog
  //
  void _accountCancelDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(
              'To proceed, please sign in again',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //
                // Cancel through Google Sign In Authentication
                //
                ElevatedButton.icon(
                  icon: Icon(FlutterIcons.google,
                      color: Theme.of(context).colorScheme.tertiary),
                  onPressed: () async {
                    final credential = await _auth.signInWithGoogle();
                    if (credential != null) {
                      credential.user?.delete();
                      // https://stackoverflow.com/questions/44159819/how-to-dismiss-an-alertdialog-on-a-flatbutton-click
                      if (context.mounted) {
                        Navigator.of(context, rootNavigator: true).pop(true);
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            'Failed to delete account (${_auth.lastError})',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ));
                      }
                    }
                  },
                  label: const Text('Sign In with Google'),
                ),
              ],
            ),
          );
        });
      },
    ).then((value) {
      // if account is deleted
      if (value == true) {
        // need to get out of the settings page
        Navigator.of(context).pop();
      }
    });
  }

  Widget _buildBody() {
    final logic = context.watch<CartaBloc>();
    final servers = logic.servers;
    final myLibrary = logic.getMyLibrary();
    final titleStyle = TextStyle(color: Theme.of(context).colorScheme.tertiary);
    // debugPrint('myLibrary: ${myLibrary.toString()}');

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView(
        children: [
          //
          // Email
          //
          ListTile(
            title: Text('Email', style: titleStyle),
            subtitle: Text(_auth.user?.email ?? ''),
          ),
          //
          // Cancel Account
          //
          ListTile(
            title: Text('Cancel Account', style: titleStyle),
            subtitle: const Text('Delete data and close account'),
            onTap: () => _accountCancelDialog(),
          ),
          //
          // My Library
          //
          myLibrary != null
              ? ExpansionTile(
                  tilePadding: tilePadding,
                  childrenPadding: tilePadding,
                  title: Text('My Library', style: titleStyle),
                  children: [
                    LibrarySettings(
                      library: myLibrary,
                      userId: _auth.uid!,
                    )
                  ],
                )
              : ExpansionTile(
                  tilePadding: tilePadding,
                  childrenPadding: tilePadding,
                  title: Text('Create My Library', style: titleStyle),
                  children: [LibrarySettings(userId: _auth.uid!)],
                ),
          //
          // Public Libraries
          //
          FutureBuilder<List<CartaLibrary>>(
              future: logic.getPublicLibraries(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ExpansionTile(
                    tilePadding: tilePadding,
                    childrenPadding: tilePadding,
                    title: Text('Public Libraries', style: titleStyle),
                    children: snapshot.data!
                        .map(
                          (l) => CheckboxListTile(
                            contentPadding: const EdgeInsets.only(left: 8.0),
                            title: Text(l.title),
                            subtitle: Text(
                              l.description ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                            value: l.signedUp,
                            onChanged: (value) => value == true
                                ? logic.signupLibrary(l)
                                : logic.cancelLibrary(l),
                          ),
                        )
                        .toList(),
                  );
                } else {
                  return const SizedBox(
                    width: 20,
                    height: 0,
                    // child: CircularProgressIndicator(),
                  );
                }
              }),
          // WebDav Servers
          for (final server in servers)
            ExpansionTile(
              tilePadding: tilePadding,
              childrenPadding: tilePadding,
              title: Text(server.title, style: titleStyle),
              children: [WebDavSettings(server: server)],
            ),
          // add a WebDav server
          ExpansionTile(
            tilePadding: tilePadding,
            childrenPadding: tilePadding,
            title: Text('Register WebDAV Server', style: titleStyle),
            children: const [WebDavSettings()],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _buildBody(),
    );
  }
}
