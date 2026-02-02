import 'package:flutter/material.dart';
import 'package:proballdev/features/map/map_view_model.dart';
import 'package:proballdev/models/map_point.dart';

/// Abstract indoor map: room zones, ball path, high-activity highlights.
/// Coordinates: room 5x4 units (x 0-5, y 0-4).
/// Not real GPS — schematic floor plan only. Dark mode ready.
class IndoorMapWidget extends StatelessWidget {
  const IndoorMapWidget({
    super.key,
    required this.positions,
    required this.activityZones,
    required this.roomZones,
    this.colorScheme,
  });

  final List<MapPoint> positions;
  final List<ActivityZone> activityZones;
  final List<MapZone> roomZones;
  final ColorScheme? colorScheme;

  static const double roomWidth = 5.0;
  static const double roomHeight = 4.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _IndoorMapPainter(
            positions: positions,
            activityZones: activityZones,
            roomZones: roomZones,
            roomWidth: roomWidth,
            roomHeight: roomHeight,
            colorScheme: colorScheme ?? const ColorScheme.light(),
          ),
        );
      },
    );
  }
}

class _IndoorMapPainter extends CustomPainter {
  _IndoorMapPainter({
    required this.positions,
    required this.activityZones,
    required this.roomZones,
    required this.roomWidth,
    required this.roomHeight,
    required this.colorScheme,
  });

  final List<MapPoint> positions;
  final List<ActivityZone> activityZones;
  final List<MapZone> roomZones;
  final double roomWidth;
  final double roomHeight;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 48.0;
    final usableW = size.width - padding * 2;
    final usableH = size.height - padding * 2;

    double scaleX(double x) => padding + (x / roomWidth) * usableW;
    double scaleY(double y) => padding + (y / roomHeight) * usableH;

    // Room outline
    final roomRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(padding, padding, usableW, usableH),
      const Radius.circular(12),
    );
    final isDark = colorScheme.brightness == Brightness.dark;
    final borderColor = isDark
        ? colorScheme.outline.withValues(alpha: 0.4)
        : const Color(0xFFE2E8F0);
    final zoneBg = isDark
        ? colorScheme.surfaceContainerHighest
        : const Color(0xFFF1F5F9);
    final labelColor = colorScheme.onSurfaceVariant;

    canvas.drawRRect(
      roomRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Zone labels (light background)
    for (final z in roomZones) {
      final rect = Rect.fromLTRB(
        scaleX(z.xMin),
        scaleY(z.yMin),
        scaleX(z.xMax),
        scaleY(z.yMax),
      ).deflate(4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()
          ..color = zoneBg
          ..style = PaintingStyle.fill,
      );
    }

    // High-activity zone highlights
    for (final az in activityZones) {
      final cx = scaleX(az.x);
      final cy = scaleY(az.y);
      final radius = 24.0 + az.intensity * 20;
      final hotColor = colorScheme.tertiary;
      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()
          ..color = hotColor.withValues(alpha: 0.2 * az.intensity)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()
          ..color = hotColor.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Ball path
    if (positions.length >= 2) {
      final path = Path();
      path.moveTo(scaleX(positions[0].x), scaleY(positions[0].y));
      for (var i = 1; i < positions.length; i++) {
        path.lineTo(scaleX(positions[i].x), scaleY(positions[i].y));
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = colorScheme.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      // Path glow (subtle)
      canvas.drawPath(
        path,
        Paint()
          ..color = colorScheme.primary.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      // Start marker (green)
      final start = positions.first;
      canvas.drawCircle(
        Offset(scaleX(start.x), scaleY(start.y)),
        6,
        Paint()
          ..color = colorScheme.secondary
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(scaleX(start.x), scaleY(start.y)),
        6,
        Paint()
          ..color = colorScheme.surface
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // End marker (primary)
      final end = positions.last;
      canvas.drawCircle(
        Offset(scaleX(end.x), scaleY(end.y)),
        8,
        Paint()
          ..color = colorScheme.primary
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(scaleX(end.x), scaleY(end.y)),
        8,
        Paint()
          ..color = colorScheme.surface
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Zone labels text
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    for (final z in roomZones) {
      final cx = (scaleX(z.xMin) + scaleX(z.xMax)) / 2;
      final cy = (scaleY(z.yMin) + scaleY(z.yMax)) / 2;
      textPainter.text = TextSpan(
        text: z.name,
        style: TextStyle(
          color: labelColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IndoorMapPainter oldDelegate) {
    return oldDelegate.positions.length != positions.length ||
        oldDelegate.activityZones.length != activityZones.length ||
        oldDelegate.positions != positions;
  }
}
