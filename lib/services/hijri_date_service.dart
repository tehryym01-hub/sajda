import 'package:hijri/hijri_calendar.dart';

/// Local Hijri date calculation service using Umm al-Qura algorithm (Saudi Arabia official).
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

  /// Get Hijri date for a given Gregorian date.
  /// Uses Umm al-Qura (Saudi Arabia) calculation method via hijri package.
  static HijriDateInfo getHijriDate(DateTime gregorian) {
    HijriCalendar.language = 'en';
    final dateOnly = DateTime(gregorian.year, gregorian.month, gregorian.day).subtract(const Duration(days: 1));
    final calendar = HijriCalendar.fromDate(dateOnly);
    
    return HijriDateInfo(
      day: calendar.hDay,
      month: calendar.hMonth,
      year: calendar.hYear,
      monthEn: englishMonths[calendar.hMonth - 1],
      monthAr: arabicMonths[calendar.hMonth - 1],
      weekdayEn: _weekdayEn(calendar.wkDay ?? calendar.weekDay()),
      weekdayAr: _weekdayAr(calendar.wkDay ?? calendar.weekDay()),
    );
  }

  /// Get Hijri date for today.
  static HijriDateInfo getTodayHijri() {
    return getHijriDate(DateTime.now());
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