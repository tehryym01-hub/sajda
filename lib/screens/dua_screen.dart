import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class DuaScreen extends StatefulWidget {
  const DuaScreen({super.key});

  @override
  State<DuaScreen> createState() => _DuaScreenState();
}

class _DuaScreenState extends State<DuaScreen> {
  List<DuaModel> _duas = [];
  DuaModel? _daily;
  bool _loading = true;
  String? _error;
  String _category = 'all';
  String _query = '';

  static const _categories = [
    'all', 'morning', 'evening', 'sleep', 'food',
    'travel', 'hardship', 'forgiveness', 'protection', 'ramadan',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiClient.instance.getDuas(category: _category == 'all' ? null : _category),
        ApiClient.instance.getDailyDua(),
      ]);
      if (!mounted) return;
      final raw0 = results[0] as List?;
      final raw1 = results[1];
      setState(() {
        _duas = raw0?.whereType<DuaModel>().toList() ?? <DuaModel>[];
        _daily = raw1 is DuaModel ? raw1 : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<DuaModel> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _duas;
    return _duas
        .where((d) =>
            d.titleEn.toLowerCase().contains(q) ||
            d.titleUr.toLowerCase().contains(q) ||
            d.english.toLowerCase().contains(q) ||
            d.urdu.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang = state.language;

    return Scaffold(
      appBar: AppBar(title: Text(state.t('Duas', 'دعائیں'))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            // Daily dua hero
            if (_daily != null)
              GlassCard(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDeep],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          state.t("Dua of the Day", 'آج کی دعا'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _daily!.arabic.isEmpty ? _daily!.urdu : _daily!.arabic,
                      style: const TextStyle(color: Colors.white, fontSize: 17, height: 1.85),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _daily!.urdu,
                      style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.7),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => _DuaDetailScreen(dua: _daily!)),
                        ),
                        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: Text(state.t('Read More', 'مزید پڑھیں')),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),

            // Search
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: state.t('Search duas...', 'دعائیں تلاش کریں...'),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() => _query = ''),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Category chips
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final cat = _categories[i];
                  final selected = cat == _category;
                  return FilterChip(
                    label: Text(_categoryLabel(cat, lang)),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _category = cat);
                      _load();
                    },
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : null,
                    ),
                    side: BorderSide(
                      color: selected ? AppColors.primary : const Color(0xFFE0E7E4),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            if (_loading)
              const Padding(padding: EdgeInsets.only(top: 60), child: AppLoader())
            else if (_error != null)
              ErrorView(message: _error!, onRetry: _load)
            else if (_filtered.isEmpty)
              EmptyView(message: state.t('No duas found', 'کوئی دعا نہیں ملی'))
            else
              ..._filtered.map(
                (dua) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => _DuaDetailScreen(dua: dua)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconTile(icon: Icons.auto_awesome_outlined, color: AppColors.primary, size: 44),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dua.title(lang),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                dua.arabic.isEmpty ? dua.urdu : dua.arabic,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 16.5, height: 1.75),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(String cat, String lang) {
    const map = {
      'all': ['All', 'تمام'],
      'morning': ['Morning', 'صبح'],
      'evening': ['Evening', 'شام'],
      'sleep': ['Sleep', 'نیند'],
      'food': ['Food', 'کھانا'],
      'travel': ['Travel', 'سفر'],
      'hardship': ['Hardship', 'مشکل'],
      'forgiveness': ['Forgiveness', 'مغفرت'],
      'protection': ['Protection', 'حفاظت'],
      'ramadan': ['Ramadan', 'رمضان'],
    };
    final v = map[cat] ?? [cat, cat];
    return lang == 'ur' ? v[1] : v[0];
  }
}

class _DuaDetailScreen extends StatelessWidget {
  final DuaModel dua;
  const _DuaDetailScreen({required this.dua});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang = state.language;
    return Scaffold(
      appBar: AppBar(title: Text(dua.title(lang))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HeroPanel(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  dua.arabic.isEmpty ? dua.urdu : dua.arabic,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    height: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (dua.transliteration.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    dua.transliteration,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      height: 1.7,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (dua.urdu.isNotEmpty) ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(state.t('Urdu Translation', 'اردو ترجمہ'),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(dua.urdu, style: const TextStyle(fontSize: 16, height: 1.8)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (dua.english.isNotEmpty && lang == 'en') ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('English Translation', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(dua.english, style: const TextStyle(fontSize: 15, height: 1.7)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (dua.reference.isNotEmpty) ...[
            GlassCard(
              child: Row(
                children: [
                  const Icon(Icons.menu_book_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.t('Reference', 'حوالہ'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    dua.reference,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}