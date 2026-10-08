import 'dart:convert';

import 'package:http/http.dart' as http;

class DriveApiException implements Exception {
  DriveApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'Drive API $statusCode: $message';
}

class DriveFile {
  DriveFile.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        name = json['name'] as String? ?? '',
        modifiedTime = DateTime.tryParse(json['modifiedTime'] as String? ?? ''),
        resourceKey = json['resourceKey'] as String?,
        webViewLink = json['webViewLink'] as String?;

  final String id;
  final String name;
  final DateTime? modifiedTime;
  final String? resourceKey;
  final String? webViewLink;
}

/// The narrow Drive operations used by Carta Plus. Tokens are requested for
/// each call so the Google Sign-In plugin can refresh expired access tokens.
class DriveApi {
  DriveApi({
    required Future<String> Function() accessToken,
    http.Client? client,
    this.publicApiKey = const String.fromEnvironment('DRIVE_PUBLIC_API_KEY'),
  })  : _accessToken = accessToken,
        _client = client ?? http.Client();

  static final Uri _filesUrl =
      Uri.parse('https://www.googleapis.com/drive/v3/files');
  static final Uri _uploadUrl =
      Uri.parse('https://www.googleapis.com/upload/drive/v3/files');

  Uri _itemUrl(Uri base, String id,
          {String? suffix, Map<String, String>? query}) =>
      base.replace(
        pathSegments: [...base.pathSegments, id, if (suffix != null) suffix],
        queryParameters: query,
      );

  final Future<String> Function() _accessToken;
  final http.Client _client;
  final String publicApiKey;

  void close() => _client.close();

  Future<Map<String, String>> _headers({String? contentType}) async => {
        'Authorization': 'Bearer ${await _accessToken()}',
        if (contentType != null) 'Content-Type': contentType,
      };

  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DriveApiException(response.statusCode, response.body);
    }
  }

  Future<List<DriveFile>> listAppFiles() async {
    final files = <DriveFile>[];
    String? pageToken;
    do {
      final uri = _filesUrl.replace(queryParameters: {
        'spaces': 'appDataFolder',
        'q': 'trashed = false',
        'pageSize': '1000',
        'fields':
            'nextPageToken,files(id,name,modifiedTime,resourceKey,webViewLink)',
        if (pageToken != null) 'pageToken': pageToken,
      });
      final response = await _client.get(uri, headers: await _headers());
      _check(response);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      for (final item in body['files'] as List<dynamic>? ?? []) {
        files.add(DriveFile.fromJson(item as Map<String, dynamic>));
      }
      pageToken = body['nextPageToken'] as String?;
    } while (pageToken != null);
    return files;
  }

  Future<Map<String, dynamic>> readJson(String id,
      {String? resourceKey}) async {
    final uri = _itemUrl(_filesUrl, id, query: {'alt': 'media'});
    final headers = await _headers();
    if (resourceKey != null) {
      headers['X-Goog-Drive-Resource-Keys'] = '$id/$resourceKey';
    }
    final response = await _client.get(uri, headers: headers);
    _check(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Link-shared libraries are intentionally public. Reading them with an API
  /// key avoids requesting access to the reader's entire Google Drive.
  Future<Map<String, dynamic>> readPublicJson(String id,
      {String? resourceKey}) async {
    if (publicApiKey.isEmpty) {
      throw StateError('DRIVE_PUBLIC_API_KEY is required for shared libraries');
    }
    final uri =
        _itemUrl(_filesUrl, id, query: {'alt': 'media', 'key': publicApiKey});
    final response = await _client.get(uri, headers: {
      if (resourceKey != null) 'X-Goog-Drive-Resource-Keys': '$id/$resourceKey',
    });
    _check(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<DriveFile> createJson(String name, Map<String, dynamic> data,
      {bool appData = true}) async {
    final boundary = 'cartaplus_${DateTime.now().microsecondsSinceEpoch}';
    final metadata = {
      'name': name,
      'mimeType': 'application/json',
      if (appData) 'parents': ['appDataFolder'],
    };
    final body = '--$boundary\r\n'
        'Content-Type: application/json; charset=UTF-8\r\n\r\n'
        '${jsonEncode(metadata)}\r\n'
        '--$boundary\r\n'
        'Content-Type: application/json; charset=UTF-8\r\n\r\n'
        '${jsonEncode(data)}\r\n'
        '--$boundary--\r\n';
    final uri = _uploadUrl.replace(queryParameters: {
      'uploadType': 'multipart',
      'fields': 'id,name,modifiedTime,resourceKey,webViewLink',
    });
    final response = await _client.post(uri,
        headers: await _headers(
            contentType: 'multipart/related; boundary=$boundary'),
        body: utf8.encode(body));
    _check(response);
    return DriveFile.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> updateJson(String id, Map<String, dynamic> data) async {
    final uri = _itemUrl(_uploadUrl, id, query: {'uploadType': 'media'});
    final response = await _client.patch(uri,
        headers: await _headers(contentType: 'application/json; charset=UTF-8'),
        body: jsonEncode(data));
    _check(response);
  }

  Future<void> deleteFile(String id) async {
    final response = await _client.delete(_itemUrl(_filesUrl, id),
        headers: await _headers());
    _check(response);
  }

  Future<DriveFile> getMetadata(String id) async {
    final uri = _itemUrl(_filesUrl, id,
        query: {'fields': 'id,name,modifiedTime,resourceKey,webViewLink'});
    final response = await _client.get(uri, headers: await _headers());
    _check(response);
    return DriveFile.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> shareByLink(String id) async {
    final uri = _itemUrl(_filesUrl, id, suffix: 'permissions');
    final response = await _client.post(uri,
        headers: await _headers(contentType: 'application/json'),
        body: jsonEncode({
          'type': 'anyone',
          'role': 'reader',
          'allowFileDiscovery': false,
        }));
    _check(response);
  }
}
