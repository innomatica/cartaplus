import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../enc_dec.dart';

enum ServerType { nextcloud, gdrive }

class CartaServer {
  String serverId;
  String title;
  ServerType type;
  String url;
  Map<String, dynamic>? settings;

  CartaServer({
    required this.serverId,
    required this.type,
    required this.title,
    required this.url,
    this.settings,
  });

  factory CartaServer.fromSqlite(Map<String, dynamic> data) {
    return CartaServer(
      serverId: data['serverId'],
      title: data['title'],
      type: ServerType.values[data['type'] ?? 0],
      url: data['url'],
      settings: jsonDecode(data['settings']),
    );
  }

  factory CartaServer.fromFirestore(DocumentSnapshot data) {
    return CartaServer(
      serverId: data['serverId'],
      title: data['title'],
      type: ServerType.values[data['type'] ?? 0],
      url: data['url'],
      settings: data['settings'] == null
          ? null
          : (data['settings'] as Map<String, dynamic>)
              .map((key, value) => MapEntry(
                    key,
                    ['password', 'username'].contains(key)
                        ? decrypt(value)
                        : value,
                  )),
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      'serverId': serverId,
      'title': title,
      'type': type.index,
      'url': url,
      'settings': jsonEncode(settings),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'serverId': serverId,
      'title': title,
      'type': type.index,
      'url': url,
      'settings': settings?.map((key, value) => MapEntry(
            key,
            ['password', 'username'].contains(key) ? encrypt(value) : value,
          )),
    };
  }

  @override
  String toString() {
    return toSqlite().toString();
  }
}
