import 'dart:math';
import 'dart:ui';

import 'package:dartchess/dartchess.dart';

/// Vector outlines of the six pieces in a 100 x 100 box (y grows downwards).
///
/// The shapes are original, drawn for this game: flat, bold silhouettes
/// that stay readable on a small phone square.
abstract final class PieceShapes {
  static final Map<Role, List<Path>> _bodies = {};
  static final Map<Role, Path> _bases = {};

  /// Upper parts of the piece (everything above the pedestal).
  static List<Path> body(Role role) => _bodies[role] ??= switch (role) {
    Role.pawn => _pawn(),
    Role.rook => _rook(),
    Role.knight => _knight(),
    Role.bishop => _bishop(),
    Role.queen => _queen(),
    Role.king => _king(),
  };

  /// The pedestal the piece stands on.
  static Path base(Role role) => _bases[role] ??= Path()
    ..addRRect(
      RRect.fromLTRBR(
        role == Role.pawn ? 24 : 20,
        78,
        role == Role.pawn ? 76 : 80,
        90,
        const Radius.circular(5),
      ),
    );

  static Path _rrect(double l, double t, double r, double b, double radius) =>
      Path()..addRRect(RRect.fromLTRBR(l, t, r, b, Radius.circular(radius)));

  static Path _circle(double x, double y, double radius) =>
      Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: radius));

  static List<Path> _pawn() => [
    _circle(50, 31, 13),
    _rrect(36, 44, 64, 50, 3),
    Path()
      ..moveTo(41, 50)
      ..cubicTo(41, 62, 31, 66, 29, 79)
      ..lineTo(71, 79)
      ..cubicTo(69, 66, 59, 62, 59, 50)
      ..close(),
  ];

  static List<Path> _rook() => [
    Path()
      ..moveTo(26, 14)
      ..lineTo(36, 14)
      ..lineTo(36, 22)
      ..lineTo(45, 22)
      ..lineTo(45, 14)
      ..lineTo(55, 14)
      ..lineTo(55, 22)
      ..lineTo(64, 22)
      ..lineTo(64, 14)
      ..lineTo(74, 14)
      ..lineTo(74, 33)
      ..lineTo(26, 33)
      ..close(),
    Path()
      ..moveTo(29, 33)
      ..lineTo(71, 33)
      ..lineTo(66, 42)
      ..lineTo(34, 42)
      ..close(),
    Path()
      ..moveTo(34, 42)
      ..lineTo(66, 42)
      ..lineTo(69, 72)
      ..lineTo(31, 72)
      ..close(),
    _rrect(26, 70, 74, 79, 3),
  ];

  static List<Path> _knight() => [
    Path()
      ..moveTo(30, 79)
      ..cubicTo(30, 65, 47, 61, 45, 47)
      ..lineTo(31, 53)
      ..cubicTo(24, 55, 19, 47, 24, 41)
      ..lineTo(42, 24)
      ..lineTo(44, 10)
      ..lineTo(54, 21)
      ..cubicTo(73, 26, 79, 55, 72, 79)
      ..close(),
  ];

  static List<Path> _bishop() => [
    _circle(50, 11, 5),
    Path()
      ..moveTo(50, 15)
      ..cubicTo(69, 28, 67, 47, 50, 55)
      ..cubicTo(33, 47, 31, 28, 50, 15)
      ..close(),
    _rrect(35, 53, 65, 60, 3),
    Path()
      ..moveTo(41, 60)
      ..cubicTo(41, 69, 32, 71, 30, 79)
      ..lineTo(70, 79)
      ..cubicTo(68, 71, 59, 69, 59, 60)
      ..close(),
  ];

  static List<Path> _queen() => [
    Path()
      ..moveTo(34, 61)
      ..lineTo(22, 30)
      ..lineTo(31, 46)
      ..lineTo(36, 22)
      ..lineTo(43, 44)
      ..lineTo(50, 18)
      ..lineTo(57, 44)
      ..lineTo(64, 22)
      ..lineTo(69, 46)
      ..lineTo(78, 30)
      ..lineTo(66, 61)
      ..close(),
    _circle(22, 28, 4.2),
    _circle(36, 20, 4.2),
    _circle(50, 16, 4.2),
    _circle(64, 20, 4.2),
    _circle(78, 28, 4.2),
    _rrect(32, 60, 68, 67, 3),
    Path()
      ..moveTo(36, 67)
      ..cubicTo(36, 72, 30, 75, 28, 79)
      ..lineTo(72, 79)
      ..cubicTo(70, 75, 64, 72, 64, 67)
      ..close(),
  ];

  static List<Path> _king() => [
    _rrect(47, 6, 53, 27, 1.5),
    _rrect(40, 12, 60, 18, 1.5),
    Path()
      ..moveTo(50, 35)
      ..cubicTo(44, 24, 25, 26, 25, 42)
      ..cubicTo(25, 53, 34, 56, 36, 63)
      ..lineTo(64, 63)
      ..cubicTo(66, 56, 75, 53, 75, 42)
      ..cubicTo(75, 26, 56, 24, 50, 35)
      ..close(),
    _rrect(32, 62, 68, 69, 3),
    Path()
      ..moveTo(36, 69)
      ..cubicTo(36, 73, 30, 76, 28, 79)
      ..lineTo(72, 79)
      ..cubicTo(70, 76, 64, 73, 64, 69)
      ..close(),
  ];

  /// Five-pointed star centred on ([cx], [cy]).
  static Path star(
    double cx,
    double cy,
    double radius, {
    double rotation = -pi / 2,
  }) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * 0.42;
      final angle = rotation + i * pi / 5;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path..close();
  }

  /// Crescent opening towards the right, centred on ([cx], [cy]).
  static Path crescent(
    double cx,
    double cy,
    double radius, {
    double thickness = 0.26,
  }) {
    final outer = _circle(cx, cy, radius);
    final inner = _circle(
      cx + radius * thickness * 1.5,
      cy,
      radius * (1 - thickness),
    );
    return Path.combine(PathOperation.difference, outer, inner);
  }
}
