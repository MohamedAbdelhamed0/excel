import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';

/// State holding ThemeMode and AppColorPalette preferences.
class ThemeState {
  final ThemeMode mode;
  final AppColorPalette palette;

  const ThemeState({
    this.mode = ThemeMode.system,
    this.palette = AppColorPalette.blue,
  });

  ThemeState copyWith({
    ThemeMode? mode,
    AppColorPalette? palette,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      palette: palette ?? this.palette,
    );
  }
}

/// Riverpod Notifier for managing app appearance (ThemeMode & Color Palette).
class ThemeNotifier extends Notifier<ThemeState> {
  @override
  ThemeState build() {
    return const ThemeState();
  }

  void toggleTheme() {
    final nextMode = state.mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = state.copyWith(mode: nextMode);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setColorPalette(AppColorPalette palette) {
    state = state.copyWith(palette: palette);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(() {
  return ThemeNotifier();
});
