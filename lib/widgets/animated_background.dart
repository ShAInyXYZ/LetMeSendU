import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<FloatingShape> _shapes;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _shapes = List.generate(6, (index) => FloatingShape.random(index));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppTheme.gradientColors,
            ),
          ),
        ),
        // Animated floating shapes
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: ShapesPainter(
                shapes: _shapes,
                progress: _controller.value,
              ),
              size: Size.infinite,
            );
          },
        ),
        // Gradient overlay for depth
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topRight,
              radius: 1.5,
              colors: [
                AppTheme.primary.withOpacity(0.15),
                Colors.transparent,
              ],
            ),
          ),
        ),
        // Content
        widget.child,
      ],
    );
  }
}

class FloatingShape {
  final double x;
  final double y;
  final double size;
  final Color color;
  final ShapeType type;
  final double speed;
  final double phase;

  FloatingShape({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.type,
    required this.speed,
    required this.phase,
  });

  factory FloatingShape.random(int index) {
    final random = Random(index * 42);
    final colors = AppTheme.shapeColors
        .map((c) => c.withOpacity(0.25))
        .toList();

    return FloatingShape(
      x: random.nextDouble(),
      y: random.nextDouble(),
      size: 40 + random.nextDouble() * 80,
      color: colors[random.nextInt(colors.length)],
      type: ShapeType.values[random.nextInt(ShapeType.values.length)],
      speed: 0.5 + random.nextDouble() * 1.5,
      phase: random.nextDouble() * 2 * pi,
    );
  }
}

enum ShapeType { circle, square, triangle }

class ShapesPainter extends CustomPainter {
  final List<FloatingShape> shapes;
  final double progress;

  ShapesPainter({required this.shapes, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var shape in shapes) {
      final paint = Paint()
        ..color = shape.color
        ..style = PaintingStyle.fill;

      final angle = progress * 2 * pi * shape.speed + shape.phase;
      final dx = sin(angle) * 30;
      final dy = cos(angle * 0.7) * 20;

      final x = shape.x * size.width + dx;
      final y = shape.y * size.height + dy;

      switch (shape.type) {
        case ShapeType.circle:
          canvas.drawCircle(Offset(x, y), shape.size / 2, paint);
          break;
        case ShapeType.square:
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(angle * 0.3);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: shape.size,
                height: shape.size,
              ),
              Radius.circular(shape.size * 0.2),
            ),
            paint,
          );
          canvas.restore();
          break;
        case ShapeType.triangle:
          final path = Path();
          final halfSize = shape.size / 2;
          path.moveTo(x, y - halfSize);
          path.lineTo(x - halfSize, y + halfSize);
          path.lineTo(x + halfSize, y + halfSize);
          path.close();
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(angle * 0.2);
          canvas.translate(-x, -y);
          canvas.drawPath(path, paint);
          canvas.restore();
          break;
      }
    }
  }

  @override
  bool shouldRepaint(ShapesPainter oldDelegate) => true;
}
