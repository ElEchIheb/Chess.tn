import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Colours of one chess board style.
@immutable
class BoardColors {
  const BoardColors({
    required this.light,
    required this.dark,
    required this.frame,
    required this.coordinateOnLight,
    required this.coordinateOnDark,
    this.selected = const Color(0xB3F2C94C),
    this.lastMove = const Color(0x73F2C94C),
    this.check = const Color(0xFFFF3B3B),
    this.moveDot = const Color(0x55101010),
    this.woodGrain = false,
  });

  final Color light;
  final Color dark;
  final Color frame;
  final Color coordinateOnLight;
  final Color coordinateOnDark;
  final Color selected;
  final Color lastMove;
  final Color check;
  final Color moveDot;

  /// Draws subtle grain lines over the squares.
  final bool woodGrain;
}

enum BoardTheme {
  tunisian(
    BoardColors(
      light: Color(0xFFF4E7CF),
      dark: Color(0xFFA5222A),
      frame: AppColors.redDeep,
      coordinateOnLight: Color(0xFFA5222A),
      coordinateOnDark: Color(0xFFF4E7CF),
      moveDot: Color(0x66140608),
    ),
  ),
  classic(
    BoardColors(
      light: Color(0xFFEEEED2),
      dark: Color(0xFF769656),
      frame: Color(0xFF3C4A2E),
      coordinateOnLight: Color(0xFF769656),
      coordinateOnDark: Color(0xFFEEEED2),
    ),
  ),
  dark(
    BoardColors(
      light: Color(0xFF8A93A6),
      dark: Color(0xFF3B4252),
      frame: Color(0xFF1C2029),
      coordinateOnLight: Color(0xFF3B4252),
      coordinateOnDark: Color(0xFFB8C0D0),
      moveDot: Color(0x77000000),
    ),
  ),
  wood(
    BoardColors(
      light: Color(0xFFEFD8B0),
      dark: Color(0xFFB07B4F),
      frame: Color(0xFF5B3A21),
      coordinateOnLight: Color(0xFF8A5A35),
      coordinateOnDark: Color(0xFFF5E3C3),
      woodGrain: true,
    ),
  );

  const BoardTheme(this.colors);

  final BoardColors colors;

  static BoardTheme fromName(String? name) =>
      values.where((t) => t.name == name).firstOrNull ?? BoardTheme.tunisian;
}

/// Colours of one piece style, for one side.
@immutable
class PieceColors {
  const PieceColors({
    required this.fill,
    required this.shade,
    required this.outline,
    required this.detail,
  });

  final Color fill;

  /// Darker tone used for the lower part / inner shading.
  final Color shade;
  final Color outline;

  /// Accent used for small ornaments (crescent, star, eye, slit).
  final Color detail;
}

enum PieceTheme {
  /// Ivory with deep-red line work; charcoal with gold ornaments.
  tunisian(
    white: PieceColors(
      fill: Color(0xFFFFFBF2),
      shade: Color(0xFFE9DCC3),
      outline: Color(0xFF6E1016),
      detail: Color(0xFFE31B23),
    ),
    black: PieceColors(
      fill: Color(0xFF26262C),
      shade: Color(0xFF131317),
      outline: Color(0xFF050506),
      detail: Color(0xFFF2C94C),
    ),
    ornaments: true,
  ),
  classic(
    white: PieceColors(
      fill: Color(0xFFFDFDFD),
      shade: Color(0xFFDADADA),
      outline: Color(0xFF2B2B2B),
      detail: Color(0xFF2B2B2B),
    ),
    black: PieceColors(
      fill: Color(0xFF3A3A3A),
      shade: Color(0xFF1E1E1E),
      outline: Color(0xFF0A0A0A),
      detail: Color(0xFFE8E8E8),
    ),
    ornaments: false,
  );

  const PieceTheme({
    required this.white,
    required this.black,
    required this.ornaments,
  });

  final PieceColors white;
  final PieceColors black;

  /// Crescent on the king and a star on the queen.
  final bool ornaments;

  static PieceTheme fromName(String? name) =>
      values.where((t) => t.name == name).firstOrNull ?? PieceTheme.tunisian;
}
