import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/user_rank.dart';
import '../../theme/app_theme.dart';
import '../animations/apple_pressable.dart';
import '../profile/profile_customization.dart';
import 'animated_trophy.dart';

/// Highly animated motion graphics clinical podium for Top 3 doctors.
/// Features dynamic rising pedestals, laser-etched cyber meters, animated light sweeps,
/// pulsating avatar aura rings, and cheerful animated trophies.
class EditorialPodium extends StatefulWidget {
  final LeaderboardEntry? first;
  final LeaderboardEntry? second;
  final LeaderboardEntry? third;
  final ValueChanged<LeaderboardEntry>? onEntryTap;

  const EditorialPodium({
    super.key,
    this.first,
    this.second,
    this.third,
    this.onEntryTap,
  });

  @override
  State<EditorialPodium> createState() => _EditorialPodiumState();
}

class _EditorialPodiumState extends State<EditorialPodium>
    with TickerProviderStateMixin {
  late final AnimationController _riseController;
  late final AnimationController _motionController;

  @override
  void initState() {
    super.initState();
    _riseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();

    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void didUpdateWidget(EditorialPodium oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.first?.id != widget.first?.id ||
        oldWidget.second?.id != widget.second?.id ||
        oldWidget.third?.id != widget.third?.id) {
      _riseController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _riseController.dispose();
    _motionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.first == null && widget.second == null && widget.third == null) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        child: AnimatedBuilder(
        animation: Listenable.merge([_riseController, _motionController]),
        builder: (context, child) {
          // Staggered rise curves
          final secondRise = CurvedAnimation(
            parent: _riseController,
            curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack),
          ).value;

          final firstRise = CurvedAnimation(
            parent: _riseController,
            curve: const Interval(0.12, 0.95, curve: Curves.easeOutBack),
          ).value;

          final thirdRise = CurvedAnimation(
            parent: _riseController,
            curve: const Interval(0.06, 0.82, curve: Curves.easeOutBack),
          ).value;

          final motionProgress = _motionController.value;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd Place (Left - Silver)
              Expanded(
                child: widget.second != null
                    ? _PodiumColumn(
                        entry: widget.second!,
                        targetHeight: 128.0,
                        currentHeight: 128.0 * secondRise.clamp(0.0, 1.08),
                        rank: 2,
                        isPeak: false,
                        motionProgress: motionProgress,
                        accentColor: const Color(0xFF94A3B8), // Silver
                        rimColor: const Color(0xFFE2E8F0),
                        onTap: () => widget.onEntryTap?.call(widget.second!),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),

              // 1st Place (Center - Gold)
              Expanded(
                child: widget.first != null
                    ? _PodiumColumn(
                        entry: widget.first!,
                        targetHeight: 162.0,
                        currentHeight: 162.0 * firstRise.clamp(0.0, 1.1),
                        rank: 1,
                        isPeak: true,
                        motionProgress: motionProgress,
                        accentColor: const Color(0xFFF59E0B), // Vibrant Gold
                        rimColor: const Color(0xFFFDE68A),
                        onTap: () => widget.onEntryTap?.call(widget.first!),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),

              // 3rd Place (Right - Bronze)
              Expanded(
                child: widget.third != null
                    ? _PodiumColumn(
                        entry: widget.third!,
                        targetHeight: 114.0,
                        currentHeight: 114.0 * thirdRise.clamp(0.0, 1.06),
                        rank: 3,
                        isPeak: false,
                        motionProgress: motionProgress,
                        accentColor: const Color(0xFFEA580C), // Warm Bronze
                        rimColor: const Color(0xFFFDBA74),
                        onTap: () => widget.onEntryTap?.call(widget.third!),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final LeaderboardEntry entry;
  final double targetHeight;
  final double currentHeight;
  final int rank;
  final bool isPeak;
  final double motionProgress;
  final Color accentColor;
  final Color rimColor;
  final VoidCallback? onTap;

  const _PodiumColumn({
    required this.entry,
    required this.targetHeight,
    required this.currentHeight,
    required this.rank,
    required this.isPeak,
    required this.motionProgress,
    required this.accentColor,
    required this.rimColor,
    this.onTap,
  });

  /// Maps any unset or letter avatar to a polished character avatar,
  /// strictly preventing single-letter initials (S, V, A) from appearing on the podium.
  String _resolvePodiumAvatar(String iconId, int rank) {
    if (iconId.isNotEmpty && iconId != 'letter' && iconId != 'stethoscope') {
      return iconId;
    }
    // High-quality character fallback per rank
    switch (rank) {
      case 1:
        return 'cute_plague_doctor';
      case 2:
        return 'avatar_dark_knight';
      case 3:
      default:
        return 'september_glow';
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarSize = isPeak ? 54.0 : 44.0;
    final resolvedIcon = _resolvePodiumAvatar(entry.avatarIconId, rank);

    return ApplePressable(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Doctor Avatar with Pulsating Holographic Halo Aura Ring
          _PodiumAvatarHalo(
            size: avatarSize,
            rank: rank,
            accentColor: accentColor,
            motionProgress: motionProgress,
            child: ProfileAvatar(
              size: avatarSize,
              colorId: entry.avatarColorId,
              iconId: resolvedIcon,
              doctorName: entry.displayName,
            ),
          ),
          const SizedBox(height: 8),

          // 2. Doctor Display Name
          Text(
            entry.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isPeak ? 13.5 : 12.0,
              fontWeight: entry.isCurrentUser ? FontWeight.w800 : FontWeight.w700,
              color: entry.isCurrentUser ? AppTheme.accentPrimary : AppTheme.inkForeground,
            ),
          ),
          const SizedBox(height: 2),

          // 3. Formatted Study Duration
          Text(
            entry.formattedDuration,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isPeak ? 13.0 : 11.5,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              color: AppTheme.inkForeground.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 8),

          // 4. Motion Graphics Animated Pedestal Bar
          _AnimatedMotionPodiumBar(
            height: currentHeight,
            targetHeight: targetHeight,
            rank: rank,
            isPeak: isPeak,
            accentColor: accentColor,
            rimColor: rimColor,
            motionProgress: motionProgress,
          ),
        ],
      ),
    );
  }
}

/// Pulsating Aura Ring around Top 3 avatars
class _PodiumAvatarHalo extends StatelessWidget {
  final double size;
  final int rank;
  final Color accentColor;
  final double motionProgress;
  final Widget child;

  const _PodiumAvatarHalo({
    required this.size,
    required this.rank,
    required this.accentColor,
    required this.motionProgress,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final pulse = 0.5 + 0.5 * math.sin(motionProgress * 2 * math.pi + (rank * 0.8));
    final glowSpread = 1.0 + (pulse * 2.0);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.35 + (pulse * 0.25)),
            blurRadius: 10 + (pulse * 6),
            spreadRadius: glowSpread,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// High-Octane Motion Graphics Podium Bar with Laser Etched Grid, Light Sweep, and Cheerful Trophy
class _AnimatedMotionPodiumBar extends StatelessWidget {
  final double height;
  final double targetHeight;
  final int rank;
  final bool isPeak;
  final Color accentColor;
  final Color rimColor;
  final double motionProgress;

  const _AnimatedMotionPodiumBar({
    required this.height,
    required this.targetHeight,
    required this.rank,
    required this.isPeak,
    required this.accentColor,
    required this.rimColor,
    required this.motionProgress,
  });

  @override
  Widget build(BuildContext context) {
    final trophySize = isPeak ? 50.0 : 40.0;
    final rankLabel = rank == 1 ? '1ST' : (rank == 2 ? '2ND' : '3RD');

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isPeak ? 0.25 : 0.15),
            blurRadius: isPeak ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: Stack(
          children: [
            // 1. Motion Graphics Custom Painter (Obsidian Metallic Gradient, Laser Meters, Light Sweep, Neon Rim)
            Positioned.fill(
              child: CustomPaint(
                painter: _PodiumMotionPainter(
                  rank: rank,
                  isPeak: isPeak,
                  accentColor: accentColor,
                  rimColor: rimColor,
                  progress: motionProgress,
                ),
              ),
            ),

            // 2. Interior Elements (Cheerful Trophy & Holographic Plaque)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CheerfulAnimatedTrophy(
                    rank: rank,
                    size: trophySize,
                  ),
                  const SizedBox(height: 4),

                  // Cyber Holographic Rank Badge Pill
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isPeak ? 10.0 : 8.0,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.55),
                        width: 0.9,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.25),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      rankLabel,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: isPeak ? 11.5 : 10.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: rimColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Painter executing motion graphics: laser graduations, obsidian metallic base, and moving reflection sweep
class _PodiumMotionPainter extends CustomPainter {
  final int rank;
  final bool isPeak;
  final Color accentColor;
  final Color rimColor;
  final double progress;

  _PodiumMotionPainter({
    required this.rank,
    required this.isPeak,
    required this.accentColor,
    required this.rimColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;

    // 1. Obsidian Metallic Base Gradient
    final List<Color> baseColors;
    switch (rank) {
      case 1:
        // Deep obsidian gold
        baseColors = const [
          Color(0xFF282015),
          Color(0xFF1B160E),
          Color(0xFF100D09),
        ];
        break;
      case 2:
        // Obsidian titanium silver
        baseColors = const [
          Color(0xFF1F2532),
          Color(0xFF151922),
          Color(0xFF0E1017),
        ];
        break;
      case 3:
      default:
        // Obsidian ember bronze
        baseColors = const [
          Color(0xFF2A1C15),
          Color(0xFF1C130E),
          Color(0xFF110C09),
        ];
        break;
    }

    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: baseColors,
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    // 2. Laser-Etched Cyber Energy Graduations (Tick Marks on Left & Right)
    final tickCount = (size.height / 14).floor().clamp(3, 12);
    final tickPaint = Paint()
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final sweepY = size.height * (1.0 - progress);

    for (int i = 0; i < tickCount; i++) {
      final y = size.height - (i * 14.0) - 10.0;
      if (y < 8) continue;

      // Distance from sweep line modulates brightness
      final dist = (y - sweepY).abs();
      final highlightFactor = (1.0 - (dist / 40.0)).clamp(0.0, 1.0);
      final alpha = 0.22 + (highlightFactor * 0.65);

      tickPaint.color = accentColor.withValues(alpha: alpha);

      // Left tick: 5px to 14px
      canvas.drawLine(Offset(6, y), Offset(14, y), tickPaint);
      // Right tick: width - 14px to width - 6px
      canvas.drawLine(Offset(size.width - 14, y), Offset(size.width - 6, y), tickPaint);
    }

    // 3. Sweeping High-Specular Reflection Light Beam (Translates upward diagonally)
    final beamY = size.height * 1.4 * (1.0 - progress) - (size.height * 0.2);
    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          accentColor.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0.32),
          accentColor.withValues(alpha: 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(0, beamY - 35, size.width, 70));

    canvas.save();
    canvas.clipRect(rect);
    // Draw angled beam across width
    canvas.drawRect(Rect.fromLTWH(0, beamY - 35, size.width, 70), beamPaint);
    canvas.restore();

    // 4. Subtle Outer Border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isPeak ? 1.4 : 1.0
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withValues(alpha: isPeak ? 0.8 : 0.5),
          accentColor.withValues(alpha: 0.15),
        ],
      ).createShader(rect);

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect.deflate(0.6),
        topLeft: const Radius.circular(12),
        topRight: const Radius.circular(12),
      ),
      borderPaint,
    );

    // 5. Crowning Luminous Neon Rim at Top Edge
    final rimPaint = Paint()
      ..strokeWidth = isPeak ? 3.2 : 2.4
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          rimColor.withValues(alpha: 0.7),
          Colors.white,
          rimColor.withValues(alpha: 0.7),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 4));

    canvas.drawLine(const Offset(4, 1.5), Offset(size.width - 4, 1.5), rimPaint);
  }

  @override
  bool shouldRepaint(_PodiumMotionPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.rank != rank ||
        oldDelegate.isPeak != isPeak;
  }
}
