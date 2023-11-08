import 'package:cartaplus/model/cartaserver.dart';
import 'package:cartaplus/screens/cloud/ncsettings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/authprovider.dart';
import '../../logic/cartabloc.dart';
import '../../shared/flutter_icons.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AuthProvider _auth;
  // String? _email;
  // String? _password;
  // bool _obscurePassword = true;

  @override
  void initState() {
    _auth = context.read<AuthProvider>();
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
                        credential.user
                            ?.delete()
                            .then((_) => Navigator.of(context).pop(true));
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
                //
                // Cancel through Email Password Authentication
                //
                // TextField(
                //   onChanged: (value) => _email = value,
                //   decoration: const InputDecoration(
                //     isDense: true,
                //     icon: Icon(Icons.email_rounded),
                //     label: Text('email'),
                //   ),
                // ),
                // TextField(
                //   onChanged: (value) => _password = value,
                //   obscureText: _obscurePassword,
                //   decoration: InputDecoration(
                //     suffixIcon: IconButton(
                //       icon: _obscurePassword
                //           ? const Icon(Icons.visibility_rounded)
                //           : const Icon(Icons.visibility_off_rounded),
                //       onPressed: () {
                //         _obscurePassword = !_obscurePassword;
                //         setState(() {});
                //       },
                //     ),
                //     isDense: true,
                //     icon: const Icon(Icons.password_rounded),
                //     label: const Text('password'),
                //   ),
                // ),
                // const SizedBox(height: 22.0),
                // SizedBox(
                //   width: 200,
                //   child: ElevatedButton(
                //     onPressed: () async {
                //       if (_email != null &&
                //           _email!.isNotEmpty &&
                //           _password != null &&
                //           _password!.isNotEmpty) {
                //         FocusManager.instance.primaryFocus?.unfocus();
                //         final credential =
                //             await _auth.signInWithEmailAndPassword(
                //                 email: _email!, password: _password!);
                //         if (credential != null) {
                //           credential.user
                //               ?.delete()
                //               .then((_) => Navigator.of(context).pop(true));
                //         } else {
                //           if (mounted) {
                //             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                //               content: Text(
                //                 'Failed to delete account (${_auth.lastError})',
                //                 style: const TextStyle(
                //                     fontWeight: FontWeight.w600),
                //               ),
                //             ));
                //           }
                //         }
                //       }
                //     },
                //     child: const Text('Sign in with email'),
                //   ),
                // ),
              ],
            ),
          );
        });
      },
    ).then((value) {
      // needs to pop
      if (value == true) {
        Navigator.of(context).pop();
      }
    });
  }

  void _editWebDavServer({CartaServer? server}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text('lllll'),
      ),
    );
  }

  Widget _buildBody() {
    final logic = context.read<CartaBloc>();
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
          // Change Password
          // ListTile(
          //   title: const Text('Change Password'),
          //   subtitle: const Text('Log out then reset password'),
          //   onTap: () {
          //     _auth.signOut().then((_) => Navigator.of(context).pop());
          //   },
          // ),
          // Cancel Account
          ListTile(
            title: const Text('Cancel Account'),
            subtitle: const Text('Delete data and close account'),
            onTap: () => _accountCancelDialog(),
          ),
          // WebDav Servers
          ListTile(
            title: const Text('WebDav Servers'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final server in servers)
                  TextButton(
                    onPressed: () => _editWebDavServer(server: server),
                    child: Text(server.title),
                  ),
                TextButton(
                  onPressed: () => _editWebDavServer(),
                  child: const Text('Add a new server'),
                ),
              ],
            ),
          )
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
