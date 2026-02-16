import 'dart:math';
import 'package:flutter/material.dart';

class CosmicBackground extends StatefulWidget {
  final Widget child;
  const CosmicBackground({super.key, required this.child});

  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends State<CosmicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat();
    _t = CurvedAnimation(parent: _c, curve: Curves.linear);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        return CustomPaint(
          painter: _CosmicPainter(t: _t.value),
          child: widget.child,
        );
      },
    );
  }
}

class _CosmicPainter extends CustomPainter {
  final double t;
  _CosmicPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Pearl/cosmic gradient
    final g = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [
        Color(0xFF05050B),
        Color(0xFF0A0A16),
        Color(0xFF08081F),
        Color(0xFF0C0720),
      ],
      stops: const [0.0, 0.35, 0.7, 1.0],
    );
    final paint = Paint()..shader = g.createShader(rect);
    canvas.drawRect(rect, paint);

    // Soft nebula highlight (subtle motion)
    final center = Offset(size.width * (0.5 + 0.08 * sin(2 * pi * t)),
        size.height * (0.2 + 0.06 * cos(2 * pi * t)));
    final nebula = RadialGradient(
      colors: [
        const Color(0xFF7C4DFF).withOpacity(0.18),
        const Color(0xFF00E5FF).withOpacity(0.10),
        Colors.transparent,
      ],
      stops: const [0.0, 0.35, 1.0],
    );
    canvas.drawCircle(
      center,
      size.shortestSide * 0.75,
      Paint()..shader = nebula.createShader(rect),
    );

    // Stars
    final rng = Random(1337);
    final stars = 120;
    for (var i = 0; i < stars; i++) {
      final x = rng.nextDouble() * size.width;
      var y = rng.nextDouble() * size.height;
      y = (y + t * 20) % size.height; // slow drift
      final r = rng.nextDouble() * 1.2 + 0.2;
      final o = rng.nextDouble() * 0.35 + 0.05;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = Colors.white.withOpacity(o),
      );
    }

    // Vignette
    final v = RadialGradient(
      colors: [
        Colors.transparent,
        Colors.black.withOpacity(0.55),
      ],
      stops: const [0.55, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = v.createShader(rect));
  }

  @override
  bool shouldRepaint(covariant _CosmicPainter oldDelegate) => oldDelegate.t != t;
}
