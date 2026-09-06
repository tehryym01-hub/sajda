import 'package:flutter_test/flutter_test.dart';
import 'package:sajda_dataplus/services/date_service.dart';

void main() {
  group('Streak day = CALENDAR DAY in the location timezone (not 24h)', () {
    test('23:59 local still belongs to the old day', () {
      // 2026-09-06 18:59 UTC == 2026-09-06 23:59 Asia/Karachi (+05)
      expect(
        dateService.formatDateAsYYYYMMDD(
          date: DateTime.utc(2026, 9, 6, 18, 59),
          timezone: 'Asia/Karachi',
        ),
        '2026-09-06',
      );
    });

    test('12:00 AM local starts the new day immediately', () {
      // 2026-09-06 19:00 UTC == 2026-09-07 00:00 Asia/Karachi
      expect(
        dateService.formatDateAsYYYYMMDD(
          date: DateTime.utc(2026, 9, 6, 19, 0),
          timezone: 'Asia/Karachi',
        ),
        '2026-09-07',
      );
    });

    test('12:01 AM belongs to the new day', () {
      expect(
        dateService.formatDateAsYYYYMMDD(
          date: DateTime.utc(2026, 9, 6, 19, 1),
          timezone: 'Asia/Karachi',
        ),
        '2026-09-07',
      );
    });

    test('a 24-hour elapsed duration is NOT the day boundary (1 min apart can differ)', () {
      // Two instants 61 seconds apart land on different days because the
      // boundary is local midnight — a Duration(hours: 24) rule would keep
      // them on the same "day".
      final a = DateTime.utc(2026, 9, 6, 18, 59, 30);
      final b = DateTime.utc(2026, 9, 6, 19, 0, 31);
      expect(b.difference(a), const Duration(seconds: 61));
      expect(
        dateService.formatDateAsYYYYMMDD(date: a, timezone: 'Asia/Karachi'),
        isNot(equals(dateService.formatDateAsYYYYMMDD(date: b, timezone: 'Asia/Karachi'))),
      );
    });

    test('completing a prayer at 23:00 and again 24h later spans TWO streak days', () {
      // Day 1 prayer: 2026-09-05 23:00 Karachi == 18:00 UTC
      // Day 2 prayer: exactly +24h later.
      final d1 = DateTime.utc(2026, 9, 5, 18, 0);
      final d2 = d1.add(const Duration(hours: 24));
      final k1 = dateService.formatDateAsYYYYMMDD(date: d1, timezone: 'Asia/Karachi');
      final k2 = dateService.formatDateAsYYYYMMDD(date: d2, timezone: 'Asia/Karachi');
      expect(k1, '2026-09-05');
      expect(k2, '2026-09-06');
      expect(k1 == k2, isFalse, reason: '24h elapsed must not map to the same day key');
    });

    test('day boundary is the user timezone, not UTC', () {
      // 2026-09-07 02:00 in Karachi is still 2026-09-06 in UTC.
      final karachiNight = DateTime.utc(2026, 9, 6, 21, 0); // == Sep 7, 02:00 +05
      expect(
        dateService.formatDateAsYYYYMMDD(date: karachiNight, timezone: 'Asia/Karachi'),
        '2026-09-07',
      );
      expect(
        dateService.formatDateAsYYYYMMDD(date: karachiNight, timezone: 'UTC'),
        '2026-09-06',
      );
    });

    test('next-day progress never leaks into today (distinct keys)', () {
      final today = dateService.formatDateAsYYYYMMDD(
        date: DateTime.utc(2026, 9, 6, 20, 0),
        timezone: 'Asia/Karachi',
      );
      final yesterday = dateService.formatDateAsYYYYMMDD(
        date: DateTime.utc(2026, 9, 5, 20, 0),
        timezone: 'Asia/Karachi',
      );
      expect(today, '2026-09-07');
      expect(yesterday, '2026-09-06');
      expect(today, isNot(yesterday));
    });

    test('nowHmInTimezone returns a valid wall clock for the location', () {
      final (h, m) = dateService.nowHmInTimezone('Asia/Karachi');
      expect(h, inInclusiveRange(0, 23));
      expect(m, inInclusiveRange(0, 59));
    });

    test('nowHmInTimezone converts a fixed instant correctly across zones', () {
      // Regression guard for next-prayer math: 2026-09-06 01:00 (+05)
      // Karachi is the same instant as 2026-09-05 16:00 (-04) New York.
      final karachi = dateService.zonedDateTimeToInstant('Asia/Karachi', 2026, 9, 6, 1, 0);
      final newYork = dateService.zonedDateTimeToInstant('America/New_York', 2026, 9, 5, 16, 0);
      expect(karachi!.isAtSameMomentAs(newYork!), isTrue);
    });
  });

  group('parseHm', () {
    test('parses HH:mm', () {
      expect(dateService.parseHm('18:32'), (18, 32));
      expect(dateService.parseHm(' 05:07 '), (5, 7));
    });
    test('rejects malformed values', () {
      expect(dateService.parseHm('25:00'), isNull);
      expect(dateService.parseHm('12:60'), isNull);
      expect(dateService.parseHm('12'), isNull);
      expect(dateService.parseHm(''), isNull);
    });
  });
}
