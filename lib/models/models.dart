// ---------- Utility ----------

String _s(dynamic v, [String fallback = '']) =>
    v == null ? fallback : v.toString();

int _i(dynamic v, [int fallback = 0]) => v is num ? v.toInt() : fallback;

double _d(dynamic v, [double fallback = 0]) => v is num ? v.toDouble() : fallback;

DateTime _parseDate(dynamic v, [DateTime? fallback]) {
  if (v == null) return fallback ?? DateTime.now();
  if (v is DateTime) return v;
  try {
    return DateTime.parse(v.toString());
  } catch (_) {
    return fallback ?? DateTime.now();
  }
}

bool _b(dynamic v, [bool fallback = false]) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v.toLowerCase() == 'true' || v == '1';
  return fallback;
}

// ---------- Location ----------

class LocationModel {
  final String id;
  final String city;
  final String state;
  final String country;
  final String countryCode;
  final double latitude;
  final double longitude;
  final String timezone;
  final String source; // 'GPS' | 'MANUAL'
  final bool isManual;

  const LocationModel({
    required this.id,
    required this.city,
    required this.state,
    required this.country,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.source,
    required this.isManual,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) => LocationModel(
        id: _s(json['id']),
        city: _s(json['city']),
        state: _s(json['state']),
        country: _s(json['country']),
        countryCode: _s(json['countryCode']),
        latitude: _d(json['latitude']),
        longitude: _d(json['longitude']),
        timezone: _s(json['timezone']),
        source: _s(json['source'], 'MANUAL'),
        isManual: _b(json['isManual'], true),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'city': city,
        'state': state,
        'country': country,
        'countryCode': countryCode,
        'latitude': latitude,
        'longitude': longitude,
        'timezone': timezone,
        'source': source,
        'isManual': isManual,
      };

  LocationModel copyWith({
    String? id,
    String? city,
    String? state,
    String? country,
    String? countryCode,
    double? latitude,
    double? longitude,
    String? timezone,
    String? source,
    bool? isManual,
  }) =>
      LocationModel(
        id: id ?? this.id,
        city: city ?? this.city,
        state: state ?? this.state,
        country: country ?? this.country,
        countryCode: countryCode ?? this.countryCode,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        timezone: timezone ?? this.timezone,
        source: source ?? this.source,
        isManual: isManual ?? this.isManual,
      );

  @override
  String toString() => '$city, $state, $country';
}

// ---------- Prayer ----------

class PrayerTime {
  final String name;
  final String time;
  PrayerTime(this.name, this.time);
  factory PrayerTime.fromJson(Map<String, dynamic> json) =>
      PrayerTime(_s(json['name']), _s(json['time']));
}

class HijriInfo {
  final String day;
  final String month;
  final String monthAr;
  final String year;
  final String full;
  final String fullAr;
  final int monthNumber;
  HijriInfo({
    this.day = '',
    this.month = '',
    this.monthAr = '',
    this.year = '',
    this.full = '',
    this.fullAr = '',
    this.monthNumber = 0,
  });

  factory HijriInfo.fromJson(Map<String, dynamic> json) => HijriInfo(
        day: _s(json['day']),
        month: _s(json['month']),
        monthAr: _s(json['monthAr']),
        year: _s(json['year']),
        full: _s(json['full']),
        fullAr: _s(json['fullAr']),
        monthNumber: _i(json['monthNumber']),
      );
}

class PrayerTimesResponse {
  final List<PrayerTime> prayers;
  final String date;
  final HijriInfo hijri;
  PrayerTimesResponse({required this.prayers, required this.date, required this.hijri});

