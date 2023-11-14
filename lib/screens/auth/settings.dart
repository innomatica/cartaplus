import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/cartaauth.dart';
import '../../logic/cartabloc.dart';
import '../../shared/flutter_icons.dart';
import '../cloud/webdav_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    icon: Icon(FlutterIcons.google,
                        color: Theme.of(context).colorScheme.tertiary),
                    onPressed: () async {
                      final credential = await _auth.signInWithGoogle();
                      if (credential != null) {
                        credential.user?.delete();
                        // https://stackoverflow.com/questions/44159819/how-to-dismiss-an-alertdialog-on-a-flatbutton-click
                        if (mounted) {
                          Navigator.of(context, rootNavigator: true).pop(true);
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                              'Failed to delete account (${_auth.lastError})',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ));
                        }
                      }
                    },
                    label: const Text('Sign In with Google'),
                  ),
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView(
        children: [
          // Email
          ListTile(
            title: const Text('Email'),
            subtitle: Text(_auth.user?.email ?? ''),
          ),
          // Cancel Account
          ListTile(
            title: const Text('Cancel Account'),
            subtitle: const Text('Delete data and close account'),
            onTap: () => _accountCancelDialog(),
          ),
          // WebDav Servers
          for (final server in servers)
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              title: Text(server.title),
              children: [WebDavSettings(server: server)],
            ),
          const ExpansionTile(
            tilePadding: EdgeInsets.symmetric(horizontal: 16.0),
            childrenPadding: EdgeInsets.symmetric(horizontal: 16.0),
            title: Text('Add a new WebDav server'),
            children: [WebDavSettings()],
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
