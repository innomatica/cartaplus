import 'dart:convert';

import 'package:cartaplus/model/cartabook.dart';
import 'package:cartaplus/model/cartasection.dart';
import 'package:cartaplus/repo/drive_api.dart';
import 'package:cartaplus/repo/drive_repo.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Drive API addresses file endpoints and paginates app data', () async {
    final paths = <String>[];
    final api = DriveApi(
      accessToken: () async => 'access-token',
      client: MockClient((request) async {
        paths.add('${request.method} ${request.url.path}');
        expect(request.headers['authorization'], 'Bearer access-token');
        if (request.method == 'GET' && request.url.path.endsWith('/files')) {
          return http.Response(
              jsonEncode({
                'files': [
                  {
                    'id': request.url.queryParameters['pageToken'] == null
                        ? 'a'
                        : 'b',
                    'name': 'book.json'
                  }
                ],
                if (request.url.queryParameters['pageToken'] == null)
                  'nextPageToken': 'next',
              }),
              200);
        }
        if (request.method == 'GET' &&
            request.url.queryParameters['alt'] == 'media') {
          return http.Response('{"bookId":"b"}', 200);
        }
        if (request.method == 'POST') {
          return http.Response('{"id":"new","name":"book.json"}', 200);
        }
        return http.Response('', 204);
      }),
    );
    expect((await api.listAppFiles()).map((file) => file.id), ['a', 'b']);
    expect((await api.readJson('file id'))['bookId'], 'b');
    await api.createJson('book.json', {'bookId': 'b'});
    await api.updateJson('file id', {'bookId': 'c'});
    await api.deleteFile('file id');
    expect(paths, contains('GET /drive/v3/files/file%20id'));
    expect(paths, contains('POST /upload/drive/v3/files'));
    expect(paths, contains('PATCH /upload/drive/v3/files/file%20id'));
    expect(paths, contains('DELETE /drive/v3/files/file%20id'));
    api.close();
  });

  test('book credentials stay in secure storage and never reach Drive',
      () async {
    final secure = <String, String>{};
    FlutterSecureStoragePlatform.instance =
        TestFlutterSecureStoragePlatform(secure);
    final drive = <String, Map<String, dynamic>>{};
    var nextId = 0;
    final api = DriveApi(
      accessToken: () async => 'access-token',
      client: MockClient((request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/files')) {
          return http.Response(
              jsonEncode({
                'files': [
                  for (final entry in drive.entries)
                    {'id': entry.key, 'name': entry.value['name']},
                ],
              }),
              200);
        }
        final id = request.url.pathSegments.last;
        if (request.method == 'GET') {
          return http.Response(jsonEncode(drive[id]!['data']), 200);
        }
        if (request.method == 'POST') {
          final parts = request.body.split('\r\n');
          final metadata =
              jsonDecode(parts.firstWhere((part) => part.contains('"name"')))
                  as Map<String, dynamic>;
          final data =
              jsonDecode(parts.firstWhere((part) => part.contains('"bookId"')))
                  as Map<String, dynamic>;
          final newId = '${++nextId}';
          drive[newId] = {'name': metadata['name'], 'data': data};
          return http.Response(
              jsonEncode({'id': newId, 'name': metadata['name']}), 200);
        }
        if (request.method == 'PATCH') {
          drive[id]!['data'] = jsonDecode(request.body);
          return http.Response('', 200);
        }
        if (request.method == 'DELETE') {
          drive.remove(id);
          return http.Response('', 204);
        }
        return http.Response('', 404);
      }),
    );
    final repo = DriveRepo(api, 'google-user');
    final book = CartaBook(
      bookId: 'one',
      title: 'One',
      source: CartaSource.cloud,
      info: {
        'authentication': 'basic',
        'username': 'alice',
        'password': 'secret'
      },
      sections: [
        CartaSection(
            index: 0,
            title: 'Part',
            uri: 'https://example.org/a.mp3',
            info: {'username': 'alice', 'password': 'secret'})
      ],
    );
    expect(await repo.addAudioBook(book), isTrue);
    expect(jsonEncode(drive), isNot(contains('secret')));
    expect(jsonEncode(drive), isNot(contains('alice')));
    expect(secure.values, contains('secret'));
    final restored = (await repo.getAudioBooks()).single;
    expect(restored.getAuthHeaders(), contains('authorization'));
    await repo.deleteAudioBook(restored);
    expect(drive, isEmpty);
    expect(secure, isEmpty);
    repo.close();
  });

  test('joining a shared library saves only a private reference', () async {
    final files = <String, Map<String, dynamic>>{};
    final api = DriveApi(
      accessToken: () async => 'access-token',
      publicApiKey: 'public-key',
      client: MockClient((request) async {
        if (request.url.path.endsWith('/files') && request.method == 'GET') {
          return http.Response(
              jsonEncode({
                'files': [
                  for (final entry in files.entries)
                    {'id': entry.key, 'name': entry.value['name']},
                ]
              }),
              200);
        }
        if (request.url.path.endsWith('/shared123') &&
            request.url.queryParameters['alt'] == 'media') {
          expect(request.url.queryParameters['key'], 'public-key');
          expect(request.headers['x-goog-drive-resource-keys'],
              'shared123/key123');
          return http.Response(
              jsonEncode({
                'title': 'Readers',
                'owner': 'other-user',
                'members': [],
                'books': [],
                'description': 'A reading group',
                'isPublic': true,
                'info': {},
              }),
              200);
        }
        if (request.method == 'POST') {
          final parts = request.body.split('\r\n');
          final metadata =
              jsonDecode(parts.firstWhere((part) => part.contains('"name"')))
                  as Map<String, dynamic>;
          final data =
              jsonDecode(parts.firstWhere((part) => part.contains('"owned"')))
                  as Map<String, dynamic>;
          files['ref1'] = {'name': metadata['name'], 'data': data};
          return http.Response(
              jsonEncode({'id': 'ref1', 'name': metadata['name']}), 200);
        }
        if (request.url.path.endsWith('/ref1')) {
          return http.Response(jsonEncode(files['ref1']!['data']), 200);
        }
        return http.Response('', 404);
      }),
    );
    final repo = DriveRepo(api, 'reader');
    final library = await repo.joinLibrary(
        'https://drive.google.com/file/d/shared123/view?resourcekey=key123');
    expect(library.title, 'Readers');
    expect(files.values.single['data'],
        {'id': 'shared123', 'owned': false, 'resourceKey': 'key123'});
    expect((await repo.getOurLibraries()).single.title, 'Readers');
    repo.close();
  });
}
