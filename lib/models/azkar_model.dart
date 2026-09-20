import '../data/azkar_data.dart';

/// Multi-language translations overlay for adhkar content. Arabic text in
/// [ZikrItem.text] / [ZikrCategory.category] always remains the source of
/// truth; these are server-provided renderings (ur / en / hi / id).
class ZikrTranslations {
  final String ur;
  final String en;
  final String hi;
  final String id;
  const ZikrTranslations({this.ur = '', this.en = '', this.hi = '', this.id = ''});

  static const empty = ZikrTranslations();

  bool get isEmpty => ur.isEmpty && en.isEmpty && hi.isEmpty && id.isEmpty;

  /// Returns the translation for [code], or null when missing.
  /// Only ur / en / hi / id are supported.
  String? forLang(String code) {
    switch (code) {
      case 'ur':
        return ur.isEmpty ? null : ur;
      case 'en':
        return en.isEmpty ? null : en;
      case 'hi':
        return hi.isEmpty ? null : hi;
      case 'id':
        return id.isEmpty ? null : id;
    }
    return null;
  }

  factory ZikrTranslations.fromJson(Map<String, dynamic>? json) => ZikrTranslations(
        ur: json?['ur']?.toString() ?? '',
        en: json?['en']?.toString() ?? '',
        hi: json?['hi']?.toString() ?? '',
        id: json?['id']?.toString() ?? '',
      );
}

class ZikrItem {
  final int id;
  final String text;
  final int count;
  final String audio;
  final ZikrTranslations translations;
  ZikrItem({
    required this.id,
    required this.text,
    required this.count,
    required this.audio,
    this.translations = ZikrTranslations.empty,
  });

  /// Text for the selected content language. Falls back to the original
  /// Arabic text when no translation exists yet.
  String textFor(String lang) {
    if (lang == 'ar') return text;
    return translations.forLang(lang) ?? text;
  }

  bool hasTranslation(String lang) => lang != 'ar' && translations.forLang(lang) != null;

  ZikrItem withTranslations(ZikrTranslations t) => ZikrItem(
        id: id,
        text: text,
        count: count,
        audio: audio,
        translations: t,
      );

  factory ZikrItem.fromJson(Map<String, dynamic> json) => ZikrItem(
        id: (json['id'] as num?)?.toInt() ?? 0,
        text: json['text']?.toString() ?? '',
        count: (json['count'] as num?)?.toInt() ?? 1,
        audio: json['audio']?.toString() ?? '',
        translations: ZikrTranslations.fromJson(json['translations'] as Map<String, dynamic>?),
      );
}

class ZikrCategory {
  final int id;
  final String category;
  final String audio;
  final List<ZikrItem> items;
  final ZikrTranslations translations;
  ZikrCategory({
    required this.id,
    required this.category,
    required this.audio,
    required this.items,
    this.translations = ZikrTranslations.empty,
  });

  /// Category title for the selected content language; falls back to Arabic.
  String nameFor(String lang) {
    if (lang == 'ar') return category;
    return translations.forLang(lang) ?? category;
  }

  bool hasTranslation(String lang) => lang != 'ar' && translations.forLang(lang) != null;

  ZikrCategory withTranslations(ZikrTranslations t, List<ZikrItem> newItems) => ZikrCategory(
        id: id,
        category: category,
        audio: audio,
        items: newItems,
        translations: t,
      );

  factory ZikrCategory.fromJson(Map<String, dynamic> json) => ZikrCategory(
        id: (json['id'] as num?)?.toInt() ?? 0,
        category: json['category']?.toString() ?? '',
        audio: json['audio']?.toString() ?? '',
        translations: ZikrTranslations.fromJson(json['translations'] as Map<String, dynamic>?),
        // Bundled dataset uses "array"; the backend model uses "items".
        items: (((json['array'] ?? json['items']) as List?) ?? const [])
            .map((e) => ZikrItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

List<ZikrCategory> get adhkarCategories =>
    azkar.map((e) => ZikrCategory.fromJson(e as Map<String, dynamic>)).toList();
