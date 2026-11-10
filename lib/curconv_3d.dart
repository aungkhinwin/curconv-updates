import 'package:flutter/material.dart';

const Color kCurconvTeal = Color(0xFF00796B);

bool curconvIsDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color curconvScaffoldColor(BuildContext context) => curconvIsDark(context)
    ? const Color(0xFF0F1716)
    : const Color(0xFFF3F7F8);

Color curconvCardColor(BuildContext context) =>
    curconvIsDark(context) ? const Color(0xFF1B2725) : Colors.white;

Color curconvTitleColor(BuildContext context) =>
    curconvIsDark(context) ? const Color(0xFFE6F1EF) : const Color(0xFF233331);

Color curconvSubtitleColor(BuildContext context) =>
    curconvIsDark(context) ? const Color(0xFFB7CBC7) : const Color(0xFF45615E);

Color curconvBorderColor(BuildContext context, Color accent, Color tint) =>
    curconvIsDark(context)
        ? accent.withValues(alpha: 0.6)
        : tint.withValues(alpha: 0.95);

/// Gradient background: light or dark depending on the theme.
BoxDecoration curconvBackground(BuildContext context) {
  final bool dark = curconvIsDark(context);
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: dark
          ? const <Color>[
              Color(0xFF0E1A18),
              Color(0xFF0F1716),
              Color(0xFF111A24),
            ]
          : const <Color>[
              Color(0xFFE4F5F1),
              Color(0xFFF5F7FA),
              Color(0xFFE9F0FB),
            ],
    ),
  );
}

/// Gradient icon frame used by the 3D cards.
Widget curconvIconFrame({
  required BuildContext context,
  required Widget child,
  required Color accent,
  required Color tint,
}) {
  final bool dark = curconvIsDark(context);
  return Container(
    width: 40,
    height: 40,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          curconvCardColor(context),
          dark ? accent.withValues(alpha: 0.25) : tint,
        ],
      ),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: accent.withValues(alpha: 0.24),
          blurRadius: 9,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

