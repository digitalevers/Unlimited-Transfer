import 'dart:math';
import 'package:flutter/material.dart';

class WaterRipple extends StatefulWidget {
  final int count;
  final Color color;

  const WaterRipple(
      {Key? key,
      this.count = 3,
      this.color = const Color.fromARGB(9, 92, 173, 255)})
      : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _WaterRippleState createState() => _WaterRippleState();
}

class _WaterRippleState extends State<WaterRipple>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: WaterRipplePainter(_controller.value,
              count: widget.count, color: widget.color),
        );
      },
    );
  }
}

class WaterRipplePainter extends CustomPainter {
  final double progress;
  final int count;
  final Color color;

  final Paint _paint = Paint()..style = PaintingStyle.fill;

  WaterRipplePainter(this.progress,
      {this.count = 3, this.color = const Color(0xFF0080ff)});

  @override
  void paint(Canvas canvas, Size size) {
    double radius = min(size.width, size.height);

    for (int i = count; i >= 0; i--) {
      final double opacity = (1.0 - ((i + progress) / (count + 1)));
      // ignore: no_leading_underscores_for_local_identifiers
      final Color _color = color.withOpacity(opacity);
      _paint.color = _color;

      // ignore: no_leading_underscores_for_local_identifiers
      double _radius = radius * ((i + progress) / (count + 1));

      // canvas.drawCircle(
      //     Offset(size.width / 2, size.height / 2), _radius, _paint);

      Paint line = Paint()
        ..color = _color
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      //画圆方法
      canvas.drawCircle(Offset(size.width / 2, size.height), _radius, line);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
