import 'package:cartaplus/service/librivox_feed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses RSS enclosures and podcast durations', () {
    const rss = '''
<rss xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
  <channel>
    <item>
      <title>Chapter One</title>
      <enclosure url="https://example.org/one.mp3" type="audio/mpeg" />
      <itunes:duration>01:02:03</itunes:duration>
    </item>
    <item><title>Without audio</title></item>
  </channel>
</rss>''';
    final items = parseLibriVoxFeed(rss);
    expect(items, hasLength(1));
    expect(items.single.title, 'Chapter One');
    expect(items.single.url, 'https://example.org/one.mp3');
    expect(items.single.duration, 3723);
  });
}