/// Raised 3D card, same look as the Menu cards.
class Curconv3DCard extends StatelessWidget {
  const Curconv3DCard({
    super.key,
    required this.leading,
    required this.title,
    required this.accent,
    required this.tint,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Color accent;
  final Color tint;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 400;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: curconvCardColor(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: curconvBorderColor(context, accent, tint),
              width: 1.4,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: accent.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 17,
              vertical: compact ? 8 : 10,
            ),
            child: Row(
              children: <Widget>[
                leading,
                SizedBox(width: compact ? 9 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        title,
                        style: TextStyle(
                          color: curconvTitleColor(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: accent,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: compact ? 6 : 10),
                trailing ??
                    Container(
                      width: compact ? 24 : 27,
                      height: compact ? 24 : 27,
                      decoration: BoxDecoration(
                        color: curconvIsDark(context)
                            ? accent.withValues(alpha: 0.25)
                            : tint,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_forward_rounded,
                          color: accent, size: compact ? 14 : 16),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Toggle switch that matches the reference image (teal on, grey off).
class Curconv3DSwitch extends StatelessWidget {
  const Curconv3DSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final bool dark = curconvIsDark(context);
    final Color offTrack =
        dark ? const Color(0xFF2C3A38) : const Color(0xFFDDE3E1);
    final Color offBorder =
        dark ? const Color(0xFF8A9996) : const Color(0xFF737F7C);
    final Color offKnob =
        dark ? const Color(0xFFB8C6C3) : const Color(0xFF5E6A67);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? kCurconvTeal : offTrack,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: value ? kCurconvTeal : offBorder,
            width: 2,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? Colors.white : offKnob,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

/// Generic 3D tile (same look as Curconv3DCard) that takes any widgets,
/// used by Settings rows so they keep their existing onTap logic.
class Curconv3DTile extends StatelessWidget {
  const Curconv3DTile({
    super.key,
    required this.leading,
    required this.title,
    required this.accent,
    required this.tint,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final Color accent;
  final Color tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 400;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: curconvCardColor(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: curconvBorderColor(context, accent, tint),
              width: 1.4,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: accent.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 17,
              vertical: compact ? 8 : 10,
            ),
            child: Row(
              children: <Widget>[
                curconvIconFrame(
                  context: context,
                  accent: accent,
                  tint: tint,
                  child: leading,
                ),
                SizedBox(width: compact ? 9 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      title,
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 3),
                        subtitle!,
                      ],
                    ],
                  ),
                ),
                SizedBox(width: compact ? 6 : 10),
                trailing ??
                    Container(
                      width: compact ? 24 : 27,
                      height: compact ? 24 : 27,
                      decoration: BoxDecoration(
                        color: curconvIsDark(context)
                            ? accent.withValues(alpha: 0.25)
                            : tint,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_forward_rounded,
                          color: accent, size: compact ? 14 : 16),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Raised 3D panel used as a container (e.g. account panel).
class Curconv3DPanel extends StatelessWidget {
  const Curconv3DPanel({
    super.key,
    required this.child,
    this.accent = kCurconvTeal,
  });

  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: curconvCardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: curconvBorderColor(context, accent, const Color(0xFFDDF7F2)),
          width: 1.4,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Storefront (awning shop) icon drawn with code, no image file needed.
class CurconvShopIcon extends StatelessWidget {
  const CurconvShopIcon({
    super.key,
    this.size = 28,
    this.color = Colors.white,
    this.strokeWidth = 2.0,
  });

  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.8),
      painter: _CurconvShopIconPainter(color: color, strokeWidth: strokeWidth),
    );
  }
}

class _CurconvShopIconPainter extends CustomPainter {
  _CurconvShopIconPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final double w = size.width;
    final double h = size.height;

    // Awning: slightly wider at the bottom, like a real shop awning.
    final double awningTop = h * 0.08;
    final double awningBottom = h * 0.36;
    final Path awning = Path()
      ..moveTo(w * 0.12, awningTop)
      ..lineTo(w * 0.88, awningTop)
      ..lineTo(w * 0.96, awningBottom)
      ..lineTo(w * 0.04, awningBottom)
      ..close();
    canvas.drawPath(awning, paint);

    // Stripe dividers inside the awning.
    for (final double x in <double>[0.32, 0.50, 0.68]) {
      final double t = (x - 0.5) * 0.08; // slight slant that follows the roof
      canvas.drawLine(
        Offset(w * (x + t * 0.0), awningTop),
        Offset(w * (x + t * 1.4), awningBottom),
        paint,
      );
    }

    // Scalloped valance under the awning (3 soft arcs).
    final double seg = w * 0.92 / 3;
    for (int i = 0; i < 3; i++) {
      final double x0 = w * 0.04 + seg * i;
      final Path scallop = Path()
        ..moveTo(x0, awningBottom)
        ..quadraticBezierTo(
          x0 + seg / 2,
          awningBottom + h * 0.12,
          x0 + seg,
          awningBottom,
        );
      canvas.drawPath(scallop, paint);
    }

    // Shop body (open at the top, sits under the valance).
    final double bodyTop = h * 0.46;
    final double bodyBottom = h * 0.92;
    final Path body = Path()
      ..moveTo(w * 0.16, bodyTop)
      ..lineTo(w * 0.16, bodyBottom)
      ..lineTo(w * 0.84, bodyBottom)
      ..lineTo(w * 0.84, bodyTop);
    canvas.drawPath(body, paint);

    // Door with a rounded top.
    final RRect door = RRect.fromRectAndCorners(
      Rect.fromLTRB(w * 0.42, h * 0.66, w * 0.58, bodyBottom),
      topLeft: Radius.circular(w * 0.05),
      topRight: Radius.circular(w * 0.05),
    );
    canvas.drawRRect(door, paint);
  }

  @override
  bool shouldRepaint(covariant _CurconvShopIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Scroll-and-quill (records) icon drawn with code, outline style.
/// Coordinates follow a 900 x 900 design grid and are scaled to [size].
class CurconvScrollIcon extends StatelessWidget {
  const CurconvScrollIcon({
    super.key,
    this.size = 28,
    this.color = Colors.white,
    this.strokeWidth = 2.0,
  });

  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CurconvScrollIconPainter(color: color, strokeWidth: strokeWidth),
    );
  }
}

class _CurconvScrollIconPainter extends CustomPainter {
  _CurconvScrollIconPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on a 500-unit grid, matching the reference artwork.
    const double maxDim = 431;
    final double s = size.width * 0.82 / maxDim; // leave margin like Material icons
    canvas.save();
    canvas.translate(size.width / 2 - 265.5 * s, size.height / 2 - 220 * s);
    canvas.scale(s);

    final Paint p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Paper outline: left edge with rounded top, top edge, right edge
    canvas.drawPath(
      Path()
        ..moveTo(97, 352)
        ..lineTo(97, 70)
        ..quadraticBezierTo(97, 35, 132, 35)
        ..lineTo(355, 35)
        ..lineTo(355, 395),
      p,
    );

    // Top-right roll
    canvas.drawPath(
      Path()
        ..moveTo(355, 45)
        ..quadraticBezierTo(395, 35, 410, 60)
        ..quadraticBezierTo(422, 80, 420, 100)
        ..lineTo(355, 100),
      p,
    );

    // Text lines
    canvas.drawLine(const Offset(135, 85), const Offset(318, 85), p);
    canvas.drawLine(const Offset(135, 140), const Offset(318, 140), p);
    canvas.drawLine(const Offset(135, 195), const Offset(318, 195), p);
    canvas.drawLine(const Offset(135, 250), const Offset(318, 250), p);
    canvas.drawLine(const Offset(135, 305), const Offset(240, 305), p);

    // Bottom roll with curl
    canvas.drawPath(
      Path()
        ..moveTo(50, 352)
        ..lineTo(295, 352)
        ..lineTo(295, 378)
        ..quadraticBezierTo(295, 405, 330, 405)
        ..lineTo(355, 405)
        ..quadraticBezierTo(355, 395, 355, 395)
        ..moveTo(50, 352)
        ..quadraticBezierTo(50, 405, 100, 405)
        ..lineTo(330, 405),
      p,
    );

    // Quill: tilted oval nib and shaft
    canvas.save();
    canvas.translate(395, 190);
    canvas.rotate(-0.6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 160, height: 72),
      p,
    );
    canvas.restore();
    canvas.drawLine(const Offset(280, 305), const Offset(400, 205), p);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CurconvScrollIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Saved-info icon (address book with avatar and index tabs), outline style.
/// Drawn on a 1000 x 1000 grid and scaled to [size].
class CurconvSaveInfoIcon extends StatelessWidget {
  const CurconvSaveInfoIcon({
    super.key,
    this.size = 28,
    this.color = Colors.white,
    this.strokeWidth = 2.0,
  });

  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CurconvSaveInfoIconPainter(color: color, strokeWidth: strokeWidth),
    );
  }
}

class _CurconvSaveInfoIconPainter extends CustomPainter {
  _CurconvSaveInfoIconPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // Address book / profile icon, drawn on a 1254-unit grid from the reference.
    // Content spans x 96..1132, y 128..1127 (incl. 1 px border); fit it to ~20 px.
    final double s = size.width * 0.82 / 1036;
    canvas.save();
    canvas.translate(size.width / 2 - 614 * s, size.height / 2 - 627.5 * s);
    canvas.scale(s);

    const Color white = Color(0xFFFFFFFF);
    const Color pinkCover = Color(0xFFF7B6CC);
    const Color profileLight = Color(0xFF79C5F2);
    const Color profileDark = Color(0xFF08A9E8);
    const Color binder = Color(0xFF77869B);
    const double outline = 52; // ~1.0 px white border at this scale

    final RRect book = RRect.fromRectAndRadius(
      const Rect.fromLTRB(238, 180, 1080, 1075),
      const Radius.circular(90),
    );
    final RRect strip = RRect.fromRectAndRadius(
      const Rect.fromLTRB(982, 333, 1060, 1075),
      const Radius.circular(40),
    );
    final List<RRect> rings = <RRect>[
      for (final double cy in <double>[370, 620, 877])
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(233, cy), width: 170, height: 74),
          const Radius.circular(37),
        ),
    ];

    // 1. White outer outline around the book, tabs and binder rings
    final Paint whiteOutline = Paint()
      ..color = white
      ..style = PaintingStyle.stroke
      ..strokeWidth = outline * 2
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(book, whiteOutline);
    canvas.drawRRect(strip, whiteOutline);
    for (final RRect r in rings) {
      canvas.drawRRect(r, whiteOutline);
    }
    canvas.drawRRect(book, Paint()..color = white);
    canvas.drawRRect(strip, Paint()..color = white);

    // 2. Cover
    canvas.drawRRect(book, Paint()..color = pinkCover);

    // 3. Binder rings
    for (final RRect r in rings) {
      canvas.drawRRect(r, Paint()..color = binder);
    }

    // 4. Index tabs (orange, blue, pink, red) on the right edge
    const List<(double, double, Color)> tabs = <(double, double, Color)>[
      (333, 510, Color(0xFFFF927E)),
      (530, 697, Color(0xFF45BDEB)),
      (718, 888, Color(0xFFF34D9A)),
      (915, 1075, Color(0xFFFF4655)),
    ];
    for (final (double top, double bottom, Color color) in tabs) {
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTRB(982, top, 1060, bottom),
          bottomRight: const Radius.circular(45),
          topRight: const Radius.circular(12),
        ),
        Paint()..color = color,
      );
    }

    // 5. Profile circle: white ring, light blue fill
    const Offset centre = Offset(640, 528);
    canvas.drawCircle(centre, 232, Paint()..color = white);
    canvas.drawCircle(centre, 205, Paint()..color = profileLight);

    // Person: head with white ring, shoulders clipped by the circle
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: centre, radius: 205)));
    canvas.drawCircle(const Offset(640, 455), 88, Paint()..color = white);
    canvas.drawCircle(const Offset(640, 455), 60, Paint()..color = profileDark);
    canvas.drawPath(
      Path()
        ..moveTo(470, 760)
        ..lineTo(470, 690)
        ..quadraticBezierTo(470, 580, 640, 580)
        ..quadraticBezierTo(810, 580, 810, 690)
        ..lineTo(810, 760)
        ..close(),
      Paint()..color = white,
    );
    canvas.drawPath(
      Path()
        ..moveTo(492, 760)
        ..lineTo(492, 690)
        ..quadraticBezierTo(492, 605, 640, 605)
        ..quadraticBezierTo(788, 605, 788, 690)
        ..lineTo(788, 760)
        ..close(),
      Paint()..color = profileDark,
    );
    canvas.restore();

    // 6. Two white text lines under the profile
    final Paint line = Paint()..color = white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(500, 825, 772, 862),
        const Radius.circular(18),
      ),
      line,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(445, 918, 826, 955),
        const Radius.circular(18),
      ),
      line,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CurconvSaveInfoIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// History icon: user inside a circle with a clock badge (outline style).
