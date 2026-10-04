import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/audio/sound_service.dart';
import 'core/constants/app_branding.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/splash_screen.dart';
import 'features/settings/application/settings_controller.dart';
import 'l10n/app_localizations.dart';

class ChessTnApp extends ConsumerStatefulWidget {
  const ChessTnApp({super.key, this.home, this.fontFamily});

  /// First screen; defaults to the splash. Tests start on a given screen.
  final Widget? home;

  /// Overrides the app font (used when rendering screenshots).
  final String? fontFamily;

  @override
  ConsumerState<ChessTnApp> createState() => _ChessTnAppState();
}

class _ChessTnAppState extends ConsumerState<ChessTnApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncMusic());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _syncMusic({bool foreground = true}) {
    ref
        .read(soundServiceProvider)
        .setMusic(playing: foreground && ref.read(settingsProvider).music);
  }

  // No music while the app is in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _syncMusic(foreground: state == AppLifecycleState.resumed);

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsProvider.select((s) => s.music), (_, _) => _syncMusic());
    final locale = ref.watch(settingsProvider.select((s) => s.language.locale));

    return MaterialApp(
      title: AppBranding.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(fontFamily: widget.fontFamily),
      // Tunisian Arabic is the default whatever the phone language is; the
      // player switches in the settings.
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: widget.home ?? const SplashScreen(),
    );
  }
}
