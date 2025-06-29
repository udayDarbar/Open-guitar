import 'package:flutter/material.dart';

class FretboardPainter extends CustomPainter {
  final List<int> frets;
  final List<int> fingers;
  FretboardPainter(this.frets, this.fingers);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey;
    const margin = 20.0;
    final width = size.width - margin * 2;
    final height = size.height - margin * 2;
    final stringGap = width / 5;
    final fretGap = height / 4;
    for (int i = 0; i < 6; i++) {
      final x = margin + i * stringGap;
      canvas.drawLine(Offset(x, margin), Offset(x, margin + height), paint);
    }
    for (int j = 0; j < 5; j++) {
      final y = margin + j * fretGap;
      canvas.drawLine(Offset(margin, y), Offset(margin + width, y), paint);
    }
    for (int i = 0; i < frets.length; i++) {
      final fret = frets[i];
      if (fret < 0) continue;
      final x = margin + i * stringGap;
      final y = margin + (fret - 1) * fretGap + fretGap / 2;
      canvas.drawCircle(Offset(x, y), 10, Paint()..color = Colors.tealAccent);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