/// Drawn on a 1000-unit grid and scaled to [size].
class CurconvHistoryIcon extends StatelessWidget {
  const CurconvHistoryIcon({
    super.key,
    this.size = 24,
    this.color = Colors.white,
    this.strokeWidth = 2.0,
  });

  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: size * 0.82,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2.0),
              ),
            ),
          ),
          CustomPaint(
            size: Size.square(size),
            painter: _CurconvHistoryIconPainter(
              color: color,
              strokeWidth: strokeWidth,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurconvHistoryIconPainter extends CustomPainter {
  _CurconvHistoryIconPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    const double maxDim = 920;
    final double s = size.width * 0.82 / maxDim; // leave margin like Material icons
    canvas.save();
    canvas.translate(size.width / 2 - 500 * s, size.height / 2 - 500 * s);
    canvas.scale(s);

    final Paint p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // User: head
    canvas.drawCircle(const Offset(440, 380), 120, p);
    // User: shoulders
    canvas.drawPath(
      Path()
        ..moveTo(260, 760)
        ..quadraticBezierTo(280, 560, 440, 560)
        ..quadraticBezierTo(560, 560, 590, 690),
      p,
    );

    // Clock badge (bottom-right)
    canvas.drawPath(
      Path()..addOval(Rect.fromCircle(center: const Offset(720, 720), radius: 150)),
      p,
    );
    canvas.drawLine(const Offset(720, 720), const Offset(720, 630), p);
    canvas.drawLine(const Offset(720, 720), const Offset(785, 720), p);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CurconvHistoryIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Trash (delete mode) icon, outline style, drawn with code.
/// Drawn on a 1000-unit grid and scaled to [size].
class CurconvTrashIcon extends StatelessWidget {
  const CurconvTrashIcon({
    super.key,
    this.size = 24,
    this.color = Colors.white,
    this.strokeWidth = 1.0,
  });

  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CurconvTrashIconPainter(color: color, strokeWidth: strokeWidth),
    );
  }
}

class _CurconvTrashIconPainter extends CustomPainter {
  _CurconvTrashIconPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    const double maxDim = 740;
    final double s = size.width * 0.82 / maxDim; // leave margin like Material icons
    canvas.save();
    canvas.translate(size.width / 2 - 500 * s, size.height / 2 - 530 * s);
    canvas.scale(s);

    final Paint p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Lid
    canvas.drawLine(const Offset(150, 260), const Offset(850, 260), p);

    // Handle
    canvas.drawPath(
      Path()
        ..moveTo(390, 260)
        ..lineTo(390, 200)
        ..quadraticBezierTo(390, 160, 430, 160)
        ..lineTo(570, 160)
        ..quadraticBezierTo(610, 160, 610, 200)
        ..lineTo(610, 260),
      p,
    );

    // Bin body
    canvas.drawPath(
      Path()
        ..moveTo(230, 260)
        ..lineTo(280, 840)
        ..quadraticBezierTo(285, 900, 345, 900)
        ..lineTo(655, 900)
        ..quadraticBezierTo(715, 900, 720, 840)
        ..lineTo(770, 260),
      p,
    );

    // Inner ribs
    canvas.drawLine(const Offset(410, 380), const Offset(425, 780), p);
    canvas.drawLine(const Offset(500, 380), const Offset(500, 780), p);
    canvas.drawLine(const Offset(590, 380), const Offset(575, 780), p);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CurconvTrashIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Edit icon (pen inside a circle), outline style, drawn with code.
class CurconvEditIcon extends StatelessWidget {
  const CurconvEditIcon({
    super.key,
    this.size = 22,
    this.color = Colors.white,
    this.strokeWidth = 1.0,
    this.filled = false,
  });

  final double size;
  final Color color;
  final double strokeWidth;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CurconvEditIconPainter(
        color: color,
        strokeWidth: strokeWidth,
        filled: filled,
      ),
    );
  }
}

