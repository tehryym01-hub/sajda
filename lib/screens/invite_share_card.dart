import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/share_image.dart';

class InviteShareCard extends StatefulWidget {
  final String streakTitle;
  final String inviteCode;
  final String appUrl;
  final String? creatorName;

  const InviteShareCard({
    super.key,
    required this.streakTitle,
    required this.inviteCode,
    required this.appUrl,
    this.creatorName,
  });

  @override
  State<InviteShareCard> createState() => _InviteShareCardState();
}

class _InviteShareCardState extends State<InviteShareCard> {
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      await shareWidgetAsImage(
        context: context,
        widget: _buildCard(),
        fileName: 'invite_${widget.inviteCode}',
        caption: _buildShareText(),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _buildShareText() {
    final name = widget.creatorName != null ? '${widget.creatorName} invited you to join' : 'You are invited to join';
    return '$name ${widget.streakTitle} 🔥\n\nPray together and stay consistent!\n\n📱 Download Sajda: Daily Athan & Qibla\n🔗 ${widget.appUrl}\n\nUse invite code: ${widget.inviteCode}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCard(),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: _sharing ? null : _share,
            icon: _sharing
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Icon(Icons.ios_share_rounded),
            label: Text(_sharing ? 'Preparing...' : 'Share Invite Card'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 420 ? 420.0 : screenWidth - 48;

    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A3D28), AppColors.primaryDeep, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  left: -20,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🔥', style: TextStyle(fontSize: 16)),
                            SizedBox(width: 8),
                            Text(
                              'SAJDA',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.6), width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.mosque_rounded, size: 40, color: AppColors.primary),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'YOU ARE INVITED TO JOIN',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.streakTitle,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 2),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'INVITE CODE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.inviteCode,
                              style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDeep],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group_add_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Join & Pray Together',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone_android_rounded, size: 16, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              'SAJDA: Namaz & Qibla',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}







