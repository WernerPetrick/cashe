import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// The design's small uppercase mono label ("TOTAL BALANCE", "HISTORY").
class MonoLabel extends StatelessWidget {
  const MonoLabel(this.text, {super.key, this.color = CasheColors.muted});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontFamily: mono,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.9,
      color: color,
    ),
  );
}

/// The rounded outline "Home" / "Cancel" / "Back" button at the top of screens.
class PillButton extends StatelessWidget {
  const PillButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        foregroundColor: CasheColors.textSoft,
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(label),
    ),
  );
}

class CasheLogo extends StatelessWidget {
  const CasheLogo({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * 0.26),
    child: Image.asset(
      'assets/images/cashe-logo.png',
      width: size,
      height: size,
    ),
  );
}

/// The amber progress ring used for pots: [progress] of the ring is amber, the
/// rest is the dark track, with an optional dotted inner ring and a centre child.
class RingDial extends StatelessWidget {
  const RingDial({
    super.key,
    required this.size,
    required this.progress,
    this.thickness,
    this.dotted = false,
    this.child,
  });

  final double size;
  final double progress;
  final double? thickness;
  final bool dotted;
  final Widget? child;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _RingPainter(
        progress: progress.clamp(0, 1).toDouble(),
        thickness: thickness ?? size * 0.076,
        dotted: dotted,
      ),
      child: Center(child: child),
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.thickness,
    required this.dotted,
  });

  final double progress;
  final double thickness;
  final bool dotted;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ring = rect.deflate(thickness / 2);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    canvas.drawArc(
      ring,
      0,
      math.pi * 2,
      false,
      stroke..color = CasheColors.track,
    );
    if (progress > 0) {
      canvas.drawArc(
        ring,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        stroke..color = CasheColors.amber,
      );
    }
    if (dotted) _dots(canvas, size);
  }

  void _dots(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.width / 2 - thickness - size.width * 0.1;
    final dot = Paint()..color = CasheColors.dots;
    const count = 36;
    for (var i = 0; i < count; i++) {
      final angle = math.pi * 2 * i / count;
      canvas.drawCircle(
        centre + Offset(math.cos(angle), math.sin(angle)) * radius,
        1.6,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.thickness != thickness ||
      old.dotted != dotted;
}

/// Two amber rings pulsing outwards: "tap your phone here".
class PulseRings extends StatefulWidget {
  const PulseRings({super.key, required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  State<PulseRings> createState() => _PulseRingsState();
}

class _PulseRingsState extends State<PulseRings>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.size,
    child: AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => Stack(
        alignment: Alignment.center,
        children: [
          _ring(_controller.value),
          _ring((_controller.value + 0.5) % 1),
          child!,
        ],
      ),
      child: widget.child,
    ),
  );

  Widget _ring(double t) => Transform.scale(
    scale: 0.6 + t,
    child: Opacity(
      opacity: (0.7 * (1 - t)).clamp(0, 1).toDouble(),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: CasheColors.amber, width: 2),
        ),
      ),
    ),
  );
}

/// Fills the available height (so Spacers work) and scrolls instead of
/// overflowing on short screens.
class FillOrScroll extends StatelessWidget {
  const FillOrScroll({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(child: child),
        ),
      ),
    );
  }
}
