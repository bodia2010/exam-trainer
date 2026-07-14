import 'package:exam_trainer/screens/import_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('free tier receives only the first cached variant and edition', () {
    final cached = <String, List<dynamic>>{
      'lesen_teil1': [
        {'variant_number': 1, 'content': 'first'},
        {'variant_number': 2, 'content': 'premium-only'},
      ],
      'telefonnotiz': [
        {
          'variant_number': 1,
          'versions': [
            {'label': 'original'},
            {'label': 'premium-only edition'},
          ],
        },
        {'variant_number': 2},
      ],
      'empty': [],
    };

    final free = freeTierSectionsFromCache(cached);

    expect(free['lesen_teil1'], hasLength(1));
    expect(free['lesen_teil1']!.first['content'], 'first');
    expect(free['telefonnotiz'], hasLength(1));
    expect(free['telefonnotiz']!.first['versions'], hasLength(1));
    expect(free['telefonnotiz']!.first['versions'].first['label'], 'original');
    expect(free['empty'], isEmpty);

    // The shared premium cache value must remain intact for premium callers.
    expect(cached['lesen_teil1'], hasLength(2));
    expect(cached['telefonnotiz']!.first['versions'], hasLength(2));
  });
}
