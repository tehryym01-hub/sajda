import 'package:flutter_test/flutter_test.dart';

import 'package:sajda_dataplus/models/streak_v2.dart';
import 'package:sajda_dataplus/services/api_client.dart';
import 'package:sajda_dataplus/services/streak_v2_api.dart';

void main() {
  group('SoloStreakData', () {
    test('parses an active solo streak', () {
      final s = SoloStreakData.fromJson({
        'started': true,
        'currentStreak': 7,
        'bestStreak': 21,
        'currentStreakStartDate': '20260901',
        'lastCompletedDay': '20260906',
        'today': {
          'fajr': true,
          'dhuhr': true,
          'asr': false,
          'maghrib': false,
          'isha': false,
          'completedCount': 2,
          'isDayComplete': false,
        },
      });
      expect(s.started, isTrue);
      expect(s.currentStreak, 7);
      expect(s.bestStreak, 21);
      expect(s.today.completedCount, 2);
      expect(s.today.of('fajr'), isTrue);
      expect(s.today.of('asr'), isFalse);
      expect(s.today.isDayComplete, isFalse);
    });

    test('parses the not-started shape', () {
      final s = SoloStreakData.fromJson({
        'started': false,
        'today': {'completedCount': 0, 'isDayComplete': false},
      });
      expect(s.started, isFalse);
      expect(s.currentStreak, 0);
      expect(s.today.completedCount, 0);
    });

    test('optimistic withPrayer flips count in both directions', () {
      const base = DayProgress(
        fajr: true,
        dhuhr: true,
        completedCount: 2,
      );
      final afterThird = base.withPrayer('asr', true);
      expect(afterThird.completedCount, 3);
      expect(afterThird.of('asr'), isTrue);
      final reverted = afterThird.withPrayer('asr', false);
      expect(reverted.completedCount, 2);
      expect(reverted.of('asr'), isFalse);
      // Re-toggling an already-done prayer (server is authoritative, this is
      // just optimistic state) keeps the count consistent.
      final reflip = base.withPrayer('fajr', true);
      expect(reflip.completedCount, 2);
    });

    test('day completes at 5/5', () {
      DayProgress p = const DayProgress();
      for (final prayer in ['fajr', 'dhuhr', 'asr', 'maghrib']) {
        p = p.withPrayer(prayer, true);
        expect(p.isDayComplete, isFalse);
      }
      p = p.withPrayer('isha', true);
      expect(p.completedCount, 5);
      expect(p.isDayComplete, isTrue);
    });
  });

  group('GroupSummary', () {
    test('parses group list item with nested today/myToday', () {
      final g = GroupSummary.fromJson({
        'groupId': 'grp_abc1234567',
        'name': 'Family',
        'status': 'active',
        'visibility': 'invite',
        'timezone': 'Asia/Karachi',
        'memberCount': 3,
        'role': 'member',
        'currentStreak': 4,
        'bestStreak': 9,
        'myToday': {'completedCount': 5, 'isDayComplete': true, 'eligible': true},
        'today': {'required': 3, 'completed': 2, 'isGroupDayComplete': false},
        'isOwner': false,
      });
      expect(g.groupId, 'grp_abc1234567');
      expect(g.memberCount, 3);
      expect(g.myTodayCount, 5);
      expect(g.myTodayComplete, isTrue);
      expect(g.completedToday, 2);
      expect(g.requiredToday, 3);
      expect(g.groupDayComplete, isFalse);
      expect(g.archived, isFalse);
    });

    test('archived flag from status', () {
      final g = GroupSummary.fromJson({'groupId': 'g', 'name': 'n', 'status': 'archived'});
      expect(g.archived, isTrue);
    });
  });

  group('GroupDashboardData', () {
    test('parses full dashboard payload', () {
      final d = GroupDashboardData.fromJson({
        'group': {
          'groupId': 'grp_x',
          'name': 'Brothers',
          'status': 'active',
          'visibility': 'public',
          'timezone': 'Asia/Riyadh',
          'memberCount': 2,
          'inviteCode': 'QW3RTY',
          'currentStreak': 2,
          'bestStreak': 5,
          'isOwner': true,
          'myRole': 'owner',
          'dateKey': '20260907',
        },
        'members': [
          {
            'userId': 'u1',
            'displayName': 'Me',
            'role': 'owner',
            'eligible': true,
            'completedCount': 4,
            'isDayComplete': false,
            'isMe': true,
          },
          {
            'userId': 'u2',
            'displayName': 'Bro',
            'role': 'member',
            'eligible': true,
            'completedCount': 5,
            'isDayComplete': true,
            'isMe': false,
          },
        ],
        'today': {'required': 2, 'completed': 9, 'isGroupDayComplete': false},
        'activity': [
          {
            '_id': 'a1',
            'groupId': 'grp_x',
            'userId': 'u2',
            'displayName': 'Bro',
            'type': 'prayer_completed',
            'prayer': 'fajr',
            'createdAt': '2026-09-07T04:30:00.000Z',
          },
        ],
      });
      expect(d.group.inviteCode, 'QW3RTY');
      expect(d.group.isOwner, isTrue);
      expect(d.members.length, 2);
      expect(d.members.first.isMe, isTrue);
      expect(d.members.last.isDayComplete, isTrue);
      expect(d.completed, 9);
      expect(d.needed, 2);
      expect(d.activity.length, 1);
      expect(d.activity.first.prayer, 'fajr');
    });
  });

  group('InvitePreview', () {
    test('parses nested group + viewerState', () {
      final p = InvitePreview.fromJson({
        'group': {
          'groupId': 'grp_v',
          'name': 'Viewers',
          'currentStreak': 3,
          'memberCount': 4,
          'maxMembers': 50,
          'visibility': 'invite',
          'timezone': 'Asia/Karachi',
          'ownerName': 'Sara',
        },
        'inviteCode': 'PREV13',
        'viewerState': 'none',
      });
      expect(p.groupId, 'grp_v');
      expect(p.name, 'Viewers');
      expect(p.ownerName, 'Sara');
      expect(p.inviteCode, 'PREV13');
      expect(p.viewerState, 'none');
      expect(p.maxMembers, 50);
    });
  });

  group('HistoryData / MonthDay', () {
    test('parses month calendar', () {
      final h = HistoryData.fromJson({
        'year': 2026,
        'month': 9,
        'currentStreak': 2,
        'bestStreak': 10,
        'calendar': [
          {'dateKey': '20260901', 'day': 1, 'state': 'complete'},
          {'dateKey': '20260902', 'day': 2, 'state': 'missed'},
          {'dateKey': '20260907', 'day': 7, 'state': 'today'},
          {'dateKey': '20260908', 'day': 8, 'state': 'future'},
        ],
      });
      expect(h.year, 2026);
      expect(h.month, 9);
      expect(h.calendar.length, 4);
      expect(h.calendar[0].state, 'complete');
      expect(h.calendar[1].state, 'missed');
      expect(h.calendar[2].state, 'today');
      expect(h.calendar[3].state, 'future');
    });
  });

  group('ApiException', () {
    test('auth and network detection', () {
      final auth = ApiException('expired', code: 'TOKEN_EXPIRED', status: 401);
      expect(auth.isAuthError, isTrue);
      expect(auth.isNetworkError, isFalse);

      final net = ApiException('Connection refused');
      expect(net.isAuthError, isFalse);
      expect(net.isNetworkError, isTrue);
    });
  });

  group('JoinResult / GroupTouch', () {
    test('parses join response', () {
      final j = JoinResult(
        alreadyMember: true,
        groupId: 'grp_j',
        name: 'J',
        message: 'already a member',
      );
      expect(j.alreadyMember, isTrue);
      expect(j.groupId, 'grp_j');
    });

    test('parses fan-out group touch', () {
      final t = GroupTouch.fromJson({'groupId': 'grp_t', 'name': 'T', 'dateKey': '20260907', 'currentStreak': 3});
      expect(t.currentStreak, 3);
      expect(t.dateKey, '20260907');
    });
  });
}