  factory PrayerTimesResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['prayers'] as List? ?? [])
        .map((e) => PrayerTime.fromJson(e as Map<String, dynamic>))
        .toList();
    return PrayerTimesResponse(
      prayers: list,
      date: _s(json['date']),
      hijri: HijriInfo.fromJson(json['hijri'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class NextPrayerResponse {
  final String currentTime;
  final String name;
  final String time;
  final int totalMinutes;
  final bool isTomorrow;
  final int countdown;
  final List<PrayerTime> allPrayers;
  final HijriInfo hijri;
  NextPrayerResponse({
    required this.currentTime,
    required this.name,
    required this.time,
    required this.totalMinutes,
    required this.isTomorrow,
    required this.countdown,
    required this.allPrayers,
    required this.hijri,
  });

  factory NextPrayerResponse.fromJson(Map<String, dynamic> json) {
    final next = json['nextPrayer'] as Map<String, dynamic>? ?? {};
    return NextPrayerResponse(
      currentTime: _s(json['currentTime']),
      name: _s(next['name']),
      time: _s(next['time']),
      totalMinutes: _i(next['totalMinutes']),
      isTomorrow: _b(next['isTomorrow']),
      countdown: _i(next['countdown']),
      allPrayers: (json['allPrayers'] as List? ?? [])
          .map((e) => PrayerTime.fromJson(e as Map<String, dynamic>))
          .toList(),
      hijri: HijriInfo.fromJson(json['hijri'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class QiblaResponse {
  final int degree;
  final String direction;
  final int distance;
  QiblaResponse({required this.degree, required this.direction, required this.distance});

  factory QiblaResponse.fromJson(Map<String, dynamic> json) => QiblaResponse(
        degree: _i(json['degree']),
        direction: _s(json['direction']),
        distance: _i(json['distance']),
      );
}

// ---------- Events ----------

class EventDua {
  final String arabic;
  final String urdu;
  final String transliteration;
  EventDua({this.arabic = '', this.urdu = '', this.transliteration = ''});
  factory EventDua.fromJson(Map<String, dynamic> json) => EventDua(
        arabic: _s(json['arabic']),
        urdu: _s(json['urdu']),
        transliteration: _s(json['transliteration']),
      );
}

class IslamicEvent {
  final String id;
  final String month;
  final int monthNumber;
  final int day;
  final String titleEn;
  final String titleUr;
  final String type;
  final String descriptionEn;
  final String descriptionUr;
  final List<String> amal;
  final List<EventDua> duas;
  IslamicEvent({
    required this.id,
    required this.month,
    required this.monthNumber,
    required this.day,
    required this.titleEn,
    required this.titleUr,
    required this.type,
    required this.descriptionEn,
    required this.descriptionUr,
    required this.amal,
    required this.duas,
  });

  String title(String lang) => lang == 'ur' && titleUr.isNotEmpty ? titleUr : titleEn;
  String description(String lang) =>
      lang == 'ur' && descriptionUr.isNotEmpty ? descriptionUr : descriptionEn;

  factory IslamicEvent.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as Map<String, dynamic>? ?? {};
    final desc = json['description'] as Map<String, dynamic>? ?? {};
    return IslamicEvent(
      id: _s(json['_id']),
      month: _s(json['month']),
      monthNumber: _i(json['monthNumber']),
      day: _i(json['day']),
      titleEn: _s(title['en']),
      titleUr: _s(title['ur']),
      type: _s(json['type'], 'general'),
      descriptionEn: _s(desc['en']),
      descriptionUr: _s(desc['ur']),
      amal: (json['amal'] as List? ?? []).map((e) => e.toString()).toList(),
      duas: (json['duas'] as List? ?? [])
          .map((e) => EventDua.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EventsResponse {
  final List<IslamicEvent> events;
  final String hijriDate;
  EventsResponse({required this.events, this.hijriDate = ''});
  factory EventsResponse.fromJson(Map<String, dynamic> json) => EventsResponse(
        events: (json['events'] as List? ?? [])
            .map((e) => IslamicEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
        hijriDate: _s((json['hijriDate'] as Map<String, dynamic>? ?? {})['full']),
      );
}

// ---------- Duas ----------

class DuaModel {
  final String id;
  final String category;
  final String titleEn;
  final String titleUr;
  final String arabic;
  final String urdu;
  final String english;
  final String transliteration;
  final String reference;
  DuaModel({
    required this.id,
    required this.category,
    required this.titleEn,
    required this.titleUr,
    required this.arabic,
    required this.urdu,
    required this.english,
    required this.transliteration,
    required this.reference,
  });

  String title(String lang) => lang == 'ur' && titleUr.isNotEmpty ? titleUr : titleEn;

  factory DuaModel.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as Map<String, dynamic>? ?? {};
    return DuaModel(
      id: _s(json['_id']),
      category: _s(json['category']),
      titleEn: _s(title['en']),
      titleUr: _s(title['ur']),
      arabic: _s(json['arabic']),
      urdu: _s(json['urdu']),
      english: _s(json['english']),
      transliteration: _s(json['transliteration']),
      reference: _s(json['reference']),
    );
  }
}

// ---------- Wazifa ----------

class WazifaModel {
  final String id;
  final int dayOfYear;
  final String titleEn;
  final String titleUr;
  final String arabic;
  final String urdu;
  final String english;
  final String transliteration;
  final int count;
  final String type;
  final String benefitEn;
  final String benefitUr;
  WazifaModel({
    required this.id,
    required this.dayOfYear,
    required this.titleEn,
    required this.titleUr,
    required this.arabic,
    required this.urdu,
    required this.english,
    required this.transliteration,
    required this.count,
    required this.type,
    required this.benefitEn,
    required this.benefitUr,
  });

  String title(String lang) => lang == 'ur' && titleUr.isNotEmpty ? titleUr : titleEn;
  String benefit(String lang) => lang == 'ur' && benefitUr.isNotEmpty ? benefitUr : benefitEn;

  factory WazifaModel.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as Map<String, dynamic>? ?? {};
    final benefit = json['benefit'] as Map<String, dynamic>? ?? {};
    return WazifaModel(
      id: _s(json['_id']),
      dayOfYear: _i(json['dayOfYear']),
      titleEn: _s(title['en']),
      titleUr: _s(title['ur']),
      arabic: _s(json['arabic']),
      urdu: _s(json['urdu']),
      english: _s(json['english']),
      transliteration: _s(json['transliteration']),
      count: _i(json['count'], 1),
      type: _s(json['type'], 'dhikr'),
      benefitEn: _s(benefit['en']),
      benefitUr: _s(benefit['ur']),
    );
  }
}

// ---------- Hijri calendar ----------

class HijriDay {
  final String gregorian;
  final String day;
  final String month;
  final String monthNumber;
  final String year;
  HijriDay({
    required this.gregorian,
    required this.day,
    required this.month,
    required this.monthNumber,
    required this.year,
  });

  factory HijriDay.fromJson(Map<String, dynamic> json) {
    final h = json['hijri'] as Map<String, dynamic>? ?? {};
    return HijriDay(
      gregorian: _s(json['gregorian']),
      day: _s(h['day']),
      month: _s(h['month']),
      monthNumber: _s(h['monthNumber']),
      year: _s(h['year']),
    );
  }
}

class HijriToday {
  final String day;
  final String month;
  final String monthNumber;
  final String year;
  final String full;
  final String fullAr;
  HijriToday({
    required this.day,
    required this.month,
    required this.monthNumber,
    required this.year,
    required this.full,
    required this.fullAr,
  });

  factory HijriToday.fromJson(Map<String, dynamic> json) => HijriToday(
        day: _s(json['day']),
        month: _s(json['month']),
        monthNumber: _s(json['monthNumber']),
        year: _s(json['year']),
        full: _s(json['full']),
        fullAr: _s(json['fullAr']),
      );
}

// ---------- Salah Streak ----------

class PrayerCompletionModel {
  final String id;
  final String userId;
  final String date; // ISO date string YYYY-MM-DD in user's timezone
  final bool fajr;
  final bool dhuhr;
  final bool asr;
  final bool maghrib;
  final bool isha;
  final String timezone; // IANA timezone
  final Map<String, DateTime>? completedAt;
  final bool isComplete;

  PrayerCompletionModel({
    required this.id,
    required this.userId,
    required this.date,
    this.fajr = false,
    this.dhuhr = false,
    this.asr = false,
    this.maghrib = false,
    this.isha = false,
    required this.timezone,
    this.completedAt,
    this.isComplete = false,
  });

  int get completedCount => [fajr, dhuhr, asr, maghrib, isha].where((p) => p).length;

  factory PrayerCompletionModel.fromJson(Map<String, dynamic> json) => PrayerCompletionModel(
        id: _s(json['_id'] ?? json['id']),
        userId: _s(json['userId']),
        date: _s(json['date']),
        fajr: _b(json['fajr']),
        dhuhr: _b(json['dhuhr']),
        asr: _b(json['asr']),
        maghrib: _b(json['maghrib']),
        isha: _b(json['isha']),
        timezone: _s(json['timezone']),
        completedAt: null, // DateTime from JSON would need parsing
        isComplete: _b(json['isComplete']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'date': date,
        'fajr': fajr,
        'dhuhr': dhuhr,
        'asr': asr,
        'maghrib': maghrib,
        'isha': isha,
        'timezone': timezone,
        'completedAt': completedAt?.map((k, v) => MapEntry(k, v.toIso8601String())),
        'isComplete': isComplete,
      };

  PrayerCompletionModel copyWith({
    String? id,
    String? userId,
    String? date,
    bool? fajr,
    bool? dhuhr,
    bool? asr,
    bool? maghrib,
    bool? isha,
    String? timezone,
    Map<String, DateTime>? completedAt,
    bool? isComplete,
  }) => PrayerCompletionModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        date: date ?? this.date,
        fajr: fajr ?? this.fajr,
        dhuhr: dhuhr ?? this.dhuhr,
        asr: asr ?? this.asr,
        maghrib: maghrib ?? this.maghrib,
        isha: isha ?? this.isha,
        timezone: timezone ?? this.timezone,
        completedAt: completedAt ?? this.completedAt,
        isComplete: isComplete ?? this.isComplete,
      );
}

class StreakModel {
  final String id;
  final String userId;
  final int goalDays;
  final int currentDay;
  final int currentStreak;
  final int longestStreak;
  final DateTime startDate;
  final DateTime? endDate;
  final String status; // 'active', 'paused', 'completed', 'expired'
  final bool isShared;
  final String? sharedStreakId;
  final String? lastCompletedDate;
  final List<StreakHistoryEntry> streakHistory;

  StreakModel({
    required this.id,
    required this.userId,
    required this.goalDays,
    this.currentDay = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.startDate,
    this.endDate,
    this.status = 'active', // 'active', 'paused', 'completed', 'expired'
    this.isShared = false,
    this.sharedStreakId,
    this.lastCompletedDate,
    this.streakHistory = const [],
  });

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isPaused => status == 'paused';
  bool get isExpired => status == 'expired';

  double get progress => goalDays > 0 ? currentDay / goalDays : 0;

  factory StreakModel.fromJson(Map<String, dynamic> json) => StreakModel(
        id: _s(json['_id'] ?? json['id']),
        userId: _s(json['userId']),
        goalDays: _i(json['goalDays']),
        currentDay: _i(json['currentDay']),
        currentStreak: _i(json['currentStreak']),
        longestStreak: _i(json['longestStreak']),
        startDate: _parseDate(json['startDate']),
        endDate: json['endDate'] != null ? _parseDate(json['endDate']) : null,
        status: _s(json['status'], 'active'),
        isShared: _b(json['isShared']),
        sharedStreakId: json['sharedStreakId'] != null ? _s(json['sharedStreakId']) : null,
        lastCompletedDate: json['lastCompletedDate'] != null ? _s(json['lastCompletedDate']) : null,
        streakHistory: (json['streakHistory'] as List? ?? [])
            .map((e) => StreakHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'goalDays': goalDays,
        'currentDay': currentDay,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'status': status,
        'isShared': isShared,
        'sharedStreakId': sharedStreakId,
        'lastCompletedDate': lastCompletedDate,
        'streakHistory': streakHistory.map((e) => e.toJson()).toList(),
      };
}

class StreakHistoryEntry {
  final String date;
  final bool isComplete;
  final int prayerCounts;

  StreakHistoryEntry({
    required this.date,
    required this.isComplete,
    this.prayerCounts = 0,
  });

  factory StreakHistoryEntry.fromJson(Map<String, dynamic> json) => StreakHistoryEntry(
        date: _s(json['date']),
        isComplete: _b(json['isComplete']),
        prayerCounts: _i(json['prayerCounts']),
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'isComplete': isComplete,
        'prayerCounts': prayerCounts,
      };
}

class SharedStreakModel {
  final String id;
  final String creatorId;
  final String title;
  final int goalDays;
  final int currentDay;
  final DateTime startDate;
  final DateTime? endDate;
  final String status; // 'pending', 'active', 'completed', 'expired'
  final String inviteCode;
  final int maxMembers;
  final bool isRevoked;
  final DateTime? completedAt;

  SharedStreakModel({
    required this.id,
    required this.creatorId,
    this.title = 'Salah Streak',
    required this.goalDays,
    this.currentDay = 0,
    required this.startDate,
    this.endDate,
    this.status = 'pending', // 'pending', 'active', 'completed', 'expired'
    required this.inviteCode,
    this.maxMembers = 10,
    this.isRevoked = false,
    this.completedAt,
  });

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isExpired => status == 'expired';

  factory SharedStreakModel.fromJson(Map<String, dynamic> json) => SharedStreakModel(
        id: _s(json['_id'] ?? json['id']),
        creatorId: _s(json['creatorId']),
        title: _s(json['title'], 'Salah Streak'),
        goalDays: _i(json['goalDays']),
        currentDay: _i(json['currentDay']),
        startDate: _parseDate(json['startDate']),
        endDate: json['endDate'] != null ? _parseDate(json['endDate']) : null,
        status: _s(json['status'], 'pending'),
        inviteCode: _s(json['inviteCode']),
        maxMembers: _i(json['maxMembers'], 10),
        isRevoked: _b(json['isRevoked']),
        completedAt: json['completedAt'] != null ? _parseDate(json['completedAt']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'creatorId': creatorId,
        'title': title,
        'goalDays': goalDays,
        'currentDay': currentDay,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'status': status,
        'inviteCode': inviteCode,
        'maxMembers': maxMembers,
        'isRevoked': isRevoked,
        'completedAt': completedAt?.toIso8601String(),
      };
}

class StreakMemberModel {
  final String id;
  final String streakId;
  final String userId;
  final String displayName;
  final DateTime joinedAt;
  final String status; // 'active', 'left', 'removed'
  final int currentDay;
  final String? lastCompletedDate;
  final bool notificationOptIn;

  StreakMemberModel({
    required this.id,
    required this.streakId,
    required this.userId,
    required this.displayName,
    required this.joinedAt,
    this.status = 'active', // 'active', 'left', 'removed'
    this.currentDay = 0,
    this.lastCompletedDate,
    this.notificationOptIn = true,
  });

  bool get isActive => status == 'active';

  factory StreakMemberModel.fromJson(Map<String, dynamic> json) => StreakMemberModel(
        id: _s(json['_id'] ?? json['id']),
        streakId: _s(json['streakId']),
        userId: _s(json['userId']),
        displayName: _s(json['displayName']),
        joinedAt: _parseDate(json['joinedAt']),
        status: _s(json['status'], 'active'),
        currentDay: _i(json['currentDay']),
        lastCompletedDate: json['lastCompletedDate'] != null ? _s(json['lastCompletedDate']) : null,
        notificationOptIn: _b(json['notificationOptIn'], true),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'streakId': streakId,
        'userId': userId,
        'displayName': displayName,
        'joinedAt': joinedAt.toIso8601String(),
        'status': status,
        'currentDay': currentDay,
        'lastCompletedDate': lastCompletedDate,
        'notificationOptIn': notificationOptIn,
      };
}