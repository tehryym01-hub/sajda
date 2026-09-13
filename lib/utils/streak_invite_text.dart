/// Single source of truth for group invitation share text.
/// The invite code MUST always be included — recipients cannot join without
/// it. Kept dependency-free so it is trivially unit-testable.
library;

const _kFallbackAppUrl = 'https://play.google.com/store/apps/details?id=com.sajda.dataplus';

/// Text used when sharing a group invite (from cards / share buttons).
/// Includes the deep link so recipients can jump straight into the preview.
String buildStreakInviteShareText({
  required String inviterName,
  required String groupName,
  required String inviteCode,
  int currentStreak = 0,
  String appUrl = _kFallbackAppUrl,
}) {
  final inviter = inviterName.trim().isNotEmpty ? '${inviterName.trim()} invited you to join' : 'You are invited to join';
  final code = inviteCode.trim().toUpperCase();
  final name = groupName.trim().isEmpty ? 'a Namaz Streak group' : groupName.trim();
  final streakLine =
      currentStreak > 0 ? '🔥 Current streak: $currentStreak day${currentStreak == 1 ? '' : 's'}\n' : '';
  final url = appUrl.trim().isEmpty ? _kFallbackAppUrl : appUrl.trim();
  return '$inviter "$name" 🤲\n\n'
      '$streakLine'
      'Invite Code: $code\n\n'
      'Open the app and use this code to join.\n'
      'sajda://join/$code\n'
      '$url';
}
