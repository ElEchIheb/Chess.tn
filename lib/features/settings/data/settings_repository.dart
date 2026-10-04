import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/board_theme.dart';
import '../../ai/domain/ai_level.dart';
import '../domain/app_settings.dart';

/// Stores the settings on the device. No account, no cloud.
class SettingsRepository {
  const SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _language = 'language';
  static const _sound = 'sound';
  static const _music = 'music';
  static const _vibration = 'vibration';
  static const _boardTheme = 'boardTheme';
  static const _pieceTheme = 'pieceTheme';
  static const _showLegalMoves = 'showLegalMoves';
  static const _animations = 'animations';
  static const _aiLevel = 'aiLevel';

  AppSettings load() {
    const defaults = AppSettings();
    return AppSettings(
      language: AppLanguage.fromCode(_prefs.getString(_language)),
      sound: _prefs.getBool(_sound) ?? defaults.sound,
      music: _prefs.getBool(_music) ?? defaults.music,
      vibration: _prefs.getBool(_vibration) ?? defaults.vibration,
      boardTheme: BoardTheme.fromName(_prefs.getString(_boardTheme)),
      pieceTheme: PieceTheme.fromName(_prefs.getString(_pieceTheme)),
      showLegalMoves:
          _prefs.getBool(_showLegalMoves) ?? defaults.showLegalMoves,
      animations: _prefs.getBool(_animations) ?? defaults.animations,
      aiLevel: AiLevel.fromNumber(
        _prefs.getInt(_aiLevel) ?? defaults.aiLevel.number,
      ),
    );
  }

  Future<void> save(AppSettings settings) async {
    await Future.wait([
      _prefs.setString(_language, settings.language.locale.languageCode),
      _prefs.setBool(_sound, settings.sound),
      _prefs.setBool(_music, settings.music),
      _prefs.setBool(_vibration, settings.vibration),
      _prefs.setString(_boardTheme, settings.boardTheme.name),
      _prefs.setString(_pieceTheme, settings.pieceTheme.name),
      _prefs.setBool(_showLegalMoves, settings.showLegalMoves),
      _prefs.setBool(_animations, settings.animations),
      _prefs.setInt(_aiLevel, settings.aiLevel.number),
    ]);
  }
}
