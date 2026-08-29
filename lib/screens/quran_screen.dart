import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/quran_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'mushaf_screen.dart';
import 'quran_search_screen.dart';
import 'surah_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  late final List<SurahInfo> _surahs = QuranService.instance.surahs;
  String _query = '';

  List<SurahInfo> get _filtered {
    if (_query.isEmpty) return _surahs;
    final q = _query.toLowerCase();
    return _surahs.where((s) =>
        s.nameEn.toLowerCase().contains(q) ||
        s.nameAr.contains(_query) ||
        s.number.toString() == _query.trim()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final filtered = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: Text(state.t('Al-Quran', 'قرآن مجید')),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MushafScreen()),
            ),
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: state.t('Mushaf', 'مصحف'),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QuranSearchScreen()),
            ),
            icon: const Icon(Icons.search_rounded),
            tooltip: state.t('Search Quran', 'قرآن میں تلاش'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: state.t('Search surah...', 'سورہ تلاش کریں...'),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() => _query = ''),
                      ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: filtered.length + (state.quranLastSurah > 0 ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (state.quranLastSurah > 0 && i == 0) {
                  final surah = QuranService.instance.surah(state.quranLastSurah);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SurahScreen(
                            surah: surah,
                            initialVerse: state.quranLastAyah,
                          ),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryDeep, AppColors.primary],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.play_circle_outline_rounded, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(state.t('Continue Reading', 'پڑھنا جاری رکھیں'),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                  Text('${surah.nameEn} • ${state.t('Ayah', 'آیت')} ${state.quranLastAyah}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                final s = filtered[i - (state.quranLastSurah > 0 ? 1 : 0)];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    onTap: () async {
                      await state.setQuranPosition(s.number, 1);
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SurahScreen(surah: s),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.primary, AppColors.primaryDeep],
                            ),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${s.number}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.nameEn,
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${s.ayahCount} ${state.t('verses', 'آیات')} • ${state.t(s.revelation, s.revelation)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          s.nameAr,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}