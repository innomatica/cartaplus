import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/cartabloc.dart';
import '../../model/cartalibrary.dart';

class LibrarySettings extends StatefulWidget {
  final String userId;
  final CartaLibrary? library;
  const LibrarySettings({required this.userId, this.library, super.key});

  @override
  State<LibrarySettings> createState() => _LibrarySettingsState();
}

class _LibrarySettingsState extends State<LibrarySettings> {
  final _titleController = TextEditingController();
  final _descrController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late final CartaBloc _bloc;
  late final CartaLibrary _library;
  late final bool _isowner;
  late final bool _isnew;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<CartaBloc>();
    if (widget.library != null) {
      _library = widget.library!;
      _isowner = _library.owner == widget.userId;
      _isnew = false;
    } else {
      _library = CartaLibrary.fromDefault(widget.userId);
      _isowner = true;
      _isnew = true;
    }
    _titleController.text = _library.title;
    _descrController.text = _library.description ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isowner
        ? Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    label: Text('title'),
                    hintText: 'BBC Crime Dramas',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty == true) {
                      return 'Please enter library title';
                    }
                    return null;
                  },
                ),
                // description
                TextFormField(
                  controller: _descrController,
                  decoration: const InputDecoration(
                    label: Text('description'),
                    hintText: 'Late 80s BBC radio crime dramas',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty == true) {
                      return 'Please enter library description';
                    }
                    return null;
                  },
                ),
                // public : for now only public type is supported
                // SwitchListTile(
                //   contentPadding:
                //       const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
                //   title: const Text('allow public access'),
                //   value: _library.isPublic,
                //   onChanged: (value) {
                //     _library.isPublic = value;
                //     setState(() {});
                //   },
                // ),
                const SizedBox(height: 12.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: _isnew
                          ? null
                          : () {
                              _bloc.deleteLibrary(_library);
                              ExpansionTileController.of(context).collapse();
                            },
                      child: const Text('Delete Library'),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          // dismiss screen keyboard
                          FocusManager.instance.primaryFocus?.unfocus();
                          _library.title = _titleController.text.trim();
                          _library.description = _descrController.text.trim();
                          _isnew
                              ? await _bloc.createLibrary(_library)
                              : await _bloc.updateLibrary(_library);
                          if (context.mounted) {
                            ExpansionTileController.of(context).collapse();
                          }
                        }
                      },
                      child: const Text('Create/Update Library'),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
              ],
            ),
          )
        // NOTE: You will never reach here under current design
        : Column(
            children: [
              Text(
                _library.description ?? '',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              TextButton(
                onPressed: () => _bloc.cancelLibrary(_library),
                child: const Text('Cancel Subscription'),
              ),
            ],
          );
  }
}
