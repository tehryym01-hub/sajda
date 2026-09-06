import 'package:hijri/hijri_calendar.dart';

import 'date_service.dart';

/// Local Hijri date calculation service using Umm al-Qura algorithm.
///
/// Islamic-day rule (IMPORTANT):
/// The Islamic day begins at Maghrib (sunset), NOT at Gregorian midnight.
/// Therefore, for TODAY:
///   * before Maghrib            -> Hijri date of the current Gregorian day
///   * at/after today's Maghrib  -> Hijri date of the NEXT Gregorian day
/// Arbitrary past/future dates (calendar rendering, events) convert plainly
/// without any shift.
///
/// [maghribTime] allows callers that already fetched real prayer times to pass
/// the exact Maghrib for the selected location. When omitted, a documented
/// conservative approximation of 18:30 local is used — this only affects the
/// boundary moment, never the date math itself.
class HijriDateService {
  static const arabicMonths = [
    'محرم', 'صفر', 'ربيع الأول', 'ربيع الثاني', 'جمادى الأولى', 'جمادى الآخرة',
    'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
  ];

  static const englishMonths = [
    'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani',
    'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', 'Sha\'ban',
    'Ramadan', 'Shawwal', 'Dhu al-Qi\'dah', 'Dhu al-Hijjah',
  ];

  /// Default Maghrib approximation when no real prayer time is available.
  static const _defaultMaghribHour = 18;
  static const _defaultMaghribMinute = 30;

  /// Plain Gregorian -> Hijri conversion with NO Maghrib shift.
  /// Exposed publicly so tests can assert against the raw conversion.
  static HijriDateInfo convertPlain(DateTime gregorian) {
    HijriCalendar.language = 'en';
    final dateOnly =
        DateTime(gregorian.year, gregorian.month, gregorian.day);
    final calendar = HijriCalendar.fromDate(dateOnly);
    final weekday = calendar.wkDay ?? calendar.weekDay();
    return HijriDateInfo(
      day: calendar.hDay,
      month: calendar.hMonth,
      year: calendar.hYear,
      monthEn: englishMonths[calendar.hMonth - 1],
      monthAr: arabicMonths[calendar.hMonth - 1],
      weekdayEn: _weekdayEn(weekday),
      weekdayAr: _weekdayAr(weekday),
    );
  }

  /// Hijri date for [gregorian], applying the Maghrib day-boundary rule when
  /// [gregorian] is today in [locationTimezone].
  static HijriDateInfo getHijriDate(
    DateTime gregorian, {
    String? locationTimezone,
    DateTime? maghribTime,
  }) {
    final tz = locationTimezone;
    final isToday = dateService.isToday(gregorian, timezone: tz);

    if (!isToday) {
      return convertPlain(gregorian);
    }

    final now = DateTime.now();
    final effectiveMaghrib = maghribTime ??
        DateTime(gregorian.year, gregorian.month, gregorian.day,
            _defaultMaghribHour, _defaultMaghribMinute);

    if (!now.isBefore(effectiveMaghrib)) {
      // After Maghrib -> Islamic day has advanced to tomorrow.
      final nextDay = DateTime(gregorian.year, gregorian.month, gregorian.day)
          .add(const Duration(days: 1));
      return convertPlain(nextDay);
    }
    return convertPlain(gregorian);
  }

  /// Hijri date for today (Maghrib-aware).
  static HijriDateInfo getTodayHijri({
    String? locationTimezone,
    DateTime? maghribTime,
  }) {
    return getHijriDate(
      DateTime.now(),
      locationTimezone: locationTimezone,
      maghribTime: maghribTime,
    );
  }

  static String _weekdayEn(int weekday) {
    // weekday: 1=Monday ... 7=Sunday (from HijriCalendar.weekDay())
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  static String _weekdayAr(int weekday) {
    const days = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    return days[weekday - 1];
  }
}

class HijriDateInfo {
  final int day;
  final int month;
  final int year;
  final String monthEn;
  final String monthAr;
  final String weekdayEn;
  final String weekdayAr;

  HijriDateInfo({
    required this.day,
    required this.month,
    required this.year,
    required this.monthEn,
    required this.monthAr,
    required this.weekdayEn,
    required this.weekdayAr,
  });

  String get full => '$day $monthEn $year AH';
  String get fullAr => '$day $monthAr $year هـ';
  String get fullWithWeekday => '$weekdayEn, $day $monthEn $year AH';
  String get fullWithWeekdayAr => '$weekdayAr، $day $monthAr $year هـ';

  Map<String, dynamic> toJson() => {
    'day': day,
    'month': month,
    'monthEn': monthEn,
    'monthAr': monthAr,
    'year': year,
    'weekdayEn': weekdayEn,
    'weekdayAr': weekdayAr,
    'full': full,
    'fullAr': fullAr,
  };
}
