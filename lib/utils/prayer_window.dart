import '../models/models.dart';

/// Per-prayer END (qaza) boundaries — an app convention users actually
/// pray by: Fajr ends at SUNRISE (not at Zuhr), Zuhr at Asr, Asr at
/// Maghrib, Maghrib at Isha, and Isha at tomorrow's Fajr.
class PrayerWindow {
  /// The prayer whose time is currently ACTIVE (started, not yet over).
  /// Null in the gaps — e.g. between sunrise and Zuhr.
  final PrayerTime? current;

  /// When the current prayer's window started.
  final DateTime? currentStart;

  /// When the current prayer's time ends (qaza boundary).
  final DateTime? currentEnd;

  /// The next upcoming prayer.
  final PrayerTime next;

  /// When the next prayer starts.
  final DateTime nextStart;

  /// True when the next prayer is tomorrow's Fajr.
  final bool nextIsTomorrow;

  const PrayerWindow({
    this.current,
    this.currentStart,
    this.currentEnd,
    required this.next,
    required this.nextStart,
    required this.nextIsTomorrow,
  });
}

DateTime? _dt(DateTime base, PrayerTime? p, {int dayOffset = 0}) {
  if (p == null) return null;
  final parts = p.time.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return DateTime(base.year, base.month, base.day + dayOffset, h, m);
}

PrayerTime? _find(List<PrayerTime> prayers, String name) {
  for (final p in prayers) {
    if (p.name == name) return p;
  }
  return null;
}

/// Computes the active window + next prayer from a day's prayer list.
PrayerWindow? computePrayerWindow(List<PrayerTime> prayers, DateTime now) {
  final fajrP = _find(prayers, 'Fajr');
  final sunriseP = _find(prayers, 'Sunrise');
  final dhuhrP = _find(prayers, 'Dhuhr');
  final asrP = _find(prayers, 'Asr');
  final maghribP = _find(prayers, 'Maghrib');
  final ishaP = _find(prayers, 'Isha');
  if (fajrP == null) return null;

  final fajr = _dt(now, fajrP)!;
  final sunrise = _dt(now, sunriseP);
  final dhuhr = _dt(now, dhuhrP);
  final asr = _dt(now, asrP);
  final maghrib = _dt(now, maghribP);
  final isha = _dt(now, ishaP);
  final fajrTomorrow = fajr.add(const Duration(days: 1));

  // Qaza boundaries. Missing Sunrise falls back to Dhuhr.
  final fajrEnd = sunrise ?? dhuhr;

  final entries = <(PrayerTime, DateTime, DateTime)>[
    if (fajrEnd != null) (fajrP, fajr, fajrEnd),
    if (dhuhr != null && asr != null && dhuhrP != null) (dhuhrP, dhuhr, asr),
    if (asr != null && maghrib != null && asrP != null) (asrP, asr, maghrib),
    if (maghrib != null && isha != null && maghribP != null) (maghribP, maghrib, isha),
    if (isha != null && ishaP != null) (ishaP, isha, fajrTomorrow),
    // Yesterday's Isha covers the pre-Fajr part of the night.
    if (isha != null && ishaP != null)
      (ishaP, isha.subtract(const Duration(days: 1)), fajr),
  ];

  PrayerTime? active;
  DateTime? activeStart;
  DateTime? activeEnd;
  for (final (p, start, end) in entries) {
    if (!now.isBefore(start) && now.isBefore(end)) {
      active = p;
      activeStart = start;
      activeEnd = end;
      break;
    }
  }

  // Next upcoming prayer among today's five, else tomorrow's Fajr.
  PrayerTime nextP = fajrP;
  DateTime nextStart = fajrTomorrow;
  bool tomorrow = true;
  for (final (p, start, _) in entries.take(5)) {
    if (now.isBefore(start)) {
      nextP = p;
      nextStart = start;
      tomorrow = false;
      break;
    }
  }

  return PrayerWindow(
    current: active,
    currentStart: activeStart,
    currentEnd: activeEnd,
    next: nextP,
    nextStart: nextStart,
    nextIsTomorrow: tomorrow,
  );
}
