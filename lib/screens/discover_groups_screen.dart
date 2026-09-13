import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/streak_v2.dart';
import '../services/streak_v2_api.dart';
import '../state/app_state.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/streak/streak_components.dart';

/// Search public groups by name. Joining requires an owner/admin-approved
/// request (invite-code join is the direct path).
class DiscoverGroupsScreen extends StatefulWidget {
  const DiscoverGroupsScreen({super.key});

  @override
  State<DiscoverGroupsScreen> createState() => _DiscoverGroupsScreenState();
}

class _DiscoverGroupsScreenState extends State<DiscoverGroupsScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<DiscoverGroup> _results = [];
  bool _loading = false;
  bool _hasQuery = false;
  String? _error;
  final Set<String> _requesting = {};
  final Set<String> _requested = {};

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() {
      _loading = true;
      _error = null;
      _hasQuery = q.trim().isNotEmpty;
    });
    try {
      final page = await StreakV2Api.instance.discoverGroups(q.trim());
      if (!mounted) return;
      setState(() {
        _results = page.items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.isNetworkError ? 'network' : e.message;
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

  Future<void> _request(DiscoverGroup g) async {
    final app = context.read<AppState>();
    setState(() => _requesting.add(g.groupId));
    try {
      await StreakV2Api.instance.requestToJoin(g.groupId);
      if (!mounted) return;
      setState(() {
        _requested.add(g.groupId);
        _requesting.remove(g.groupId);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _requesting.remove(g.groupId));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.isNetworkError
            ? app.t('No connection. Check your internet.', 'انٹرنیٹ نہیں چل رہا۔')
            : e.message),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _requesting.remove(g.groupId));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? AppColors.darkText : AppColors.lightText),
        title: Text(
          app.t('Discover groups', 'گروپ تلاش کریں'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              style: TextStyle(fontSize: 15, color: isDark ? AppColors.darkText : AppColors.lightText),
              decoration: InputDecoration(
                hintText: app.t('Search public groups…', 'عوامی گروپ تلاش کریں…'),
                prefixIcon: Icon(Icons.search_rounded, color: isDark ? AppColors.darkMuted : AppColors.lightMutedText),
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : AppColors.lightCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          Expanded(
            child: _loading && _results.isEmpty
                ? const LoadingList()
                : _error != null && _results.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          ErrorCard(
                            message: _error == 'network'
                                ? app.t('No connection. Check your internet.', 'انٹرنیٹ نہیں چل رہا۔')
                                : _error!,
                            onRetry: () => _search(_controller.text),
                          ),
                        ],
                      )
                    : _results.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              EmptyStateCard(
                                icon: Icons.search_off_rounded,
                                title: _hasQuery
                                    ? app.t('No groups found', 'کوئی گروپ نہیں ملا')
                                    : app.t('No public groups yet', 'ابھی کوئی عوامی گروپ نہیں'),
                                subtitle: app.t(
                                  _hasQuery
                                      ? 'Try a different name, or join with an invite code.'
                                      : 'Be the first — create a public group.',
                                  _hasQuery
                                      ? 'دوسرا نام آزمائیں، یا کوڈ سے شامل ہوں۔'
                                      : 'پہلے آپ — عوامی گروپ بنائیں۔',
                                ),
                              ),
                            ],
                          )
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: () => _search(_controller.text),
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                              itemCount: _results.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final g = _results[i];
                                return _DiscoverRow(
                                  dark: isDark,
                                  group: g,
                                  requesting: _requesting.contains(g.groupId),
                                  requested: _requested.contains(g.groupId),
                                  onRequest: () => _request(g),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverRow extends StatelessWidget {
  final bool dark;
  final DiscoverGroup group;
  final bool requesting;
  final bool requested;
  final VoidCallback onRequest;

  const _DiscoverRow({
    required this.dark,
    required this.group,
    required this.requesting,
    required this.requested,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dark ? AppColors.darkSurfaceAlt : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.gradientTeal),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: dark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${group.memberCount} ${app.t('members', 'ارکان')} · 🔥 ${group.currentStreak} · ${group.ownerName}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: dark ? AppColors.darkMuted : AppColors.lightSecondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          group.isMember
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    app.t('Joined', 'شامل'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDeep),
                  ),
                )
              : requested || requesting
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: (dark ? AppColors.darkSurfaceAlt : AppColors.primaryLight),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: requesting
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(
                              app.t('Requested', 'درخواست'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: dark ? AppColors.darkMuted : AppColors.lightSecondaryText,
                              ),
                            ),
                    )
                  : SizedBox(
                      height: 34,
                      child: ElevatedButton(
                        onPressed: onRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          app.t('Request', 'درخواست'),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
        ],
      ),
    );
  }
}