class _CurconvEditIconPainter extends CustomPainter {
  _CurconvEditIconPainter({
    required this.color,
    required this.strokeWidth,
    required this.filled,
  });

  final Color color;
  final double strokeWidth;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    // pen-to-square: rounded square with a pen inside, drawn on a 1000 grid
    const double maxDim = 860;
    final double s = size.width * 0.82 / maxDim;
    canvas.save();
    canvas.translate(size.width / 2 - 500 * s, size.height / 2 - 500 * s);
    canvas.scale(s);

    final Paint p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Square with an open top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(560, 120)
        ..lineTo(260, 120)
        ..quadraticBezierTo(120, 120, 120, 260)
        ..lineTo(120, 740)
        ..quadraticBezierTo(120, 880, 260, 880)
        ..lineTo(740, 880)
        ..quadraticBezierTo(880, 880, 880, 740)
        ..lineTo(880, 440),
      p,
    );

    // Pen, tilted 45 degrees with the tip pointing down-left
    canvas.save();
    canvas.translate(560, 440);
    canvas.rotate(0.785);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-70, -260, 140, 340),
        const Radius.circular(25),
      ),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-70, 80)
        ..lineTo(0, 210)
        ..lineTo(70, 80),
      p,
    );
    canvas.drawLine(const Offset(-70, -170), const Offset(70, -170), p);
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CurconvEditIconPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.filled != filled;
}

