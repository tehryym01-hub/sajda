import '../data/azkar_data.dart';

class ZikrItem {
  final int id;
  final String text;
  final int count;
  final String audio;
  ZikrItem({required this.id, required this.text, required this.count, required this.audio});

  factory ZikrItem.fromJson(Map<String, dynamic> json) => ZikrItem(
        id: (json['id'] as num?)?.toInt() ?? 0,
        text: json['text']?.toString() ?? '',
        count: (json['count'] as num?)?.toInt() ?? 1,
        audio: json['audio']?.toString() ?? '',
      );
}

class ZikrCategory {
  final int id;
  final String category;
  final String audio;
  final List<ZikrItem> items;
  ZikrCategory({
    required this.id,
    required this.category,
    required this.audio,
    required this.items,
  });

  factory ZikrCategory.fromJson(Map<String, dynamic> json) => ZikrCategory(
        id: (json['id'] as num?)?.toInt() ?? 0,
        category: json['category']?.toString() ?? '',
        audio: json['audio']?.toString() ?? '',
        items: ((json['array'] as List?) ?? [])
            .map((e) => ZikrItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

List<ZikrCategory> get adhkarCategories =>
    azkar.map((e) => ZikrCategory.fromJson(e as Map<String, dynamic>)).toList();