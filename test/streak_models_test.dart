import 'package:flutter_test/flutter_test.dart';
import 'package:sajda_dataplus/models/models.dart';
import 'package:sajda_dataplus/services/api_client.dart';

void main() {
  group('StreakModel — statuses', () {
    test('parses an active streak', () {
      final s = StreakModel.fromJson({
        '_id': 'abc',
        'goalDays': 30,
        'currentDay': 12,
        'currentStreak': 9,
        'longestStreak': 15,
        'startDate': '2026-08-01T00:00:00.000Z',
        'status': 'active',
      });
      expect(s.isActive, isTrue);
      expect(s.hasEnded, isFalse);
      expect(s.progress, closeTo(12 / 30, 1e-9));
    });

    test('parses every ended status and reports hasEnded', () {
      for (final status in ['completed', 'expired', 'cancelled']) {
        final s = StreakModel.fromJson({
          '_id': 'x',
          'goalDays': 7,
          'currentDay': 7,
          'startDate': '2026-08-01T00:00:00.000Z',
          'status': status,
        });
        expect(s.hasEnded, isTrue, reason: status);
        expect(s.isActive, isFalse, reason: status);
      }
    });

    test('paused is not ended', () {
      final s = StreakModel.fromJson({
        '_id': 'x', 'goalDays': 7, 'currentDay': 3,
        'startDate': '2026-08-01T00:00:00.000Z', 'status': 'paused',
      });
      expect(s.isPaused, isTrue);
      expect(s.hasEnded, isFalse);
    });
  });

  group('SharedStreakModel', () {
    test('parses creatorName and cancelled status', () {
      final s = SharedStreakModel.fromJson({
        '_id': 'sid',
        'title': 'Morning Salah Warriors',
        'goalDays': 21,
        'currentDay': 4,
        'startDate': '2026-09-01T00:00:00.000Z',
        'status': 'cancelled',
        'inviteCode': 'ABC123',
        'creatorName': 'Ahmad',
      });
      expect(s.creatorName, 'Ahmad');
      expect(s.isCancelled, isTrue);
      expect(s.hasEnded, isTrue);
      expect(s.isActive, isFalse);
    });
  });

  group('StreakMemberModel — board payloads', () {
    test('parses userId and isCurrentUser (backend must send both)', () {
      final m = StreakMemberModel.fromJson({
        '_id': 'm1',
        'userId': 'u123',
        'displayName': 'Bilal',
        'currentDay': 5,
        'lastCompletedDate': '2026-09-06',
        'isCurrentUser': true,
      });
      expect(m.userId, 'u123');
      expect(m.isCurrentUser, isTrue);
      expect(m.isActive, isTrue);
      expect(m.displayName, 'Bilal');
    });

    test('defaults safely when optional fields are absent', () {
      final m = StreakMemberModel.fromJson({'displayName': 'Sara'});
      expect(m.userId, '');
      expect(m.isCurrentUser, isFalse);
      expect(m.currentDay, 0);
    });
  });

  group('PrayerCompletionModel — day progress', () {
    PrayerCompletionModel build({List<String> done = const []}) {
      return PrayerCompletionModel.fromJson({
        '_id': 'c1',
        'date': '2026-09-06',
        'timezone': 'Asia/Karachi',
        'fajr': done.contains('fajr'),
        'dhuhr': done.contains('dhuhr'),
        'asr': done.contains('asr'),
        'maghrib': done.contains('maghrib'),
        'isha': done.contains('isha'),
        'isComplete': done.length == 5,
      });
    }

    test('0/5 → 0 completed', () => expect(build().completedCount, 0));
    test('1/5 → 1 completed', () => expect(build(done: ['fajr']).completedCount, 1));
    test('5/5 → 5 completed and isComplete', () {
      final m = build(done: ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']);
      expect(m.completedCount, 5);
      expect(m.isComplete, isTrue);
    });
    test('duplicate flags in payload still count once per prayer', () {
      // JSON booleans are per-prayer; repeated taps cannot create duplicates
      // because each prayer maps to exactly one boolean.
      final m = PrayerCompletionModel.fromJson({
        'fajr': true, 'dhuhr': false, 'asr': false, 'maghrib': false, 'isha': false,
      });
      expect(m.completedCount, 1);
    });
  });

  group('ApiException — structured codes', () {
    test('exposes code and status', () {
      final e = ApiException('Invalid or expired invite code', code: 'INVALID_INVITE', status: 404);
      expect(e.code, 'INVALID_INVITE');
      expect(e.status, 404);
      expect(e.toString(), contains('invite'));
    });

    test('auth errors are detected across variants', () {
      expect(ApiException('x', code: 'UNAUTHORIZED', status: 401).isAuthError, isTrue);
      expect(ApiException('x', code: 'TOKEN_EXPIRED', status: 401).isAuthError, isTrue);
      expect(ApiException('x', code: 'INVALID_TOKEN').isAuthError, isTrue);
      expect(ApiException('x', code: 'INVALID_INVITE', status: 404).isAuthError, isFalse);
    });

    test('transport errors (no status) are detected as network errors', () {
      expect(ApiException('Connection refused').isNetworkError, isTrue);
      expect(ApiException('x', status: 400).isNetworkError, isFalse);
    });
  });
}
