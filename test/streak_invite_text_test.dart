import 'package:flutter_test/flutter_test.dart';
import 'package:sajda_dataplus/utils/streak_invite_text.dart';

void main() {
  group('buildStreakInviteShareText', () {
    test('always contains the invite code, streak title and join URL', () {
      final text = buildStreakInviteShareText(
        streakTitle: 'Family Namaz Streak',
        inviteCode: 'ABC123',
        appUrl: 'https://example.com/app',
      );
      expect(text, contains('ABC123'));
      expect(text, contains('Family Namaz Streak'));
      expect(text, contains('https://example.com/app'));
      expect(text, contains('Invite Code: ABC123'));
      expect(text, contains('use this code to join'));
    });

    test('includes inviter name when provided', () {
      final text = buildStreakInviteShareText(
        streakTitle: 'Friends Streak',
        inviteCode: 'XYZ9',
        inviterName: 'Ahmad',
      );
      expect(text, contains('Ahmad invited you to join'));
    });

    test('falls back gracefully for empty title / blank code / blank URL', () {
      final text = buildStreakInviteShareText(
        streakTitle: '   ',
        inviteCode: ' ',
        appUrl: '',
      );
      expect(text, contains('Namaz Streak'));
      expect(text, contains('play.google.com')); // default app URL used
    });

    test('never renders an empty invite code line incorrectly', () {
      final text = buildStreakInviteShareText(
        streakTitle: 'Solo',
        inviteCode: 'CODE1',
      );
      expect(text, isNot(contains('Invite Code:  ')));
    });
  });

  group('buildStreakShareMessage (server payload)', () {
    test('appends invite code and URL to server share text', () {
      final message = buildStreakShareMessage(
        shareText: 'Someone invited you to a 30-Day Salah Streak!',
        inviteCode: 'ABC123',
        inviteUrl: 'https://example.com/app',
      );
      expect(message, contains('30-Day Salah Streak'));
      expect(message, contains('Invite Code: ABC123'));
      expect(message, endsWith('https://example.com/app'));
    });

    test('handles missing code gracefully', () {
      final message = buildStreakShareMessage(
        shareText: 'Hello',
        inviteCode: '',
        inviteUrl: 'https://example.com/app',
      );
      expect(message, 'Hello\n\nhttps://example.com/app');
    });

    test('handles fully empty payload', () {
      expect(buildStreakShareMessage(shareText: '', inviteCode: '', inviteUrl: ''), '');
    });
  });
}
