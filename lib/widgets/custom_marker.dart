import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';

/// Creates a custom marker icon with provider avatar/initials
class CustomMarker {
  static Future<BitmapDescriptor> createMarkerIcon({
    required String? providerName,
    required double? rating,
    Color? backgroundColor,
    String? avatarUrl,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = 120.0;
    final radius = size / 2;

    // Determine color based on rating
    Color markerColor;
    if (rating == null) {
      markerColor = backgroundColor ?? Colors.green;
    } else if (rating >= 4.5) {
      markerColor = Colors.green;
    } else if (rating >= 4.0) {
      markerColor = Colors.orange;
    } else if (rating >= 3.0) {
      markerColor = Colors.orangeAccent;
    } else {
      markerColor = Colors.red;
    }

    // Draw outer shadow circle
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(
      Offset(radius, radius + 2),
      radius - 2,
      shadowPaint,
    );

    // Draw main circle with gradient
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        markerColor,
        markerColor.withOpacity(0.8),
      ],
    );
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius),
      );
    canvas.drawCircle(Offset(radius, radius), radius - 4, paint);

    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset(radius, radius), radius - 4, borderPaint);

    // Draw inner circle (for avatar or initials)
    final innerRadius = radius - 12;
    final innerPaint = Paint()..color = Colors.white.withOpacity(0.2);
    canvas.drawCircle(Offset(radius, radius), innerRadius, innerPaint);

    // Draw text (initials or rating)
    final textPainter = TextPainter(
      text: TextSpan(
        text: rating != null
            ? rating.toStringAsFixed(1)
            : (providerName?.isNotEmpty == true
                ? providerName![0].toUpperCase()
                : '?'),
        style: TextStyle(
          color: Colors.white,
          fontSize: innerRadius * 0.6,
          fontWeight: FontWeight.bold,
          letterSpacing: 0,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        radius - textPainter.width / 2,
        radius - textPainter.height / 2,
      ),
    );

    // Draw small pin point at bottom
    final pinPath = Path()
      ..moveTo(radius, size - 8)
      ..lineTo(radius - 8, size - 20)
      ..lineTo(radius + 8, size - 20)
      ..close();
    final pinPaint = Paint()
      ..color = markerColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(pinPath, pinPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  /// Creates a custom "current location" marker
  static Future<BitmapDescriptor> createCurrentLocationIcon() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = 80.0;
    final radius = size / 2;

    // Outer pulsing circle
    final outerPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(radius, radius), radius - 4, outerPaint);

    // Middle circle
    final middlePaint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(radius, radius), radius - 12, middlePaint);

    // Inner dot
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(radius, radius), radius - 20, innerPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }
}
