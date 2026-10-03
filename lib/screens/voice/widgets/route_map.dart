import 'package:flutter/material.dart';

import '../theme/voice_theme.dart';

/// A simple drawn route map (the app has no real map package).
///
/// The route line goes from the start (bottom) to the destination (top),
/// with the same turns as the hi-fi design. The filled circle shows how far
/// along the route the user is.
class RouteMap extends StatelessWidget {
  const RouteMap({super.key, required this.progress});

  /// 0.0 = at the start, 1.0 = arrived.
  final double progress;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RouteMapPainter(progress, context.palette),
      child: const SizedBox.expand(),
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  _RouteMapPainter(this.progress, this.palette);

  final double progress;
  final VoicePalette palette;

  // Route corners as fractions of the map size (0,0 = top left).
  static const List<Offset> _route = [
    Offset(0.5, 0.92), // start
    Offset(0.5, 0.62),
    Offset(0.1, 0.62),
    Offset(0.1, 0.32),
    Offset(0.5, 0.32),
    Offset(0.5, 0.08), // destination
  ];

  @override
  void paint(Canvas canvas, Size size) {
    Offset at(Offset f) => Offset(f.dx * size.width, f.dy * size.height);

    // Background and streets.
    canvas.drawRect(Offset.zero & size, Paint()..color = palette.navBackground);
    final street = Paint()..color = palette.mapStreet;
    const w = 16.0;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1 - w / 2, 0, w, size.height),
      street,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.66 - w / 2, 0, w, size.height),
      street,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.32 - w / 2, size.width, w),
      street,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.62 - w / 2, size.width, w),
      street,
    );

    // Route line.
    final points = _route.map(at).toList();
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = palette.mapRoute
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeJoin = StrokeJoin.round,
    );

    // Start and destination: white ring with a coloured centre.
    for (final p in [points.first, points.last]) {
      canvas.drawCircle(p, 10, Paint()..color = Colors.white);
      canvas.drawCircle(p, 5, Paint()..color = palette.mapRoute);
    }

    // "You are here".
    final you = _pointAlong(path, progress.clamp(0.0, 1.0));
    canvas.drawCircle(you, 12, Paint()..color = Colors.white);
    canvas.drawCircle(you, 8, Paint()..color = palette.primary);
  }

  // The point that is [fraction] of the way along [path].
  Offset _pointAlong(Path path, double fraction) {
    final metric = path.computeMetrics().first;
    final tangent = metric.getTangentForOffset(metric.length * fraction);
    return tangent?.position ?? Offset.zero;
  }

  @override
  bool shouldRepaint(_RouteMapPainter old) =>
      old.progress != progress || old.palette != palette;
}
