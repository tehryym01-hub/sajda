import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/streak_v2_api.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';
import '../state/streak_state.dart';
import '../theme/app_theme.dart';
import 'group_dashboard_screen.dart';

/// Create a Friends & Family group. Names are NOT unique. New groups are
/// invite-only by default; public groups also accept join requests.
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _controller = TextEditingController();
  bool _public = false;
  bool _creating = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final app = context.read<AppState>();
    final name = _controller.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(app.t('Enter a group name (2+ characters)', 'گروپ کا نام لکھیں (۲+ حروف)')),
      ));
      return;
    }
    setState(() => _creating = true);
    try {
      final group = await StreakV2Api.instance.createGroup(name, public: _public);
      if (!mounted) return;
      await context.read<StreakState>().groupsChanged();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => GroupDashboardScreen(groupId: group.groupId, justCreated: true)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.isNetworkError
            ? app.t('No connection. Check your internet.', 'انٹرنیٹ نہیں چل رہا۔')
            : e.message),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
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
          app.t('New group', 'نیا گروپ'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primaryDeep),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    app.t(
                      'Everyone in the group must complete all 5 prayers for the group day to count. New members never break the streak — they start counting from the next day.',
                      'گروپ کے سبھی ارکان کو پانچوں نمازیں مکمل کرنی ہوں گی تاکہ گروپ کا دن گنا جائے۔ نئے ارکان کبھی سلسلہ نہیں توڑتے — وہ اگلے دن سے شمار ہوتے ہیں۔',
                    ),
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: isDark ? AppColors.darkMuted : AppColors.lightSecondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            app.t('Group name', 'گروپ کا نام'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            maxLength: 60,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(fontSize: 15, color: isDark ? AppColors.darkText : AppColors.lightText),
            decoration: InputDecoration(
              hintText: app.t('e.g. Family Deen Squad', 'مثلاً خاندانی ٹیم'),
              counterStyle: TextStyle(color: isDark ? AppColors.darkMuted : AppColors.lightMutedText),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : AppColors.lightCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightBorder),
              ),
            ),
            onSubmitted: (_) => _create(),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _public,
            onChanged: (v) => setState(() => _public = v),
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.primary,
            title: Text(
              app.t('Discoverable (public)', 'تلاش کے قابل (عوامی)'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            subtitle: Text(
              app.t(
                'People can find this group by name and request to join. Owners approve.',
                'لوگ نام سے گروپ ڈھونڈ کر شمولیت کی درخواست دے سکتے ہیں۔ ملک رضامندی دے گا۔',
              ),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkMuted : AppColors.lightSecondaryText,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _creating ? null : _create,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _creating
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : Text(
                      app.t('Create group', 'گروپ بنائیں'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
