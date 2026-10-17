import 'package:flutter/material.dart';
import 'nori_blob_character.dart';

/// Which edge of the speech card the caret arrow points FROM.
enum NoriCaretSide { top, bottom, left, right }

/// Duo-style speech card with a triangular caret that anchors to Nori's
/// position. Mirrors Duolingo's PointingCardView design:
///   • faceColor  — card fill
///   • lipColor   — bottom border (3-D bevel / depth)
///   • caretSide  — which edge the caret protrudes from
///   • caretOffset — pixels along that edge where the caret tip aligns
///
/// The card NEVER overlaps Nori — callers must supply the correct caretSide
/// based on Nori's screen position. [NoriCoachOverlay] handles this
/// automatically. For manual use, see [NoriSpeechCard.autoPlace].
class NoriSpeechCard extends StatelessWidget {
  final String text;
  final NoriCaretSide caretSide;

  /// Pixel offset of the caret tip along the chosen edge.
  /// For [NoriCaretSide.top] and [NoriCaretSide.bottom]: horizontal offset
  /// from card left edge.
  /// For [NoriCaretSide.left] and [NoriCaretSide.right]: vertical offset
  /// from card top edge.
  final double caretOffset;

  /// Card background colour — defaults to Nori's lavender pill palette.
  final Color faceColor;

  /// Bottom border colour (bevel depth). Slightly darker than faceColor.
  final Color lipColor;

  /// Maximum card width in px.
  final double maxWidth;

  const NoriSpeechCard({
    super.key,
    required this.text,
    this.caretSide = NoriCaretSide.bottom,
    this.caretOffset = 24.0,
    this.faceColor = const Color(0xF02D1F5E),
    this.lipColor = const Color(0xFF1A0F42),
    this.maxWidth = 180.0,
  });

