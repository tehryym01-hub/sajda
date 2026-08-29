import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class CustomTasbeeh {
  final String id;
  String name;
  int count;
  CustomTasbeeh({required this.id, required this.name, required this.count});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'count': count};

  factory CustomTasbeeh.fromJson(Map<String, dynamic> json) => CustomTasbeeh(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        count: (json['count'] as num?)?.toInt() ?? 33,
      );
}

class CustomTasbeehService {
  static final CustomTasbeehService instance = CustomTasbeehService._();
  CustomTasbeehService._();

  static const _kKey = 'sajda_custom_tasbeeh';

  Future<List<CustomTasbeeh>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => CustomTasbeeh.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<CustomTasbeeh> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> add(String name, int count) async {
    final list = await getAll();
    list.add(CustomTasbeeh(
      id: '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999999)}',
      name: name,
      count: count,
    ));
    await _save(list);
  }

  Future<void> update(String id, String name, int count) async {
    final list = await getAll();
    final i = list.indexWhere((e) => e.id == id);
    if (i >= 0) {
      list[i].name = name;
      list[i].count = count;
      await _save(list);
    }
  }

  Future<void> remove(String id) async {
    final list = await getAll();
    list.removeWhere((e) => e.id == id);
    await _save(list);
  }
}
