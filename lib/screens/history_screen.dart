import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<IslamicEvent> _events = [];
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
      final events = await ApiClient.instance.getUpcomingEvents(limit: 50);
      if (!mounted) return;
      setState(() {
        _events = events;
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
    return Scaffold(
      appBar: AppBar(title: Text(state.t('Islamic History', 'اسلامی تاریخ'))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: AppLoader())
            : _error != null
                ? ErrorView(message: _error!, onRetry: _load)
                : _events.isEmpty
                    ? EmptyView(message: state.t('No historical events found', 'کوئی تاریخی واقعہ نہیں ملا'))
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _events.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final e = _events[i];
                          return _HistoryCard(event: e);
                        },
                      ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final IslamicEvent event;
  const _HistoryCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final color = _typeColor(event.type);
    return GlassCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _HistoryDetailScreen(event: event)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: Icons.history_edu_outlined, color: color, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title(state.language),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        '${event.day} ${event.month}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  event.description(state.language),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'celebration':
        return const Color(0xFF0E8A6D);
      case 'major_celebration':
        return const Color(0xFFD4A937);
      case 'mourning':
        return const Color(0xFF5D6D7E);
      case 'major_mourning':
        return const Color(0xFF2C3E50);
      default:
        return AppColors.primary;
    }
  }
}

class _HistoryDetailScreen extends StatelessWidget {
  final IslamicEvent event;
  const _HistoryDetailScreen({required this.event});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(event.title(state.language))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HeroPanel(
            child: Row(
              children: [
                const Icon(Icons.event_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${event.day} ${event.month} ${state.t('Hijri', 'ہجری')}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (event.description(state.language).isNotEmpty) ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(state.t('About this day', 'اس دن کے بارے میں'), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(event.description(state.language), style: const TextStyle(fontSize: 15, height: 1.7)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (event.amal.isNotEmpty) ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(state.t('Recommended Actions (Amal)', 'تجویز کردہ اعمال'), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  ...event.amal.map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(a, style: const TextStyle(fontSize: 14, height: 1.6))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (event.duas.isNotEmpty) ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(state.t('Duas for this day', 'اس دن کی دعائیں'), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...event.duas.map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          if (d.arabic.isNotEmpty)
                            Text(d.arabic, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, height: 1.8)),
                          if (d.transliteration.isNotEmpty)
                            Text(
                              d.transliteration,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (d.urdu.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(d.urdu, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, height: 1.6)),
                            ),
                        ],
                      ),
                    ),
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