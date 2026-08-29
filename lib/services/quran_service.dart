import 'dart:convert';

import 'package:quran/quran.dart' as q;
import 'package:shared_preferences/shared_preferences.dart';

class SurahInfo {
  final int number;
  final String nameAr;
  final String nameEn;
  final int ayahCount;
  final String revelation;
  SurahInfo({
    required this.number,
    required this.nameAr,
    required this.nameEn,
    required this.ayahCount,
    required this.revelation,
  });
}

class SearchResult {
  final int surah;
  final int ayah;
  final String arabic;
  final String english;
  final String urdu;
  SearchResult({
    required this.surah,
    required this.ayah,
    required this.arabic,
    this.english = '',
    this.urdu = '',
  });

  String translation(String lang) {
    if (lang == 'ur' && urdu.isNotEmpty) return urdu;
    if (lang == 'en' && english.isNotEmpty) return english;
    return english.isNotEmpty ? english : urdu;
  }
}

class ReciterChoice {
  final String code;
  final String name;
  const ReciterChoice(this.code, this.name);
}

class QuranService {
  static final QuranService instance = QuranService._();
  QuranService._();

  static const _kBookmarks = 'sajda_quran_bookmarks';
  static const _kDailyAyah = 'sajda_daily_ayah';

  /// Deterministic verse-of-the-day: changes at midnight, shared across devices.
  Future<SearchResult?> dailyAyah({bool forceNew = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dayKey = '${now.year}-${now.month}-${now.day}';
    final saved = prefs.getString(_kDailyAyah);
    if (!forceNew && saved != null && saved.startsWith('$dayKey|')) {
      final parts = saved.split('|');
      return _result(int.parse(parts[1]), int.parse(parts[2]));
    }
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    final (s, v) = ayahForDay(dayOfYear);
    final res = _result(s, v);
    await prefs.setString(_kDailyAyah, '$dayKey|$s|$v');
    return res;
  }

  /// Returns the (surah, ayah) for a given day of the year.
  static (int, int) ayahForDay(int dayOfYear) {
    final index = dayOfYear % 6236;
    var remaining = index;
    for (var s = 1; s <= 114; s++) {
      final count = q.getVerseCount(s);
      if (remaining < count) {
        return (s, remaining + 1);
      }
      remaining -= count;
    }
    return (1, 1);
  }

  SearchResult _result(int surah, int ayah) {
    final arabic = q.getVerse(surah, ayah);
    return SearchResult(
      surah: surah,
      ayah: ayah,
      arabic: arabic,
      english: '',
      urdu: '',
    );
  }

  static const List<ReciterChoice> reciters = [
    ReciterChoice('ar.alafasy', 'Mishary Alafasy'),
    ReciterChoice('ar.husary', 'Mahmoud Al-Husary'),
    ReciterChoice('ar.ahmedajamy', 'Ahmed Al-Ajamy'),
    ReciterChoice('ar.hudhaify', 'Ali Al-Hudhaify'),
    ReciterChoice('ar.mahermuaiqly', 'Maher Al-Muaiqly'),
    ReciterChoice('ar.muhammadayyoub', 'Muhammad Ayyoub'),
    ReciterChoice('ar.muhammadjibreel', 'Muhammad Jibreel'),
    ReciterChoice('ar.minshawi', 'Minshawi'),
    ReciterChoice('ar.shaatree', 'Abu Bakr Ash-Shaatree'),
  ];

  List<SurahInfo> get surahs {
    return List.generate(114, (i) {
      final n = i + 1;
      return SurahInfo(
        number: n,
        nameAr: q.getSurahNameArabic(n),
        nameEn: q.getSurahNameEnglish(n),
        ayahCount: q.getVerseCount(n),
        revelation: q.getPlaceOfRevelation(n),
      );
    });
  }

  SurahInfo surah(int number) => surahs[number - 1];

  String verseArabic(int surah, int ayah) => q.getVerse(surah, ayah);

  String verseTranslation(int surah, int ayah, {bool urdu = false}) => '';

  String surahAudioUrl(int surah, String reciterCode) =>
      '';

  String verseAudioUrl(int surah, int ayah, String reciterCode) =>
      '';

  List<SearchResult> search(String query, {bool urdu = false}) {
    final qry = query.trim().toLowerCase();
    if (qry.isEmpty) return const [];
    final results = <SearchResult>[];
    for (var s = 1; s <= 114 && results.length < 200; s++) {
      final count = q.getVerseCount(s);
      for (var v = 1; v <= count; v++) {
        final txt = q.getVerse(s, v);
        if (txt.toLowerCase().contains(qry)) {
          results.add(SearchResult(
            surah: s,
            ayah: v,
            arabic: txt,
            english: '',
            urdu: '',
          ));
          if (results.length >= 200) break;
        }
      }
    }
    return results;
  }

  // ---------- Bookmarks ----------

  Future<Set<String>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kBookmarks);
    if (raw == null) return {};
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> toggleBookmark(int surah, int ayah) async {
    final key = '$surah:$ayah';
    final prefs = await SharedPreferences.getInstance();
    final set = await getBookmarks();
    if (!set.add(key)) set.remove(key);
    await prefs.setString(_kBookmarks, jsonEncode(set.toList()));
  }

  String surahNameWithNumber(int surah) =>
      '$surah. ${q.getSurahNameEnglish(surah)}';
}

