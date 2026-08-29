import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// Real compass that points toward Qibla using the device magnetometer.
/// If no sensor data is available it falls back to a static bearing view.
class QiblaCompass extends StatefulWidget {
  final QiblaResponse qibla;
  final double size;
  final bool isUrdu;
  const QiblaCompass({
    super.key,
    required this.qibla,
    this.size = 230,
    this.isUrdu = true,
  });

  @override
  State<QiblaCompass> createState() => _QiblaCompassState();
}

class _QiblaCompassState extends State<QiblaCompass> {
  double? _heading;
  bool _hasStream = false;
  StreamSubscription<CompassEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final stream = FlutterCompass.events;
    if (stream == null) {
      if (mounted) setState(() => _hasStream = false);
      return;
    }
    _sub = stream.listen(
      (event) {
        if (!mounted) return;
        setState(() {
          _heading = event.heading;
          _hasStream = true;
        });
      },
      onError: (_) {
        if (mounted) setState(() => _hasStream = false);
      },
      onDone: () {
        if (mounted) setState(() => _hasStream = false);
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  double get _bearing => widget.qibla.degree.toDouble();

  @override
  Widget build(BuildContext context) {
    final heading = _heading;
    final dialAngle = (heading == null ? 0.0 : -heading) * math.pi / 180;
    final arrowAngle = (heading == null ? _bearing : _bearing - heading) * math.pi / 180;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ---- rotating dial ----
              Transform.rotate(
                angle: dialAngle,
                child: CustomPaint(
                  size: Size.square(widget.size),
                  painter: _DialPainter(radius: widget.size / 2),
                ),
              ),
              // ---- qibla arrow ----
              Transform.rotate(
                angle: arrowAngle,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: widget.size / 2 - 34,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.0)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              // ---- arrow head (Kaaba marker) ----
              Transform.rotate(
                angle: arrowAngle,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: EdgeInsets.only(top: widget.size / 2 - 52),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.mosque_rounded, color: Color(0xFF1B1203), size: 22),
                  ),
                ),
              ),
              // ---- center hub ----
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.55), width: 2),
                  boxShadow: const [
                    BoxShadow(color: AppColors.shadowSoft, blurRadius: 18, offset: Offset(0, 6)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${widget.qibla.degree}°',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _directionLabel(context, widget.qibla.direction),
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
        const SizedBox(height: 16),
        if (heading != null) ...[
          Text(
            '${_headingLabel(context)}  ${heading.toStringAsFixed(0)}°',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
        ] else if (_hasStream) ...[
          Text('…', style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 6),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            '${_kaabaLabel(context)}: ${widget.qibla.distance} km',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
        ),
      ],
    ),
  );
}

  String _directionLabel(BuildContext context, String direction) {
    if (!widget.isUrdu) return direction;
    switch (direction) {
      case 'North':
        return 'شمال';
      case 'North-East':
        return 'شمال مشرق';
      case 'East':
        return 'مشرق';
      case 'South-East':
        return 'جنوب مشرق';
      case 'South':
        return 'جنوب';
      case 'South-West':
        return 'جنوب مغرب';
      case 'West':
        return 'مغرب';
      case 'North-West':
        return 'شمال مغرب';
      default:
        return direction;
    }
  }

  String _headingLabel(BuildContext context) => widget.isUrdu ? 'شمال' : 'Heading';
  String _kaabaLabel(BuildContext context) => widget.isUrdu ? 'کعبہ کا فاصلہ' : 'Distance to Kaaba';
}

class _DialPainter extends CustomPainter {
  final double radius;
  _DialPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final ring = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0B4A3C), Color(0xFF07281F)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, ring);

    final border = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, border);

    final tickMajor = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.9)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final tickMinor = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 72; i++) {
      final angle = (i * 5) * math.pi / 180;
      final isMajor = i % 9 == 0;
      final isMid = i % 18 == 0;
      final inner = isMajor ? radius - 22 : radius - 14;
      final outer = isMajor ? radius - 8 : radius - 8;
      final p1 = center + Offset(math.sin(angle) * inner, -math.cos(angle) * inner);
      final p2 = center + Offset(math.sin(angle) * outer, -math.cos(angle) * outer);
      canvas.drawLine(p1, p2, isMid ? tickMajor : tickMinor);
    }

    final labelStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      color: Colors.white.withValues(alpha: 0.92),
    );
    final offset = radius - 34;
    final labels = {
      0.0: 'N',
      90.0: 'E',
      180.0: 'S',
      270.0: 'W',
    };
    labels.forEach((deg, label) {
      final a = deg * math.pi / 180;
      final pos = center + Offset(math.sin(a) * offset, -math.cos(a) * offset);
      final tp = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    });
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) => oldDelegate.radius != radius;
}