import 'dart:async';
import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../model/cartabook.dart';
import '../model/cartalibrary.dart';
import '../model/cartaserver.dart';
import 'drive_api.dart';

/// Each item is a separate Drive file so edits to different books do not
/// overwrite one another. Only book/server metadata lives in appDataFolder.
class DriveRepo {
  DriveRepo(this.api, this.uid, {FlutterSecureStorage? secrets})
      : _secrets = secrets ?? const FlutterSecureStorage();

  final DriveApi api;
  final String uid;
  final FlutterSecureStorage _secrets;
  Future<void> _serial = Future.value();

  static const _bookPrefix = 'cartaplus-book-';
  static const _serverPrefix = 'cartaplus-server-';
  static const _libraryPrefix = 'cartaplus-library-';

  Future<T> _oneAtATime<T>(Future<T> Function() action) async {
    final previous = _serial;
    final gate = Completer<void>();
    _serial = gate.future;
    await previous;
    try {
      return await action();
    } finally {
      gate.complete();
    }
  }

  String _name(String prefix, String id) =>
      '$prefix${Uri.encodeComponent(id)}.json';

  Future<DriveFile?> _find(String name) async {
    final files = await api.listAppFiles();
    for (final file in files) {
      if (file.name == name) return file;
    }
    return null;
  }

  Future<void> _put(String name, Map<String, dynamic> data) async {
    final existing = await _find(name);
    if (existing == null) {
      await api.createJson(name, data);
    } else {
      await api.updateJson(existing.id, data);
    }
  }

  Future<void> _remove(String name) async {
    final file = await _find(name);
    if (file != null) await api.deleteFile(file.id);
  }

  Future<List<Map<String, dynamic>>> _all(String prefix) async {
    final files = await api.listAppFiles();
    final values = <Map<String, dynamic>>[];
    for (final file in files.where((f) => f.name.startsWith(prefix))) {
      try {
        values.add(await api.readJson(file.id));
      } catch (error) {
        log('Could not read ${file.name}: $error');
        rethrow;
      }
    }
    return values;
  }

  String _secretKey(String kind, String id, String field) =>
      'cartaplus/$uid/$kind/$id/$field';

  Future<void> _saveCredentials(
      String kind, String id, Map<String, dynamic> data) async {
    for (final field in ['username', 'password']) {
      final value = data[field];
      if (value is String && value.isNotEmpty) {
        await _secrets.write(key: _secretKey(kind, id, field), value: value);
      } else if (data.containsKey(field)) {
        await _secrets.delete(key: _secretKey(kind, id, field));
      }
    }
  }

  Future<void> _loadCredentials(
      String kind, String id, Map<String, dynamic> data) async {
    for (final field in ['username', 'password']) {
      final value = await _secrets.read(key: _secretKey(kind, id, field));
      if (value != null) data[field] = value;
    }
  }

  Future<void> _deleteCredentials(String kind, String id) async {
    for (final field in ['username', 'password']) {
      await _secrets.delete(key: _secretKey(kind, id, field));
    }
  }

  /// Credentials must never be uploaded, even inside nested book sections.
  dynamic _withoutCredentials(dynamic value) {
    if (value is Map) {
      return <String, dynamic>{
        for (final entry in value.entries)
          if (entry.key != 'username' && entry.key != 'password')
            entry.key as String: _withoutCredentials(entry.value),
      };
    }
    if (value is List) return value.map(_withoutCredentials).toList();
    return value;
  }

  Future<bool> addAudioBook(CartaBook book) async => _oneAtATime(() async {
        await _saveCredentials('book', book.bookId, book.info);
        await _put(_name(_bookPrefix, book.bookId),
            _withoutCredentials(book.toFirestore()) as Map<String, dynamic>);
        return true;
      });

  Future<bool> updateAudioBook(CartaBook book) => addAudioBook(book);

  Future<CartaBook?> getAudioBookByBookId(String bookId) async {
    final file = await _find(_name(_bookPrefix, bookId));
    if (file == null) return null;
    final book = CartaBook.fromFirestore(await api.readJson(file.id));
    await _loadCredentials('book', book.bookId, book.info);
    return book;
  }

  Future<List<CartaBook>> getAudioBooks() async {
    final books = <CartaBook>[];
    for (final data in await _all(_bookPrefix)) {
      final book = CartaBook.fromFirestore(data);
      await _loadCredentials('book', book.bookId, book.info);
      books.add(book);
    }
    return books;
  }

  Future<bool> updateBookData(String bookId, Map<String, Object?> data) async =>
      _oneAtATime(() async {
        final book = await getAudioBookByBookId(bookId);
        if (book == null) return false;
        final json = book.toFirestore()..addAll(data);
        await _put(_name(_bookPrefix, bookId),
            _withoutCredentials(json) as Map<String, dynamic>);
        return true;
      });

  Future<bool> deleteAudioBook(CartaBook book) async => _oneAtATime(() async {
        await _remove(_name(_bookPrefix, book.bookId));
        await _deleteCredentials('book', book.bookId);
        return true;
      });

