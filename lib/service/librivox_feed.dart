import 'package:xml/xml.dart';

class LibriVoxFeedItem {
  const LibriVoxFeedItem({
    required this.title,
    required this.url,
    required this.duration,
  });

  final String title;
  final String url;
  final int duration;
}

/// Reads the RSS fields used by LibriVox without depending on a private parser.
List<LibriVoxFeedItem> parseLibriVoxFeed(String source) {
  final document = XmlDocument.parse(source);
  return document
      .findAllElements('item')
      .map((item) {
        final children = item.children.whereType<XmlElement>();
        XmlElement? child(String name) {
          for (final element in children) {
            if (element.name.local == name) return element;
          }
          return null;
        }

        final enclosure = child('enclosure');
        final media = child('content');
        final url =
            enclosure?.getAttribute('url') ?? media?.getAttribute('url') ?? '';
        final rawDuration = child('duration')?.innerText ??
            media?.getAttribute('duration') ??
            '';
        return LibriVoxFeedItem(
          title: child('title')?.innerText.trim() ?? 'Unknown Section',
          url: url,
          duration: _durationSeconds(rawDuration),
        );
      })
      .where((item) => item.url.isNotEmpty)
      .toList();
}

int _durationSeconds(String value) {
  final parts = value.trim().split(':');
  if (parts.isEmpty || parts.length > 3) return 0;
  final numbers = parts.map(int.tryParse).toList();
  if (numbers.any((number) => number == null)) return 0;
  var total = 0;
  for (final number in numbers) {
    total = total * 60 + number!;
  }
  return total;
}
