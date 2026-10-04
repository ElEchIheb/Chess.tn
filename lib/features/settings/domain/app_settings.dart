import 'package:flutter/material.dart';

import '../../../core/theme/board_theme.dart';
import '../../ai/domain/ai_level.dart';

/// Languages of the game. Tunisian Arabic (Darija) is the default.
enum AppLanguage {
  darija(Locale('ar')),
  english(Locale('en')),
  french(Locale('fr'));

  const AppLanguage(this.locale);

  final Locale locale;

  static AppLanguage fromCode(String? code) =>
      values.where((l) => l.locale.languageCode == code).firstOrNull ??
      AppLanguage.darija;
}

@immutable
class AppSettings {
  const AppSettings({
    this.language = AppLanguage.darija,
    this.sound = true,
    this.music = false,
    this.vibration = true,
    this.boardTheme = BoardTheme.tunisian,
    this.pieceTheme = PieceTheme.tunisian,
    this.showLegalMoves = true,
    this.animations = true,
    this.aiLevel = AiLevel.medium,
  });

  final AppLanguage language;
  final bool sound;
  final bool music;
  final bool vibration;
  final BoardTheme boardTheme;
  final PieceTheme pieceTheme;
  final bool showLegalMoves;
  final bool animations;
  final AiLevel aiLevel;

  AppSettings copyWith({
    AppLanguage? language,
    bool? sound,
    bool? music,
    bool? vibration,
    BoardTheme? boardTheme,
    PieceTheme? pieceTheme,
    bool? showLegalMoves,
    bool? animations,
    AiLevel? aiLevel,
  }) => AppSettings(
    language: language ?? this.language,
    sound: sound ?? this.sound,
    music: music ?? this.music,
    vibration: vibration ?? this.vibration,
    boardTheme: boardTheme ?? this.boardTheme,
    pieceTheme: pieceTheme ?? this.pieceTheme,
    showLegalMoves: showLegalMoves ?? this.showLegalMoves,
    animations: animations ?? this.animations,
    aiLevel: aiLevel ?? this.aiLevel,
  );
}
