/// Shared 12-hour time formatting — azan-style display everywhere.
/// Internal parsing/scheduling stays on 24h "HH:mm" strings; only the UI
/// shows these converted values.
library;

/// "16:45" -> "4:45 PM" | "00:15" -> "12:15 AM" | "12:30" -> "12:30 PM".
/// Returns the input unchanged when it cannot be parsed (defensive — a
/// malformed time must never render as an empty string in the UI).
String formatTime12(String? hhmm) {
  final raw = (hhmm ?? '').trim();
  if (raw.isEmpty) return raw;
  final parts = raw.split(':');
  if (parts.length < 2) return raw;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) return raw;
  final suffix = h >= 12 ? 'PM' : 'AM';
  final hour12 = h % 12 == 0 ? 12 : h % 12;
  return '$hour12:${m.toString().padLeft(2, '0')} $suffix';
}
