import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/cartabloc.dart';
import '../../model/cartaserver.dart';
import '../../shared/helpers.dart';

class NextCloudSettings extends StatefulWidget {
  final CartaServer? server;
  const NextCloudSettings({this.server, Key? key}) : super(key: key);

  @override
  State<NextCloudSettings> createState() => _NextCloudSettingsState();
}

class _NextCloudSettingsState extends State<NextCloudSettings> {
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _userController = TextEditingController();
  final _pswController = TextEditingController();
  final _dirController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final CartaBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<CartaBloc>();
    if (widget.server != null) {
      _titleController.text = widget.server!.title;
      _urlController.text = widget.server!.url;
      _userController.text = widget.server!.settings?['username'] ?? '';
      _pswController.text = widget.server!.settings?['password'] ?? '';
      _dirController.text = widget.server!.settings?['directory'] ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _userController.dispose();
    _pswController.dispose();
    _dirController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          top: 4.0,
          left: 12.0,
          right: 12.0,
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                label: Text('title'),
                hintText: 'My Nextcloud Instance',
              ),
              validator: (value) {
                if (value == null) {
                  return 'Please enter site title';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                label: Text('site url'),
                hintText: 'https://my.nextcloud.domain',
              ),
              validator: (value) {
                if (value == null) {
                  return 'Please enter url';
                } else if (!value.startsWith('http://') &&
                    !value.startsWith('https://')) {
                  return 'url should star "http://" or "https://"';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _userController,
              decoration: const InputDecoration(
                label: Text('login'),
                hintText: 'username',
              ),
              validator: (value) {
                if (value == null) {
                  return 'Please enter login name';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _pswController,
              obscureText: true,
              decoration: const InputDecoration(
                label: Text('password'),
                hintText: 'my super secret password',
              ),
              validator: (value) {
                if (value == null) {
                  return 'Please enter password';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _dirController,
              decoration: const InputDecoration(
                label: Text('audio books directory'),
                hintText: '/Media/MyAudioBooks',
              ),
            ),
            const SizedBox(height: 12.0),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  // dismiss screen keyboard
                  FocusManager.instance.primaryFocus?.unfocus();

                  final title = _titleController.text;
                  final url = _urlController.text;
                  final user = _userController.text;
                  final password = _pswController.text;
                  final dir = _dirController.text;
                  // final dir =
                  //     _dirController.text.replaceAll(RegExp(r'^/|/$'), '');

                  if (widget.server == null) {
                    final server = CartaServer(
                        serverId: getIdFromUrl(url),
                        type: ServerType.nextcloud,
                        title: title,
                        url: url,
                        settings: {
                          'authentication': 'basic',
                          'username': user,
                          'password': password,
                          'directory': dir,
                        });

                    _bloc.addBookServer(server);
                  } else {
                    widget.server!.title = title;
                    widget.server!.url = url;
                    widget.server!.settings = {
                      'authentication': 'basic',
                      'username': user,
                      'password': password,
                      'directory': dir,
                    };
                    _bloc.updateBookServer(widget.server!);
                  }
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add/Update Settings'),
            ),
            ElevatedButton(
              onPressed: () {
                if (widget.server != null) {
                  _bloc.deleteBookServer(widget.server!);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Delete Entry'),
            ),
            const SizedBox(height: 12.0),
          ],
        ),
      ),
    );
  }
}
