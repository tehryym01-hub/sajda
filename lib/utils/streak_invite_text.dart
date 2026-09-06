/// Single source of truth for streak invitation share text.
/// The invite code MUST always be included — recipients cannot join without it.
/// Kept dependency-free so it is trivially unit-testable.
library;

const _kFallbackAppUrl = 'https://play.google.com/store/apps/details?id=com.sajda.dataplus';

/// Text used when sharing a streak invite (from cards / share buttons).
String buildStreakInviteShareText({
  required String streakTitle,
  required String inviteCode,
  String appUrl = _kFallbackAppUrl,
  String? inviterName,
}) {
  final inviter = (inviterName != null && inviterName.trim().isNotEmpty)
      ? '${inviterName.trim()} invited you to join'
      : 'You are invited to join';
  final code = inviteCode.trim();
  final title = streakTitle.trim().isEmpty ? 'Namaz Streak' : streakTitle.trim();
  return '$inviter $title 🤲\n\n'
      'Invite Code: $code\n\n'
      'Open the app and use this code to join.\n'
      '${appUrl.trim().isEmpty ? _kFallbackAppUrl : appUrl.trim()}';
}

/// Composes the full message for the "share streak" API payload
/// (server-provided shareText + invite code + URL).
String buildStreakShareMessage({
  required String shareText,
  required String inviteCode,
  required String inviteUrl,
}) {
  var message = shareText.trim();
  final code = inviteCode.trim();
  final url = inviteUrl.trim();
  if (code.isNotEmpty) {
    message = message.isEmpty ? 'Invite Code: $code' : '$message\n\n🎯 Invite Code: $code';
  }
  if (url.isNotEmpty) {
    message = message.isEmpty ? url : '$message\n\n$url';
  }
  return message;
}
