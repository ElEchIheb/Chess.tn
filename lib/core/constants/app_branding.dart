/// The official chess.tn brand, in one place.
///
/// The logo is a supplied asset: it is always shown as-is (never redrawn,
/// recoloured or stretched) and, because parts of it are transparent and
/// its lettering is black, always on a white surface.
abstract final class AppBranding {
  /// Official product name. Always lowercase.
  static const String name = 'chess.tn';

  /// Full logo: emblem, wordmark and tagline.
  static const String logo = 'assets/branding/chess_tn_logo.png';

  /// Emblem only, cropped from [logo] by `tool/build_brand_assets.dart`.
  static const String emblem = 'assets/branding/chess_tn_emblem.png';

  /// Width / height of [emblem].
  static const double emblemAspectRatio = 415 / 865;

  static const int copyrightYear = 2026;
}
