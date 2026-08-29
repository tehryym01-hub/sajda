import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as q;

void main() {
  test('Quran complete: 114 surahs, 6236 ayahs', () {
    var total = 0;
    for (var s = 1; s <= 114; s++) {
      final count = q.getVerseCount(s);
      expect(count, greaterThan(0), reason: 'Surah $s has no verses');
      expect(q.getSurahNameArabic(s), isNotEmpty, reason: 'Surah $s name missing');
      total += count;
    }
    expect(total, 6236);
  });
}