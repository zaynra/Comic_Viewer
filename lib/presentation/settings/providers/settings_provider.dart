import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ReadingMode {
  single('Halaman Tunggal'),
  doublePage('Halaman Ganda'),
  vertical('Vertical Scroll');

  const ReadingMode(this.label);
  final String label;
}

enum FitMode {
  fitScreen('Fit to Screen'),
  fitWidth('Fit Width'),
  fitHeight('Fit Height'),
  original('Ukuran Asli');

  const FitMode(this.label);
  final String label;
}

enum OrientationMode {
  auto('Otomatis'),
  portrait('Portrait'),
  landscape('Landscape');

  const OrientationMode(this.label);
  final String label;
}

class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.readingDirection = ReadingDirection.leftToRight,
    this.readingMode = ReadingMode.single,
    this.fitMode = FitMode.fitScreen,
    this.orientationMode = OrientationMode.auto,
    this.keepScreenOn = true,
    this.readingBrightness = 1.0,
    this.darkOverlay = 0.0,
    this.autoContinue = true,
  });

  final ThemeMode themeMode;
  final ReadingDirection readingDirection;
  final ReadingMode readingMode;
  final FitMode fitMode;
  final OrientationMode orientationMode;
  final bool keepScreenOn;
  final double readingBrightness;
  final double darkOverlay;
  final bool autoContinue;

  SettingsState copyWith({
    ThemeMode? themeMode,
    ReadingDirection? readingDirection,
    ReadingMode? readingMode,
    FitMode? fitMode,
    OrientationMode? orientationMode,
    bool? keepScreenOn,
    double? readingBrightness,
    double? darkOverlay,
    bool? autoContinue,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      readingDirection: readingDirection ?? this.readingDirection,
      readingMode: readingMode ?? this.readingMode,
      fitMode: fitMode ?? this.fitMode,
      orientationMode: orientationMode ?? this.orientationMode,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      readingBrightness: readingBrightness ?? this.readingBrightness,
      darkOverlay: darkOverlay ?? this.darkOverlay,
      autoContinue: autoContinue ?? this.autoContinue,
    );
  }
}

enum ReadingDirection {
  leftToRight('Kiri ke Kanan'),
  rightToLeft('Kanan ke Kiri'),
  vertical('Vertikal');

  const ReadingDirection(this.label);
  final String label;
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._prefs) : super(const SettingsState()) {
    _loadSettings();
  }

  final SharedPreferences _prefs;

  void _loadSettings() {
    final themeIndex = _prefs.getInt('theme_mode') ?? 2;
    final directionIndex = _prefs.getInt('reading_direction') ?? 0;
    final readingModeIndex = _prefs.getInt('reading_mode') ?? 0;
    final fitModeIndex = _prefs.getInt('fit_mode') ?? 0;
    final orientationIndex = _prefs.getInt('orientation_mode') ?? 0;
    final keepScreenOn = _prefs.getBool('keep_screen_on') ?? true;
    final readingBrightness = _prefs.getDouble('reading_brightness') ?? 1.0;
    final darkOverlay = _prefs.getDouble('dark_overlay') ?? 0.0;
    final autoContinue = _prefs.getBool('auto_continue') ?? true;

    state = SettingsState(
      themeMode: ThemeMode.values[themeIndex],
      readingDirection: ReadingDirection.values[directionIndex],
      readingMode: ReadingMode.values[readingModeIndex],
      fitMode: FitMode.values[fitModeIndex],
      orientationMode: OrientationMode.values[orientationIndex],
      keepScreenOn: keepScreenOn,
      readingBrightness: readingBrightness,
      darkOverlay: darkOverlay,
      autoContinue: autoContinue,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setInt('theme_mode', mode.index);
  }

  Future<void> setReadingDirection(ReadingDirection direction) async {
    state = state.copyWith(readingDirection: direction);
    await _prefs.setInt('reading_direction', direction.index);
  }

  Future<void> setReadingMode(ReadingMode mode) async {
    state = state.copyWith(readingMode: mode);
    await _prefs.setInt('reading_mode', mode.index);
  }

  Future<void> setFitMode(FitMode mode) async {
    state = state.copyWith(fitMode: mode);
    await _prefs.setInt('fit_mode', mode.index);
  }

  Future<void> setOrientationMode(OrientationMode mode) async {
    state = state.copyWith(orientationMode: mode);
    await _prefs.setInt('orientation_mode', mode.index);
  }

  Future<void> setKeepScreenOn(bool value) async {
    state = state.copyWith(keepScreenOn: value);
    await _prefs.setBool('keep_screen_on', value);
  }

  Future<void> setReadingBrightness(double value) async {
    state = state.copyWith(readingBrightness: value);
    await _prefs.setDouble('reading_brightness', value);
  }

  Future<void> setDarkOverlay(double value) async {
    state = state.copyWith(darkOverlay: value);
    await _prefs.setDouble('dark_overlay', value);
  }

  Future<void> setAutoContinue(bool value) async {
    state = state.copyWith(autoContinue: value);
    await _prefs.setBool('auto_continue', value);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden at app startup');
});
