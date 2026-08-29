import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/azkar_model.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'zikr_detail_screen.dart';

class AdhkarScreen extends StatelessWidget {
  const AdhkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final categories = adhkarCategories;
    return Scaffold(
      appBar: AppBar(
        title: Text(state.t('Adhkar (Hisnul Muslim)', 'اذکار (حصون مسلم)')),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (ctx, i) {
          final c = categories[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ZikrDetailScreen(category: c)),
              ),
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
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.volunteer_activism_outlined, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.category,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'serif',
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkText
                                : const Color(0xFF12352B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          state.t(
                            '${c.items.length} remembrances',
                            '${c.items.length} اذکار',
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}