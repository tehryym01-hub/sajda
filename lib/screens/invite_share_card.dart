import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/share_image.dart';
import '../utils/streak_invite_text.dart';

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
    return buildStreakInviteShareText(
      streakTitle: widget.streakTitle,
      inviteCode: widget.inviteCode,
      appUrl: widget.appUrl,
      inviterName: widget.creatorName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCard(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: _sharing ? null : _share,
            icon: _sharing
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Icon(Icons.ios_share_rounded, size: 20),
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
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
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -25,
                  left: -15,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.03),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mosque_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 6),
                          const Text(
                            'SAJDA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.streakTitle,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'YOU ARE INVITED TO JOIN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'INVITE CODE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.inviteCode,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone_android_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Sajda: Daily Athan & Qibla',
                              style: TextStyle(
                                fontSize: 11,
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