  Future<bool> addBookServer(CartaServer server) async => _oneAtATime(() async {
        await _saveCredentials(
            'server', server.serverId, server.settings ?? {});
        await _put(_name(_serverPrefix, server.serverId),
            _withoutCredentials(server.toFirestore()) as Map<String, dynamic>);
        return true;
      });

  Future<bool> updateBookServer(CartaServer server) => addBookServer(server);

  Future<CartaServer?> getBookServerById(String serverId) async {
    final file = await _find(_name(_serverPrefix, serverId));
    if (file == null) return null;
    final server = CartaServer.fromFirestore(await api.readJson(file.id));
    server.settings ??= {};
    await _loadCredentials('server', server.serverId, server.settings!);
    return server;
  }

  Future<List<CartaServer>> getBookServers() async {
    final servers = <CartaServer>[];
    for (final data in await _all(_serverPrefix)) {
      final server = CartaServer.fromFirestore(data);
      server.settings ??= {};
      await _loadCredentials('server', server.serverId, server.settings!);
      servers.add(server);
    }
    return servers;
  }

  Future<bool> deleteBookServer(CartaServer server) async =>
      _oneAtATime(() async {
        await _remove(_name(_serverPrefix, server.serverId));
        await _deleteCredentials('server', server.serverId);
        return true;
      });

  /// A library is a normal Drive JSON file, shared with anyone who has its
  /// link. Private subscriptions are stored in this user's appDataFolder.
  Future<bool> createLibrary(CartaLibrary library) async =>
      _oneAtATime(() async {
        final data =
            _withoutCredentials(library.toFirestore()) as Map<String, dynamic>;
        final file = await api.createJson(
            'Carta Plus - ${library.title}.json', data,
            appData: false);
        await api.shareByLink(file.id);
        final metadata = await api.getMetadata(file.id);
        library.id = file.id;
        library.info['resourceKey'] = metadata.resourceKey;
        await api.updateJson(file.id,
            _withoutCredentials(library.toFirestore()) as Map<String, dynamic>);
        await _saveLibraryRef(library, owned: true);
        return true;
      });

  Future<void> _saveLibraryRef(CartaLibrary library,
      {required bool owned}) async {
    final id = library.id!;
    await _put(_name(_libraryPrefix, id), {
      'id': id,
      'owned': owned,
      if (library.info['resourceKey'] != null)
        'resourceKey': library.info['resourceKey'],
    });
  }

  Future<List<CartaLibrary>> getOurLibraries() async {
    final libraries = <CartaLibrary>[];
    for (final ref in await _all(_libraryPrefix)) {
      final id = ref['id'] as String;
      try {
        final owned = ref['owned'] == true;
        final key = ref['resourceKey'] as String?;
        final data = owned
            ? await api.readJson(id, resourceKey: key)
            : await api.readPublicJson(id, resourceKey: key);
        final library = CartaLibrary.fromFirestore(id, data);
        library.info['resourceKey'] = key;
        library.signedUp = true;
        libraries.add(library);
      } on DriveApiException catch (error) {
        if (error.statusCode == 403 || error.statusCode == 404) {
          log('Shared library $id is no longer accessible: $error');
          continue;
        }
        log('Could not load shared library $id: $error');
        rethrow;
      }
    }
    return libraries;
  }

  Future<CartaLibrary> joinLibrary(String link) async {
    final uri = Uri.parse(link.trim());
    final match = RegExp(r'^/file/d/([^/]+)/view/?$').firstMatch(uri.path);
    if (uri.host != 'drive.google.com' || match == null) {
      throw const FormatException('Use a Google Drive file sharing link');
    }
    final id = match.group(1)!;
    final key = uri.queryParameters['resourcekey'];
    final data = await api.readPublicJson(id, resourceKey: key);
    if (data['owner'] is! String || data['books'] is! List) {
      throw const FormatException('This is not a Carta Plus library');
    }
    final library = CartaLibrary.fromFirestore(id, data);
    library.info['resourceKey'] = key;
    library.signedUp = true;
    await _saveLibraryRef(library, owned: false);
    return library;
  }

  String libraryLink(CartaLibrary library) {
    final id = library.id;
    if (id == null) throw StateError('Save the library before sharing');
    return Uri.https('drive.google.com', '/file/d/$id/view', {
      if (library.info['resourceKey'] is String)
        'resourcekey': library.info['resourceKey'] as String,
    }).toString();
  }

  Future<bool> updateLibrary(CartaLibrary library) async =>
      _oneAtATime(() async {
        if (library.owner != uid || library.id == null) return false;
        await api.updateJson(library.id!,
            _withoutCredentials(library.toFirestore()) as Map<String, dynamic>);
        return true;
      });

  Future<bool> deleteLibrary(CartaLibrary library) async =>
      _oneAtATime(() async {
        if (library.owner != uid || library.id == null) return false;
        await api.deleteFile(library.id!);
        await _remove(_name(_libraryPrefix, library.id!));
        return true;
      });

  Future<void> leaveLibrary(CartaLibrary library) async {
    if (library.id != null && library.owner != uid) {
      await _remove(_name(_libraryPrefix, library.id!));
    }
  }

  void close() => api.close();
}
