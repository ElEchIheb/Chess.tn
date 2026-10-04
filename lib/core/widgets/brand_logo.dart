import 'package:flutter/material.dart';

import '../constants/app_branding.dart';
import '../theme/app_colors.dart';

/// The official chess.tn logo, exactly as supplied.
///
/// The image keeps its aspect ratio and is never tinted. With [onCard] it
/// sits on a white rounded card, which is how it is shown on the game's
/// dark screens (the lettering is black and parts of the mark are
/// transparent, so it needs a light surface).
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 200,
    this.onCard = true,
    this.emblemOnly = false,
  });

  /// Width of the logo (or of the card around it).
  final double size;
  final bool onCard;

  /// Shows the emblem without the wordmark (small spaces).
  final bool emblemOnly;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      emblemOnly ? AppBranding.emblem : AppBranding.logo,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: AppBranding.name,
    );
    if (!onCard) {
      return SizedBox(
        width: size,
        height: emblemOnly ? size / AppBranding.emblemAspectRatio : size,
        child: image,
      );
    }
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * (emblemOnly ? 0.14 : 0.04)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(size * 0.16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: image,
    );
  }
}
