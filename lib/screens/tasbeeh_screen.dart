import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/static_data.dart';
import '../services/custom_tasbeeh_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

const _channel = MethodChannel('sajda/prayer_alarm');

class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {
  TasbeehPreset _preset = tasbeehPresets.isNotEmpty
      ? tasbeehPresets.first
      : const TasbeehPreset(name: '', arabic: '', meaning: '', defaultCount: 33);
  CustomTasbeeh? _custom;
  List<CustomTasbeeh> _customs = [];
  int _count = 0;
  int _sets = 0;
  int _target = 33;

  @override
  void initState() {
    super.initState();
    _target = _preset.defaultCount;
    _loadCustoms();
  }

  Future<void> _loadCustoms() async {
    final c = await CustomTasbeehService.instance.getAll();
    if (!mounted) return;
    setState(() => _customs = c);
  }

  void _selectPreset(TasbeehPreset p) {
    setState(() {
      _preset = p;
      _custom = null;
      _target = p.defaultCount;
      _count = 0;
      _sets = 0;
    });
  }

  void _selectCustom(CustomTasbeeh c) {
    setState(() {
      _custom = c;
      _target = c.count;
      _count = 0;
      _sets = 0;
    });
  }

  void _increment() async {
    final state = context.read<AppState>();
    if (state.tasbeehVibration) {
      try {
        await _channel.invokeMethod('vibrate', {'duration': 50});
      } catch (_) {
        HapticFeedback.heavyImpact();
      }
    }
    setState(() {
      if (_count < _target) {
        _count++;
      } else {
        _sets++;
        _count = 0;
      }
    });
  }

  void _reset() => setState(() {
    _count = 0;
    _sets = 0;
  });

