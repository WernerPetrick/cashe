import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/cashe_widgets.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: _LoadingLogo(size: 88)));
}

/// The logo drawn live, its amber arc filling and emptying while we load.
class _LoadingLogo extends StatefulWidget {
  const _LoadingLogo({required this.size});

  final double size;

  @override
  State<_LoadingLogo> createState() => _LoadingLogoState();
}

class _LoadingLogoState extends State<_LoadingLogo>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  late final _progress = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading',
    child: AnimatedBuilder(
      animation: _progress,
      builder: (_, child) => RingDial(
        size: widget.size,
        progress: 0.1 + 0.9 * _progress.value,
        dotted: true,
        child: child,
      ),
      child: Container(
        width: widget.size * 0.26,
        height: widget.size * 0.26,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: CasheColors.amber,
        ),
      ),
    ),
  );
}
