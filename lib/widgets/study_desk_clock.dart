import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/tour/app_tour_controller.dart';
import '../theme/modulix_theme.dart';
import 'animations/rolling_digit_text.dart';

/// Authentic Hand-Drawn Sketchy Desk Clock
///
/// Features an ornate fine-line hand-drawn scrollwork frame with
/// cross-hatched sketchy time digits (hh:mm a) and an architectural baseline guide.
/// Full-width integration on the Home screen with no buttons, tags, or focus timer links.
class StudyDeskClock extends StatelessWidget {
  const StudyDeskClock({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.modulixTheme;
    final isDark = theme.isDark;
    final frameAsset = isDark
        ? 'assets/illustrations/ornate_sketch_frame_dark.png'
        : 'assets/illustrations/ornate_sketch_frame_light.png';

    return SizedBox(
      key: TourTargetRegistry.keyFor(TourTargetId.noriHeroCard),
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: 2617 / 1486, // Proportional to hand-drawn ornate frame (~1.76:1)
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ornate hand-drawn pencil/ink border frame
            Image.asset(
              frameAsset,
              fit: BoxFit.fill,
              cacheWidth: 1080,
              filterQuality: FilterQuality.medium,
            ),

            // Center: Sketched live clock digits & AM/PM with baseline guide
            Center(
              child: _SketchyLiveClockDisplay(
                fontColor: theme.inkForeground,
                lineColor: theme.inkForeground.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Live clock display rendering sketchy cross-hatched digits using CabinSketch
class _SketchyLiveClockDisplay extends StatefulWidget {
  final Color fontColor;
  final Color lineColor;

  const _SketchyLiveClockDisplay({
    required this.fontColor,
    required this.lineColor,
  });

  @override
  State<_SketchyLiveClockDisplay> createState() => _SketchyLiveClockDisplayState();
}

class _SketchyLiveClockDisplayState extends State<_SketchyLiveClockDisplay> {
  late DateTime _time;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _time = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        final now = DateTime.now();
        if (now.minute != _time.minute || now.hour != _time.hour) {
          setState(() {
            _time = now;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm').format(_time);
    final amPmStr = DateFormat('a').format(_time);

    return RepaintBoundary(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // Sketched Digits: h:mm with rolling minute transitions
              RollingDigitText(
                text: timeStr,
                style: TextStyle(
                  fontFamily: 'CabinSketch',
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: widget.fontColor,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 10),
              // Sketched AM/PM with architectural pencil baseline guide
              CustomPaint(
                foregroundPainter: _SketchBaselinePainter(
                  lineColor: widget.lineColor,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2, right: 6),
                  child: Text(
                    amPmStr,
                    style: TextStyle(
                      fontFamily: 'CabinSketch',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: widget.fontColor.withValues(alpha: 0.9),
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SketchBaselinePainter extends CustomPainter {
  final Color lineColor;
  const _SketchBaselinePainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    // Draw fine pencil guide line under AM/PM extending slightly past bounds
    canvas.drawLine(
      Offset(-6, size.height + 1.0),
      Offset(size.width + 6, size.height + 1.0),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SketchBaselinePainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}

