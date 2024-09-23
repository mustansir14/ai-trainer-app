import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;

  PosePainter(this.poses, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.fill;

    // Scale the canvas to fit the screen size
    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;

    for (Pose pose in poses) {
      for (PoseLandmark landmark in pose.landmarks.values) {
        // Get the x, y coordinates and scale them

        final double x = (landmark.x * scaleX) + 75;
        final double y = (landmark.y * scaleY) - 200;

        // Draw a small circle at each landmark position
        canvas.drawCircle(Offset(x, y), 10, paint);

        final textStyle = TextStyle(
          color: Colors.blue,
          fontSize: 12,
        );
        final textPainter = TextPainter(
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
        );

        // Create a text span for the label
        final textSpan = TextSpan(
          text: landmark.type.toString(),
          style: textStyle,
        );

        // Layout the text and paint it on the canvas
        textPainter.text = textSpan;
        textPainter.layout();
        textPainter.paint(
            canvas, Offset(x + 12, y - 6)); // Offset text near the circle
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
