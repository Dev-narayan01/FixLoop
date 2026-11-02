import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../preview/preview_models.dart';
import 'fix_loop_theme.dart';

/// Keeps the phone layout readable on larger web and tablet windows too.
class FixScreen extends StatelessWidget {
  const FixScreen({
    required this.title,
    required this.child,
    this.onBack,
    this.headerActions = const <Widget>[],
    this.showProfile = true,
    super.key,
  });

  final String title;
  final Widget child;
  final VoidCallback? onBack;
  final List<Widget> headerActions;
  final bool showProfile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Row(
                    children: <Widget>[
                      if (onBack != null)
                        IconButton(
                          tooltip: 'Back',
                          onPressed: onBack,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      if (onBack != null) const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          title,
                          style: text.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ...headerActions,
                      if (showProfile)
                        IconButton.filled(
                          tooltip: 'Account information',
                          onPressed: () => showAccountNotice(context),
                          style: IconButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                          ),
                          icon: const Icon(Icons.person_outline_rounded),
                        ),
                    ],
                  ),
                ),
                const PreviewNotice(),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void showAccountNotice(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Account', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            const Text('Sign-in is not available in this preview.'),
          ],
        ),
      ),
    ),
  );
}

class PreviewNotice extends StatelessWidget {
  const PreviewNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 2, 24, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.science_outlined, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Preview only · Nothing is sent to Fix Loop',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class StepProgress extends StatelessWidget {
  const StepProgress({required this.step, super.key});
  final int step;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Step $step of 4',
      child: ExcludeSemantics(
        child: Row(
          children: <Widget>[
            for (var i = 1; i <= 4; i++) ...<Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: i == step ? 25 : 9,
                height: 9,
                decoration: BoxDecoration(
                  color: i <= step ? colors.primary : colors.outlineVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              if (i != 4) const SizedBox(width: 5),
            ],
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'Step $step of 4',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrimaryAction extends StatelessWidget {
  const PrimaryAction({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final iconData = icon;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(child: Text(label, textAlign: TextAlign.center)),
            if (iconData != null) ...<Widget>[
              const SizedBox(width: 8),
              Icon(iconData, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.status, super.key});
  final PreviewStatus status;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (fill, foreground) = switch (status) {
      PreviewStatus.reported => dark
          ? (const Color(0xFF3A424D), const Color(0xFFC8D1DD))
          : (const Color(0xFFDDE3EA), const Color(0xFF3F4A58)),
      PreviewStatus.assigned => dark
          ? (const Color(0xFF1E3A5F), const Color(0xFFAFCBFF))
          : (const Color(0xFFD3E4FF), const Color(0xFF1D4E89)),
      PreviewStatus.inProgress => dark
          ? (const Color(0xFF4D3B00), const Color(0xFFFFDF8F))
          : (const Color(0xFFFFE29A), const Color(0xFF5B4300)),
      PreviewStatus.resolved => dark
          ? (const Color(0xFF00423B), const Color(0xFF9FF0E0))
          : (const Color(0xFFB4ECE0), const Color(0xFF00504A)),
      PreviewStatus.verified => dark
          ? (const Color(0xFF1E4D22), const Color(0xFFA8E6A0))
          : (const Color(0xFFC3EFB5), const Color(0xFF1B5E20)),
      PreviewStatus.reopened => (
          Theme.of(context).colorScheme.errorContainer,
          Theme.of(context).colorScheme.onErrorContainer,
        ),
      PreviewStatus.rejected => dark
          ? (const Color(0xFF3B3633), const Color(0xFFCFC8C3))
          : (const Color(0xFFE5E1DE), const Color(0xFF4A4643)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(status.icon, size: 16, color: foreground),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              status.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

enum MoonPhase { crescent, half, almostFull, full }

/// An asset-free rendering of the Stitch design's loop moon.
class MoonGraphic extends StatelessWidget {
  const MoonGraphic({required this.phase, this.size = 116, this.orbit = false, super.key});
  final MoonPhase phase;
  final double size;
  final bool orbit;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _MoonPainter(phase: phase, dark: dark, orbit: orbit),
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  const _MoonPainter({required this.phase, required this.dark, required this.orbit});
  final MoonPhase phase;
  final bool dark;
  final bool orbit;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * (orbit ? 0.37 : 0.47);
    final disk = Rect.fromCircle(center: center, radius: radius);
    final brown = dark ? FixPalette.darkPrimary : FixPalette.brownLight;
    final pale = dark ? const Color(0xFF68564B) : const Color(0xFFF2E5DD);

    if (orbit) {
      final orbitPaint = Paint()
        ..color = brown.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final orbitRect = Rect.fromCircle(center: center, radius: radius * 1.13);
      for (var i = 0; i < 36; i++) {
        canvas.drawArc(orbitRect, i * math.pi / 18, math.pi / 45, false, orbitPaint);
      }
    }

    if (phase == MoonPhase.full) {
      final green = dark ? const Color(0xFFA8E6A0) : FixPalette.green;
      canvas.drawCircle(center, radius, Paint()..color = dark ? FixPalette.darkCard : Colors.white);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = green
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      final checkPaint = Paint()
        ..color = green
        ..strokeWidth = radius * 0.09
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final check = Path()
        ..moveTo(center.dx - radius * 0.32, center.dy)
        ..lineTo(center.dx - radius * 0.08, center.dy + radius * 0.23)
        ..lineTo(center.dx + radius * 0.36, center.dy - radius * 0.25);
      canvas.drawPath(check, checkPaint);
      return;
    }

    canvas.drawCircle(center, radius, Paint()..color = brown);
    canvas.save();
    canvas.clipPath(Path()..addOval(disk));
    final shift = switch (phase) {
      MoonPhase.crescent => -radius * 0.72,
      MoonPhase.half => -radius,
      MoonPhase.almostFull => -radius * 0.22,
      MoonPhase.full => 0.0,
    };
    canvas.drawCircle(center.translate(shift, 0), radius, Paint()..color = pale);
    canvas.restore();
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = brown.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _MoonPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.dark != dark || oldDelegate.orbit != orbit;
}

class MoonArch extends StatelessWidget {
  const MoonArch({required this.child, this.height = 240, super.key});
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Leave room for larger system text instead of clipping the arch's contents.
        final textScale = MediaQuery.textScalerOf(context).scale(18) / 18;
        final extraHeight = (textScale - 1).clamp(0.0, 2.0) * 140;
        final effectiveHeight = height + extraHeight;
        final radius = Radius.elliptical(constraints.maxWidth / 2, effectiveHeight * 0.85);
        return Container(
          width: double.infinity,
          height: effectiveHeight,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.only(
              topLeft: radius,
              topRight: radius,
              bottomLeft: const Radius.circular(28),
              bottomRight: const Radius.circular(28),
            ),
          ),
          child: child,
        );
      },
    );
  }
}