/// Share icon (three connected nodes), outline style, drawn with code.
class CurconvShareIcon extends StatelessWidget {
  const CurconvShareIcon({
    super.key,
    this.size = 22,
    this.color = Colors.white,
    this.strokeWidth = 1.0,
  });

  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CurconvShareIconPainter(color: color, strokeWidth: strokeWidth),
    );
  }
}

class _CurconvShareIconPainter extends CustomPainter {
  _CurconvShareIconPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // Font Awesome "share-nodes" (thin) look: three rings joined by thin links.
    const double maxDim = 620;
    final double s = size.width * 0.82 / maxDim;
    canvas.save();
    canvas.translate(size.width / 2 - 500 * s, size.height / 2 - 500 * s);
    canvas.scale(s);

    final Paint p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const Offset top = Offset(700, 280);
    const Offset left = Offset(300, 500);
    const Offset bottom = Offset(700, 720);

    canvas.drawLine(left, top, p);
    canvas.drawLine(left, bottom, p);
    canvas.drawPath(
      Path()..addOval(Rect.fromCircle(center: top, radius: 85)),
      p,
    );
    canvas.drawPath(
      Path()..addOval(Rect.fromCircle(center: left, radius: 85)),
      p,
    );
    canvas.drawPath(
      Path()..addOval(Rect.fromCircle(center: bottom, radius: 85)),
      p,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CurconvShareIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
