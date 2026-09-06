import 'package:flutter_test/flutter_test.dart';
import 'package:sajda_dataplus/services/date_service.dart';
import 'package:sajda_dataplus/services/hijri_date_service.dart';

void main() {
  group('DateService — timezone-aware local date (streak agreement)', () {
    test('formats plain date', () {
      expect(
        dateService.formatDateAsYYYYMMDD(date: DateTime(2024, 1, 15)),
        '2024-01-15',
      );
    });

    test('converts an instant into the location timezone (Tokyo +9)', () {
      // 2024-01-15 20:00 UTC == 2024-01-16 05:00 in Tokyo.
      expect(
        dateService.formatDateAsYYYYMMDD(
          date: DateTime.utc(2024, 1, 15, 20, 0),
          timezone: 'Asia/Tokyo',
        ),
        '2024-01-16',
      );
    });

    test('converts an instant into the location timezone (New York -5)', () {
      // 2024-01-15 20:00 UTC == 2024-01-15 15:00 in New York.
      expect(
        dateService.formatDateAsYYYYMMDD(
          date: DateTime.utc(2024, 1, 15, 20, 0),
          timezone: 'America/New_York',
        ),
        '2024-01-15',
      );
    });

    test('matches backend rule: 19:00 UTC == next day in Karachi (+5)', () {
      // Backend getTodayDateString('Asia/Karachi') at 19:00 UTC must agree.
      expect(
        dateService.formatDateAsYYYYMMDD(
          date: DateTime.utc(2024, 1, 15, 19, 0),
          timezone: 'Asia/Karachi',
        ),
        '2024-01-16',
      );
    });

    test('falls back to device-local formatting for unknown timezone', () {
      final d = DateTime(2024, 3, 9);
      expect(
        dateService.formatDateAsYYYYMMDD(date: d, timezone: 'Not/AZone'),
        '2024-03-09',
      );
    });

    test('pads month and day', () {
      expect(
        dateService.formatDateAsYYYYMMDD(date: DateTime(2024, 3, 5)),
        '2024-03-05',
      );
    });

    test('parses YYYY-MM-DD', () {
      final d = dateService.parseDate('2024-01-15');
      expect(d.year, 2024);
      expect(d.month, 1);
      expect(d.day, 15);
    });

    test('isToday / isYesterday (device-local)', () {
      final now = DateTime.now();
      expect(dateService.isToday(now), isTrue);
      expect(
        dateService.isYesterday(now.subtract(const Duration(days: 1))),
        isTrue,
      );
      expect(dateService.isToday(now.subtract(const Duration(days: 2))), isFalse);
    });
  });

  group('HijriDateService — Maghrib Islamic-day boundary', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    test('before Maghrib returns plain conversion of today', () {
      final result = HijriDateService.getHijriDate(
        today,
        maghribTime: DateTime(today.year, today.month, today.day, 23, 59),
      );
      final plain = HijriDateService.convertPlain(today);
      expect(result.day, plain.day);
      expect(result.month, plain.month);
      expect(result.year, plain.year);
    });

    test('after Maghrib advances to next Islamic day', () {
      // Maghrib at 00:00 -> "now" is always at/after Maghrib.
      final result = HijriDateService.getHijriDate(
        today,
        maghribTime: DateTime(today.year, today.month, today.day, 0, 0),
      );
      // Ground truth: plain conversion of tomorrow (its default 18:30 Maghrib
      // has not occurred yet, so no double shift).
      final expected = HijriDateService.getHijriDate(
        tomorrow,
        maghribTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59),
      );
      expect(result.day, expected.day);
      expect(result.month, expected.month);
      expect(result.year, expected.year);
    });

    test('arbitrary (non-today) dates convert plainly with no shift', () {
      final past = DateTime(2024, 1, 15);
      final result = HijriDateService.getHijriDate(past);
      final plain = HijriDateService.convertPlain(past);
      expect(result.day, plain.day);
      expect(result.month, plain.month);
    });

    test('HijriDateInfo formatting', () {
      final info = HijriDateService.convertPlain(DateTime(2024, 1, 15));
      expect(info.full, contains('AH'));
      expect(info.fullAr, contains('هـ'));
      expect(info.monthEn, isNotEmpty);
      expect(info.monthAr, isNotEmpty);
    });
  });
}
