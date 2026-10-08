import '../shared/helpers.dart';

enum ServerType { nextcloud, koofr, webdav }

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

  factory CartaServer.fromFirestore(Map<String, dynamic>? doc) {
    try {
      return CartaServer(
        serverId: doc?['serverId'],
        title: doc?['title'],
        type: ServerType.values[doc?['type'] ?? 0],
        url: doc?['url'],
        settings: doc?['settings'] as Map<String, dynamic>?,
      );
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'serverId': serverId,
      'title': title,
      'type': type.index,
      'url': url,
      'settings': settings,
    };
  }

  @override
  String toString() {
    return toFirestore().toString();
  }
}
