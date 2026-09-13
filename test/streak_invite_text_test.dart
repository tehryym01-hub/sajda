import 'package:flutter_test/flutter_test.dart';

import 'package:sajda_dataplus/utils/streak_invite_text.dart';

void main() {
  group('buildStreakInviteShareText', () {
    test('always includes the invite code', () {
      final text = buildStreakInviteShareText(
        inviterName: 'Ali',
        groupName: 'Family',
        inviteCode: 'ab2cd9',
      );
      expect(text, contains('AB2CD9'));
    });

    test('includes inviter, group name, deep link and store url', () {
      final text = buildStreakInviteShareText(
        inviterName: 'Ali',
        groupName: 'Family Squad',
        inviteCode: 'XYZ789',
        currentStreak: 12,
      );
      expect(text, contains('Ali invited you to join'));
      expect(text, contains('"Family Squad"'));
      expect(text, contains('Current streak: 12 days'));
      expect(text, contains('sajda://join/XYZ789'));
      expect(
        text,
        contains('https://play.google.com/store/apps/details?id=com.sajda.dataplus'),
      );
    });

    test('falls back gracefully for empty inviter/group', () {
      final text = buildStreakInviteShareText(
        inviterName: '  ',
        groupName: '',
        inviteCode: 'AAA111',
      );
      expect(text, contains('You are invited to join'));
      expect(text, contains('a Namaz Streak group'));
      expect(text, contains('AAA111'));
    });

    test('singular day for 1-day streak', () {
      final text = buildStreakInviteShareText(
        inviterName: 'S',
        groupName: 'G',
        inviteCode: 'AAA111',
        currentStreak: 1,
      );
      expect(text, contains('1 day\n'));
      expect(text, isNot(contains('1 days')));
    });
  });
}
