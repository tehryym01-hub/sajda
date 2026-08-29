import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/static_data.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class IslamicScreen extends StatefulWidget {
  const IslamicScreen({super.key});

  @override
  State<IslamicScreen> createState() => _IslamicScreenState();
}

class _IslamicScreenState extends State<IslamicScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return DefaultTabController(
      length: 2,
      initialIndex: _tab,
      child: Scaffold(
        appBar: AppBar(
          title: Text(state.t('Islamic Library', 'دینی لائبریری')),
          bottom: TabBar(
            onTap: (i) => setState(() => _tab = i),
            tabs: [
              Tab(text: state.t('Duas', 'دعائیں')),
              Tab(text: state.t('Wazifa', 'وظیفہ')),
            ],
          ),
        ),
        body: IndexedStack(
          index: _tab,
          children: const [DuasPage(), WazifaPage()],
        ),
      ),
    );
  }
}

// ---------- Duas ----------

class DuasPage extends StatefulWidget {
  const DuasPage({super.key});

  @override
  State<DuasPage> createState() => _DuasPageState();
}

class _DuasPageState extends State<DuasPage> {
  String? _category;
  List<DuaModel> _duas = [];
  bool _loading = true;
  String? _error;

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
      final duas = await ApiClient.instance.getDuas(category: _category);
      if (!mounted) return;
      setState(() {
        _duas = duas;
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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final categories = ['all', ...duaCategories];

    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              final selected = _category == cat;
              return FilterPill(
                label: _categoryLabel(cat, state.language),
                selected: selected,
                onTap: () {
                  setState(() => _category = cat);
                  _load();
                },
              );
            },
          ),
        ),
        Expanded(
          child: _loading
              ? const AppLoader()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : _duas.isEmpty
                      ? EmptyView(
                          message: state.t('No duas found for this category', 'اس قسم کی کوئی دعا نہیں ملی'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _duas.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final dua = _duas[i];
                            return GlassCard(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => _DuaDetailScreen(dua: dua),
                                ),
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
                                          dua.title(state.language),
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
                            );
                          },
                        ),
        ),
      ],
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
                  dua.arabic,
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
          if (dua.reference.isNotEmpty)
            GlassCard(
              child: Row(
                children: [
                  const Icon(Icons.menu_book_outlined, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(dua.reference, style: Theme.of(context).textTheme.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------- Wazifa ----------

class WazifaPage extends StatefulWidget {
  const WazifaPage({super.key});

  @override
  State<WazifaPage> createState() => _WazifaPageState();
}

class _WazifaPageState extends State<WazifaPage> {
  WazifaModel? _wazifa;
  int _dayOfYear = 0;
  bool _loading = true;
  String? _error;

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
      final w = await ApiClient.instance.getDailyWazifa();
      if (!mounted) return;
      setState(() {
        _wazifa = w;
        _dayOfYear = w?.dayOfYear ?? DateTime.now().difference(DateTime(DateTime.now().year)).inDays + 1;
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

  Future<void> _loadDay(int day) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final w = await ApiClient.instance.getWazifaByDay(day);
      if (!mounted) return;
      setState(() {
        _wazifa = w;
        _dayOfYear = day;
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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  state.t('Daily Wazifa', 'روزانہ وظیفہ'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showDayPicker(context),
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(state.t('Pick a day', 'دن منتخب کریں')),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const AppLoader()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : _wazifa == null
                      ? EmptyView(
                          message: state.t('No wazifa available', 'کوئی وظیفہ دستیاب نہیں'))
                      : _WazifaCard(wazifa: _wazifa!, day: _dayOfYear),
        ),
      ],
    );
  }

  Future<void> _showDayPicker(BuildContext context) async {
    final appState = context.read<AppState>();
    final controller = TextEditingController();
    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(appState.t('Select day (1-365)', 'دن منتخب کریں (1-365)')),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'e.g. 100'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final day = int.tryParse(controller.text);
              if (day != null && day >= 1 && day <= 365) {
                Navigator.of(ctx).pop(day);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (selected != null) {
      _loadDay(selected);
    }
  }
}

class _WazifaCard extends StatelessWidget {
  final WazifaModel wazifa;
  final int day;
  const _WazifaCard({required this.wazifa, required this.day});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HeroPanel(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      'Day $day',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      wazifa.type.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                wazifa.title(state.language),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Text(
                wazifa.arabic.isEmpty ? wazifa.urdu : wazifa.arabic,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 22, height: 2, fontWeight: FontWeight.w600),
              ),
              if (wazifa.transliteration.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  wazifa.transliteration,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic, height: 1.6),
                ),
              ],
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  '${state.t('Count', 'تعداد')}: ${wazifa.count}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (wazifa.urdu.isNotEmpty) ...[
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.t('Urdu', 'اردو'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(wazifa.urdu, style: const TextStyle(fontSize: 16, height: 1.8)),
              ],
            ),
          ),
        ],
        if (wazifa.english.isNotEmpty && state.language == 'en') ...[
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('English', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(wazifa.english, style: const TextStyle(fontSize: 15, height: 1.7)),
              ],
            ),
          ),
        ],
        if (wazifa.benefit(state.language).isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryPill(isDark),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${state.t('Benefit', 'فائدہ')}: ${wazifa.benefit(state.language)}',
                    style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}