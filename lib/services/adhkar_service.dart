import 'package:flutter/foundation.dart';

import '../models/azkar_model.dart';
import 'api_client.dart';

/// Adhkar content repository.
///
/// The bundled Hisnul Muslim dataset (Arabic) loads instantly and is the
/// source of truth for text/count/audio. Server-side translations
/// (ur / en / hi / id) are fetched once per session and merged on top —
/// the UI rebuilds via [notifyListeners] with no screen reload. Offline
/// or backend failure simply keeps the bundled Arabic working.
class AdhkarService extends ChangeNotifier {
  AdhkarService._();
  static final AdhkarService instance = AdhkarService._();

  List<ZikrCategory> _categories = adhkarCategories;
  bool _fetched = false;
  bool _inFlight = false;

  List<ZikrCategory> get categories => _categories;
  bool get translationsLoaded => _fetched;

  ZikrCategory? byId(int id) {
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> ensureTranslations() async {
    if (_fetched || _inFlight) return;
    _inFlight = true;
    try {
      final remote = await ApiClient.instance.getAdhkar();
      if (remote.isNotEmpty) {
        final remoteById = {for (final c in remote) c.id: c};
        _categories = [
          for (final c in _categories) _mergeCategory(c, remoteById[c.id]),
        ];
        _fetched = true;
        notifyListeners();
      }
    } catch (_) {
      // Offline / backend unavailable → bundled Arabic keeps working.
    } finally {
      _inFlight = false;
    }
  }

  ZikrCategory _mergeCategory(ZikrCategory base, ZikrCategory? remote) {
    if (remote == null) return base;
    final hasTranslations = !remote.translations.isEmpty ||
        remote.items.any((i) => !i.translations.isEmpty);
    if (!hasTranslations) return base;
    final itemsById = {for (final i in remote.items) i.id: i};
    return base.withTranslations(
      remote.translations,
      [for (final item in base.items) _mergeItem(item, itemsById[item.id])],
    );
  }

  ZikrItem _mergeItem(ZikrItem base, ZikrItem? remote) {
    if (remote == null || remote.translations.isEmpty) return base;
    return base.withTranslations(remote.translations);
  }
}
