import 'package:flutter/material.dart';

const canvasSize = 100;

typedef Point = ({int x, int y});

class DrawCanvas extends StatelessWidget {
  final List<List<Color?>> points;
  final void Function(int x, int y) onDraw;

  const DrawCanvas({
    super.key,
    required this.points,
    required this.onDraw,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.grey.shade400,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Listener(
            onPointerDown: (event) => _drawPixel(constraints, event),
            onPointerMove: (event) => _drawPixel(constraints, event),
            child: CustomPaint(
              painter: _CanvasPainter(points),
            ),
          ),
        ),
      ),
    );
  }

  void _drawPixel(BoxConstraints constraints, PointerEvent event) {
    final size = constraints.maxWidth;
    // Ignore events outside the canvas bounds
    if (!Rect.fromLTWH(0, 0, size, size).contains(event.localPosition)) return;

    final px = (event.localPosition.dx / size * canvasSize).floor();
    final py = (event.localPosition.dy / size * canvasSize).floor();
    onDraw(px, py);
  }
}

class _CanvasPainter extends CustomPainter {
  final List<List<Color?>> points;

  final pointPaint = Paint();

  final gridPaint = Paint()..color = Colors.grey.shade100;

  _CanvasPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / canvasSize;

    for (int x = 0; x < canvasSize; x++) {
      for (int y = 0; y < canvasSize; y++) {
        final color = points[x][y];
        if (color != null) {
          pointPaint.color = color;
          canvas.drawRect(
              Rect.fromLTWH(x * step, y * step, step, step), pointPaint);
        }
      }
    }

    for (var i = 1; i < canvasSize; i++) {
      final p = i * step;
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), gridPaint);
      canvas.drawLine(Offset(0, p), Offset(size.width, p), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
