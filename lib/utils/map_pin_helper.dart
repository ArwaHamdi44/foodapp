import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Helper class to generate custom pin images for Mapbox map annotations
class MapPinHelper {
  /// Generate a custom user location pin image
  static Future<ui.Image> generateUserLocationPin() async {
    const size = 48.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // Draw outer circle (shadow effect)
    paint.color = Colors.blue.withOpacity(0.2);
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 2,
      paint,
    );

    // Draw main circle (blue background)
    paint.color = Colors.blue;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 4,
      paint,
    );

    // Draw inner white circle
    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 8,
      paint,
    );

    // Draw location icon (dot)
    paint.color = Colors.blue;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      6,
      paint,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    return image;
  }

  /// Generate a custom restaurant pin image
  static Future<ui.Image> generateRestaurantPin() async {
    const size = 48.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // Draw pin shape (teardrop)
    final path = Path();
    path.moveTo(size / 2, 0);
    path.arcToPoint(
      Offset(size, size / 2),
      radius: const Radius.circular(size / 2),
      clockwise: false,
    );
    path.arcToPoint(
      Offset(size / 2, size),
      radius: const Radius.circular(size / 2),
      clockwise: false,
    );
    path.lineTo(size / 2, size * 0.75);
    path.close();

    // Draw shadow
    paint.color = const Color(0xFFC23232).withOpacity(0.3);
    canvas.drawPath(path, paint);

    // Draw main pin body (red)
    paint.color = const Color(0xFFC23232);
    final mainPath = Path();
    mainPath.moveTo(size / 2, 2);
    mainPath.arcToPoint(
      Offset(size - 2, size / 2),
      radius: const Radius.circular(size / 2 - 2),
      clockwise: false,
    );
    mainPath.arcToPoint(
      Offset(size / 2, size - 2),
      radius: const Radius.circular(size / 2 - 2),
      clockwise: false,
    );
    mainPath.lineTo(size / 2, size * 0.75);
    mainPath.close();
    canvas.drawPath(mainPath, paint);

    // Draw white circle for icon
    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 3,
      paint,
    );

    // Draw fork and knife icon (simplified)
    paint.color = const Color(0xFFC23232);
    paint.strokeWidth = 2.5;
    paint.style = PaintingStyle.stroke;
    paint.strokeCap = StrokeCap.round;

    // Fork (left side)
    canvas.drawLine(
      Offset(size / 2 - 6, size / 2 - 4),
      Offset(size / 2 - 6, size / 2 + 4),
      paint,
    );
    canvas.drawLine(
      Offset(size / 2 - 8, size / 2 - 2),
      Offset(size / 2 - 4, size / 2 - 2),
      paint,
    );
    canvas.drawLine(
      Offset(size / 2 - 8, size / 2),
      Offset(size / 2 - 4, size / 2),
      paint,
    );

    // Knife (right side)
    canvas.drawLine(
      Offset(size / 2 + 6, size / 2 - 4),
      Offset(size / 2 + 6, size / 2 + 4),
      paint,
    );
    canvas.drawLine(
      Offset(size / 2 + 4, size / 2 - 2),
      Offset(size / 2 + 8, size / 2 - 2),
      paint,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    return image;
  }

  /// Convert ui.Image to bytes for Mapbox
  static Future<Uint8List> imageToBytes(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}

