import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as q;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/quran_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

const _kLastPage = 'sajda_last_page';

class _MushafAyah {
  final String text;
  final int surahNumber;
  final int juz;
  const _MushafAyah({required this.text, required this.surahNumber, required this.juz});
}

String _arabicNumeral(int n) {
  const ar = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return n.toString().split('').map((c) => ar[int.parse(c)]).join();
}

class MushafScreen extends StatefulWidget {
  final int? initialPage;
  const MushafScreen({super.key, this.initialPage});

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  late final PageController _controller;
  int _page = 1;

  List<_MushafAyah> _buildAyahsForPage(int page) {
    final result = <_MushafAyah>[];
    final pageData = q.getPageData(page);
    for (final entry in pageData) {
      final surah = entry['surah'] as int;
      final start = entry['start'] as int;
      final end = entry['end'] as int;
      for (var ayah = start; ayah <= end; ayah++) {
        final text = q.getVerse(surah, ayah);
        final juz = q.getJuzNumber(surah, ayah);
        result.add(_MushafAyah(text: text, surahNumber: surah, juz: juz));
      }
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage ?? 1;
    _controller = PageController(initialPage: _page - 1);
    _restoreLastPage();
  }

  Future<void> _restoreLastPage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_kLastPage);
    if (saved != null && saved != widget.initialPage) {
      setState(() {
        _page = saved;
        _controller.jumpToPage(saved - 1);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveLastPage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastPage, _page);
  }

  void _jumpToPage(int p) {
    setState(() {
      _page = p;
      _controller.jumpToPage(p - 1);
    });
    _saveLastPage();
  }

  void _openGoToDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B211A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        var value = _page.toDouble();
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Provider.of<AppState>(ctx).t('Go to Page', 'صفحہ پر جائیں'),
                    style: const TextStyle(
                        color: Color(0xFFF4EDDC),
                        fontSize: 16,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _arabicNumeral(value.round()),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Slider(
                    min: 1,
                    max: 604,
                    value: value,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setSheet(() => value = v),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _jumpToPage(value.round());
                    },
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(Provider.of<AppState>(ctx)
                        .t('Open Page', 'صفحہ کھولیں')),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F1DE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F1DE),
        foregroundColor: const Color(0xFF12352B),
        title: Text(
          Provider.of<AppState>(context).t('Mushaf', 'مصحف'),
        ),
        actions: [
          IconButton(
            onPressed: _openGoToDialog,
            icon: const Icon(Icons.pin_drop_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: 604,
            onPageChanged: (i) {
              setState(() => _page = i + 1);
              _saveLastPage();
            },
            itemBuilder: (ctx, i) {
              final ayahs = _buildAyahsForPage(i + 1);
              return _MushafPage(page: i + 1, ayahs: ayahs);
            },
          ),
          // top-left corner overlay (positioned like mushaf ornament)
          Positioned(
            top: 8,
            left: 12,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFE3C46B),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _arabicNumeral(_page),
                  style: const TextStyle(
                    color: Color(0xFF12352B),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 12,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFE3C46B),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.menu_book_rounded,
                    color: Color(0xFF12352B), size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MushafPage extends StatelessWidget {
  final int page;
  final List<_MushafAyah> ayahs;
  const _MushafPage({required this.page, required this.ayahs});

  @override
  Widget build(BuildContext context) {
    final List<Widget> lines = [];
    int? prevSurah;
    int? prevJuz;
    for (final ayah in ayahs) {
      if (ayah.surahNumber != prevSurah) {
        final meta = QuranService.instance.surah(ayah.surahNumber);
        lines.add(_SurahHeader(
          surah: ayah.surahNumber,
          nameAr: meta.nameAr,
          nameEn: meta.nameEn,
        ));
        prevSurah = ayah.surahNumber;
        prevJuz = null;
      }
      if (ayah.juz != prevJuz) {
        lines.add(_JuzMarker(juz: ayah.juz));
        prevJuz = ayah.juz;
      }
      lines.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: ayah.text),
                const WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: _AyahNum(n: null),
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              color: Color(0xFF1A3A2E),
              fontSize: 22,
              height: 2.1,
              fontFamily: 'serif',
            ),
          ),
        ),
      );
    }
    lines.add(const SizedBox(height: 20));
    lines.add(
      Text(
        _arabicNumeral(page),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF8A6D2F),
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 46, 18, 24),
      child: Column(children: lines),
    );
  }
}

class _SurahHeader extends StatelessWidget {
  final int surah;
  final String nameAr;
  final String nameEn;
  const _SurahHeader({required this.surah, required this.nameAr, required this.nameEn});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B211A), Color(0xFF12351F)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            nameAr,
            style: const TextStyle(
              color: Color(0xFFE3C46B),
              fontSize: 21,
              fontWeight: FontWeight.w800,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nameEn,
            style: const TextStyle(color: Color(0xFFA8B8AE), fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _JuzMarker extends StatelessWidget {
  final int juz;
  const _JuzMarker({required this.juz});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE3C46B).withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'جزء ${_arabicNumeral(juz)}',
          style: const TextStyle(
            color: Color(0xFF12352B),
            fontSize: 14,
            fontWeight: FontWeight.w800,
            fontFamily: 'serif',
          ),
        ),
      ),
    );
  }
}

class _AyahNum extends StatelessWidget {
  final int? n;
  const _AyahNum({required this.n});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFE3C46B),
        shape: BoxShape.circle,
      ),
      child: n == null
          ? const Text('۝')
          : Text(
              _arabicNumeral(n!),
              style: const TextStyle(
                color: Color(0xFF12352B),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}