  /// Factory: automatically picks caretSide + offset so the card stays inside
  /// [viewportSize] and never covers [noriRect].
  ///
  /// Returns a positioned [NoriSpeechCard] wrapped in [Positioned] for direct
  /// use inside a Stack that spans [viewportSize].
  static Widget autoPlace({
    Key? key,
    required String text,
    required Rect noriRect,
    required Size viewportSize,
    Color faceColor = const Color(0xF02D1F5E),
    Color lipColor = const Color(0xFF1A0F42),
    double maxWidth = 180.0,
  }) {
    const cardH = 56.0; // Estimated card height
    const caretH = 10.0;

    // Prefer card ABOVE Nori
    final spaceAbove = noriRect.top;
    final spaceBelow = viewportSize.height - noriRect.bottom;

    NoriCaretSide side;
    double cardLeft, cardTop;

    if (spaceAbove >= cardH + caretH + 12) {
      // Place above — caret points DOWN from bottom of card
      side = NoriCaretSide.bottom;
      cardTop = noriRect.top - cardH - caretH - 4;
      cardLeft = (noriRect.center.dx - maxWidth / 2)
          .clamp(8.0, viewportSize.width - maxWidth - 8.0);
    } else if (spaceBelow >= cardH + caretH + 12) {
      // Place below — caret points UP from top of card
      side = NoriCaretSide.top;
      cardTop = noriRect.bottom + caretH + 4;
      cardLeft = (noriRect.center.dx - maxWidth / 2)
          .clamp(8.0, viewportSize.width - maxWidth - 8.0);
    } else {
      // Fallback: right side
      side = NoriCaretSide.left;
      cardLeft = noriRect.right + caretH + 4;
      cardTop = (noriRect.center.dy - cardH / 2)
          .clamp(8.0, viewportSize.height - cardH - 8.0);
    }

    // Caret offset: align to Nori's horizontal center
    final caretOff = (noriRect.center.dx - cardLeft)
        .clamp(16.0, maxWidth - 16.0);

    return Positioned(
      left: cardLeft,
      top: cardTop,
      child: NoriSpeechCard(
        key: key,
        text: text,
        caretSide: side,
        caretOffset: caretOff,
        faceColor: faceColor,
        lipColor: lipColor,
        maxWidth: maxWidth,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SpeechCardPainter(
        caretSide: caretSide,
        caretOffset: caretOffset.clamp(16.0, maxWidth - 16.0),
        faceColor: faceColor,
        lipColor: lipColor,
      ),
      child: Padding(
        padding: _contentPadding(),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFEDE9FF),
              fontSize: 11.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.15,
              height: 1.30,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  EdgeInsets _contentPadding() {
    const base = EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    const caretSpace = 10.0;
    switch (caretSide) {
      case NoriCaretSide.top:
        return base.copyWith(top: base.top + caretSpace);
      case NoriCaretSide.bottom:
        return base.copyWith(bottom: base.bottom + caretSpace);
      case NoriCaretSide.left:
        return base.copyWith(left: base.left + caretSpace);
      case NoriCaretSide.right:
        return base.copyWith(right: base.right + caretSpace);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPEECH CARD PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _SpeechCardPainter extends CustomPainter {
  final NoriCaretSide caretSide;
  final double caretOffset;
  final Color faceColor;
  final Color lipColor;

  const _SpeechCardPainter({
    required this.caretSide,
    required this.caretOffset,
    required this.faceColor,
    required this.lipColor,
  });

  static const double _radius = 14.0;
  static const double _caretW = 14.0; // caret base width
  static const double _caretH = 10.0; // caret height
  static const double _lipW = 3.0;    // bevel bottom border thickness

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Card rect (shrunk by caret thickness on the relevant edge)
    final Rect cardRect;
    switch (caretSide) {
      case NoriCaretSide.top:
        cardRect = Rect.fromLTWH(0, _caretH, w, h - _caretH);
        break;
      case NoriCaretSide.bottom:
        cardRect = Rect.fromLTWH(0, 0, w, h - _caretH);
        break;
      case NoriCaretSide.left:
        cardRect = Rect.fromLTWH(_caretH, 0, w - _caretH, h);
        break;
      case NoriCaretSide.right:
        cardRect = Rect.fromLTWH(0, 0, w - _caretH, h);
        break;
    }

    final rrect = RRect.fromRectAndRadius(cardRect, const Radius.circular(_radius));

    // ── 1. Shadow
    final shadowPaint = Paint()
      ..color = const Color(0x44000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawRRect(
      rrect.shift(const Offset(0, 3)),
      shadowPaint,
    );

    // ── 2. Card body
    canvas.drawRRect(rrect, Paint()..color = faceColor);

    // ── 3. Bevel lip (bottom border — Duolingo 3D depth trick)
    final lipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        cardRect.left,
        cardRect.bottom - _lipW,
        cardRect.width,
        _lipW,
      ),
      const Radius.circular(_radius * 0.5),
    );
    canvas.drawRRect(lipRect, Paint()..color = lipColor);

    // ── 4. Caret triangle
    _drawCaret(canvas, cardRect, w, h);
  }

  void _drawCaret(Canvas canvas, Rect cardRect, double w, double h) {
    final path = Path();
    const halfW = _caretW / 2;

    switch (caretSide) {
      case NoriCaretSide.bottom:
        // Triangle pointing down from card bottom edge
        final tipX = caretOffset.clamp(halfW + _radius, w - halfW - _radius);
        final baseY = cardRect.bottom;
        path
          ..moveTo(tipX - halfW, baseY)
          ..lineTo(tipX, h)
          ..lineTo(tipX + halfW, baseY)
          ..close();
        break;

      case NoriCaretSide.top:
        // Triangle pointing up from card top edge
        final tipX = caretOffset.clamp(halfW + _radius, w - halfW - _radius);
        final baseY = cardRect.top;
        path
          ..moveTo(tipX - halfW, baseY)
          ..lineTo(tipX, 0)
          ..lineTo(tipX + halfW, baseY)
          ..close();
        break;

      case NoriCaretSide.left:
        // Triangle pointing left from card left edge
        final tipY = caretOffset.clamp(halfW + _radius, h - halfW - _radius);
        final baseX = cardRect.left;
        path
          ..moveTo(baseX, tipY - halfW)
          ..lineTo(0, tipY)
          ..lineTo(baseX, tipY + halfW)
          ..close();
        break;

      case NoriCaretSide.right:
        // Triangle pointing right from card right edge
        final tipY = caretOffset.clamp(halfW + _radius, h - halfW - _radius);
        final baseX = cardRect.right;
        path
          ..moveTo(baseX, tipY - halfW)
          ..lineTo(w, tipY)
          ..lineTo(baseX, tipY + halfW)
          ..close();
        break;
    }

    canvas.drawPath(path, Paint()..color = faceColor);
  }

  @override
  bool shouldRepaint(covariant _SpeechCardPainter old) =>
      old.caretSide != caretSide ||
      old.caretOffset != caretOffset ||
      old.faceColor != faceColor ||
      old.lipColor != lipColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED SPEECH CARD  — fades in/out, used by NoriCoachOverlay
// ─────────────────────────────────────────────────────────────────────────────

/// An [AnimatedSwitcher]-backed wrapper that animates card content changes
/// and fades in/out. Wraps [NoriSpeechCard] for use wherever a persistent
/// coaching card is needed (e.g. in-lesson surface).
class AnimatedNoriSpeechCard extends StatelessWidget {
  final String? text;
  final NoriCaretSide caretSide;
  final double caretOffset;
  final double maxWidth;

  const AnimatedNoriSpeechCard({
    super.key,
    this.text,
    this.caretSide = NoriCaretSide.bottom,
    this.caretOffset = 24.0,
    this.maxWidth = 180.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      ),
      child: text == null
          ? const SizedBox.shrink()
          : NoriSpeechCard(
              key: ValueKey(text),
              text: text!,
              caretSide: caretSide,
              caretOffset: caretOffset,
              maxWidth: maxWidth,
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NORI COACH OVERLAY  — in-lesson / video-batch surface
// ─────────────────────────────────────────────────────────────────────────────

/// Duo-equivalent in-lesson companion overlay.
///
/// Positions Nori at [verticalFraction] (default 0.35 = 35% from top) so the
/// blob never covers:
///   • the progress bar (top safe zone: [topSafeHeight])
///   • the bottom navigation bar (bottom safe zone: [bottomSafeHeight])
///
/// The [NoriSpeechCard] is placed using [NoriSpeechCard.autoPlace] to
/// guarantee it never overlaps the blob body (AGENTS.md non-overlap rule).
class NoriCoachOverlay extends StatefulWidget {
  /// Coaching message to show. Null = overlay hidden.
  final String? message;

  /// Emotion state for Nori (defaults to idle/happy when visible).
  final NoriEmotion emotion;

  /// Blob size in logical pixels.
  final double noriSize;

  /// Vertical fraction: how far from top of safe area to place Nori center.
  /// 0.35 = 35% down, matching Duolingo's constraintGuide_percent layout.
  final double verticalFraction;

  /// Height of the top safe zone (progress bar / app bar) in px.
  final double topSafeHeight;

  /// Height of the bottom safe zone (nav bar / bottom sheet) in px.
  final double bottomSafeHeight;

  const NoriCoachOverlay({
    super.key,
    this.message,
    this.emotion = NoriEmotion.idle,
    this.noriSize = 72.0,
    this.verticalFraction = 0.35,
    this.topSafeHeight = 56.0,
    this.bottomSafeHeight = 80.0,
  });

  @override
  State<NoriCoachOverlay> createState() => _NoriCoachOverlayState();
}

class _NoriCoachOverlayState extends State<NoriCoachOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  final GlobalKey _noriKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    if (widget.message != null) _fadeCtrl.forward();
  }

  @override
  void didUpdateWidget(covariant NoriCoachOverlay old) {
    super.didUpdateWidget(old);
    if (widget.message != null && old.message == null) {
      _fadeCtrl.forward();
    } else if (widget.message == null && old.message != null) {
      _fadeCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: widget.message == null,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: LayoutBuilder(builder: (context, constraints) {
          final totalH = constraints.maxHeight;
          final totalW = constraints.maxWidth;

          // Safe zone bounds
          final safeTop = widget.topSafeHeight;
          final safeBottom = totalH - widget.bottomSafeHeight;
          final safeH = safeBottom - safeTop;

          // Nori center position
          final noriCenterY = safeTop + safeH * widget.verticalFraction;
          final noriCenterX = totalW / 2;
          final noriLeft = noriCenterX - widget.noriSize / 2;
          final noriTop = noriCenterY - widget.noriSize / 2;

          final noriRect = Rect.fromLTWH(
            noriLeft, noriTop, widget.noriSize, widget.noriSize,
          );

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Nori blob at percentage-based anchor
              Positioned(
                left: noriLeft,
                top: noriTop,
                width: widget.noriSize,
                height: widget.noriSize,
                child: NoriBlobCharacter(
                  key: _noriKey,
                  size: widget.noriSize,
                ),
              ),

              // Speech card — auto-placed to NEVER cover the blob
              if (widget.message != null)
                NoriSpeechCard.autoPlace(
                  text: widget.message!,
                  noriRect: noriRect,
                  viewportSize: Size(totalW, totalH),
                  maxWidth: 190.0,
                ),
            ],
          );
        }),
      ),
    );
  }
}