  Future<void> _addCustom() async {
    final nameCtrl = TextEditingController();
    final countCtrl = TextEditingController(text: '33');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Custom Tasbeeh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Dhikr name (e.g. Rabighfirli)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: countCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Target count'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Add')),
        ],
      ),
    );
    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      final count = int.tryParse(countCtrl.text) ?? 33;
      await CustomTasbeehService.instance.add(nameCtrl.text.trim(), count);
      await _loadCustoms();
    }
    nameCtrl.dispose();
    countCtrl.dispose();
  }

  Future<void> _deleteCustom(CustomTasbeeh c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${c.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await CustomTasbeehService.instance.remove(c.id);
      if (_custom?.id == c.id) {
        _selectPreset(tasbeehPresets.isNotEmpty
            ? tasbeehPresets.first
            : const TasbeehPreset(name: '', arabic: '', meaning: '', defaultCount: 33));
      }
      await _loadCustoms();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = _target == 0 ? 0.0 : _count / _target;
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;
    final ringSize = (size.shortestSide * 0.5).clamp(160.0, 260.0);
    final countFont = (ringSize * 0.3).clamp(36.0, 80.0);
    final labelFont = (ringSize * 0.13).clamp(12.0, 22.0);

    return Scaffold(
      appBar: AppBar(title: Text(state.t('Tasbeeh Counter', 'تسبیح کاؤنٹر'))),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.only(bottom: isSmall ? 16 : 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: isSmall ? 84 : 96,
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 16, vertical: 8),
                        scrollDirection: Axis.horizontal,
                        itemCount: tasbeehPresets.length + _customs.length + 1,
                        separatorBuilder: (_, _) => SizedBox(width: isSmall ? 8 : 10),
                        itemBuilder: (ctx, i) {
                          if (i < tasbeehPresets.length) {
                            final p = tasbeehPresets[i];
                            final selected = _custom == null && p.name == _preset.name;
                            return _PresetChip(
                              isSmall: isSmall,
                              selected: selected,
                              arabic: p.arabic,
                              name: p.name,
                              count: p.defaultCount,
                              color: selected ? AppColors.primary : null,
                              onTap: () => _selectPreset(p),
                            );
                          }
                          final customIndex = i - tasbeehPresets.length;
                          if (customIndex < _customs.length) {
                            final c = _customs[customIndex];
                            final selected = _custom?.id == c.id;
                            return _PresetChip(
                              isSmall: isSmall,
                              selected: selected,
                              arabic: '',
                              name: c.name,
                              count: c.count,
                              icon: Icons.bookmark_added_outlined,
                              color: selected ? AppColors.primaryPill(isDark) : null,
                              onTap: () => _selectCustom(c),
                              onLongPress: () => _deleteCustom(c),
                            );
                          }
                          return _PresetChip(
                            isSmall: isSmall,
                            selected: false,
                            arabic: '',
                            name: state.t('Custom', 'اپنا ذکر'),
                            count: 0,
                            icon: Icons.add_circle_outline_rounded,
                            color: null,
                            borderColor: AppColors.primary.withValues(alpha: 0.5),
                            onTap: _addCustom,
                          );
                        },
                      ),
                    ),
                    SizedBox(height: isSmall ? 6 : 10),
                    Flexible(
                      child: Text(
                        _custom != null ? _custom!.name : _preset.arabic,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: isSmall ? 22 : 34, fontWeight: FontWeight.w700, height: 1.6),
                      ),
                    ),
                    SizedBox(height: isSmall ? 2 : 4),
                    Text(
                      _custom != null
                          ? state.t('Custom tasbeeh', 'اپنا ذکر')
                          : state.t(_preset.meaning, _preset.meaning),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    SizedBox(height: isSmall ? 10 : 16),
                    SizedBox(
                      width: ringSize,
                      height: ringSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: ringSize,
                            height: ringSize,
                            child: CircularProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              strokeWidth: ringSize * 0.08,
                              backgroundColor: Colors.grey.withValues(alpha: 0.12),
                              color: AppColors.primary,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$_count', style: TextStyle(fontSize: countFont, fontWeight: FontWeight.w900, height: 1)),
                              SizedBox(height: isSmall ? 2 : 4),
                              Text('$_sets/$_target', style: TextStyle(fontSize: labelFont, color: AppColors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isSmall ? 8 : 12),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 16),
                      child: _ToggleRow(
                        icon: Icons.vibration_rounded,
                        label: state.t('Vibration', 'کمپن'),
                        value: state.tasbeehVibration,
                        onChanged: state.setTasbeehVibration,
                      ),
                    ),
                    SizedBox(height: isSmall ? 8 : 12),
                    Padding(
                      padding: EdgeInsets.fromLTRB(isSmall ? 10 : 16, 0, isSmall ? 10 : 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _reset,
                              icon: Icon(Icons.refresh_rounded, size: isSmall ? 18 : 20),
                              label: Text(state.t('Reset', 'ری سیٹ')),
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size.fromHeight(isSmall ? 48 : 52),
                                padding: EdgeInsets.symmetric(vertical: isSmall ? 10 : 12),
                              ),
                            ),
                          ),
                          SizedBox(width: isSmall ? 10 : 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed: _increment,
                              icon: Icon(Icons.touch_app_rounded, size: isSmall ? 20 : 24),
                              label: Text(state.t('Tap', 'ٹیپ'), style: TextStyle(fontSize: isSmall ? 14 : 16, fontWeight: FontWeight.w600)),
                              style: FilledButton.styleFrom(
                                minimumSize: Size.fromHeight(isSmall ? 52 : 56),
                                padding: EdgeInsets.symmetric(vertical: isSmall ? 12 : 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final bool isSmall;
  final bool selected;
  final String arabic;
  final String name;
  final int count;
  final IconData? icon;
  final Color? color;
  final Color? borderColor;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _PresetChip({
    required this.isSmall,
    required this.selected,
    required this.arabic,
    required this.name,
    required this.count,
    this.icon,
    this.color,
    this.borderColor,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = color ??
        (dark ? AppColors.darkSurface : Colors.white);
    final bdColor = selected
        ? (color ?? AppColors.primary)
        : (borderColor ?? Colors.grey.withValues(alpha: 0.3));
    final textColor = selected ? Colors.white : null;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSmall ? 96 : 128,
        padding: EdgeInsets.all(isSmall ? 10 : 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bdColor),
          boxShadow: selected && color != null
              ? [BoxShadow(color: color!.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 5))]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null && arabic.isEmpty)
              Icon(icon, size: 18, color: color ?? AppColors.primary)
            else
              Text(arabic, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: isSmall ? 13 : 16, fontWeight: FontWeight.w700, color: textColor)),
            SizedBox(height: isSmall ? 3 : 5),
            Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                style: TextStyle(fontSize: isSmall ? 9 : (icon != null ? 10 : 11.5),
                    fontWeight: FontWeight.w700, color: selected ? Colors.white70 : AppColors.textMuted)),
            Text('$count', style: TextStyle(fontSize: isSmall ? 8 : 10, color: selected ? Colors.white54 : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
        Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.primary),
      ],
    );
  }
}