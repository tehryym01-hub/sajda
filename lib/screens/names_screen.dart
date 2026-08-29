import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/static_data.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class NamesScreen extends StatefulWidget {
  const NamesScreen({super.key});

  @override
  State<NamesScreen> createState() => _NamesScreenState();
}

class _NamesScreenState extends State<NamesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = allahNames.where((n) {
      final q = _query.toLowerCase();
      return q.isEmpty ||
          n.en.toLowerCase().contains(q) ||
          n.arabic.contains(_query) ||
          n.meaning.toLowerCase().contains(q) ||
          n.number.toString() == _query;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(state.t('99 Names of Allah', 'اللہ کے 99 نام')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: state.t('Search names...', 'نام تلاش کریں...'),
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
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final n = filtered[i];
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _NameDetailScreen(name: n),
                    ),
                  ),
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.primaryPill(isDark),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${n.number}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          n.arabic,
                          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, height: 1.4),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          n.en,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.isUrdu ? n.meaningUr : n.meaning,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
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

class _NameDetailScreen extends StatelessWidget {
  final AllahName name;
  const _NameDetailScreen({required this.name});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text('${name.number}. ${name.en}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HeroPanel(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${name.number}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name.arabic,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  name.en,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  state.isUrdu ? name.ur : name.en,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.t('Meaning', 'معنی'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  state.isUrdu ? name.meaningUr : name.meaning,
                  style: const TextStyle(fontSize: 17, height: 1.7),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryPill(isDark),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_outline_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.isUrdu
                        ? '${name.ur} کا ذکر کرنے والا اللہ کی رحمت میں ہوگا'
                        : 'Reciting ${name.en} brings the remembrance of Allah',
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.6,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}