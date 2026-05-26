import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeKey = 'pref_theme_mode';

class ThemeNotifier extends Notifier<ThemeMode> {
  ThemeNotifier([this._initial = ThemeMode.light]);
  final ThemeMode _initial;

  @override
  ThemeMode build() => _initial;

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kThemeKey, next == ThemeMode.dark ? 'dark' : 'light');
  }
}

final themeNotifierProvider =
    NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

/// Call in [main()] after [WidgetsFlutterBinding.ensureInitialized()].
/// Loads the persisted [ThemeMode] from SharedPreferences and initializes the provider.
Future<void> initThemeProvider(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kThemeKey);
  final themeMode = raw == 'dark' ? ThemeMode.dark : ThemeMode.light;
  // Update the provider's state to match the persisted value
  ref.read(themeNotifierProvider.notifier).state = themeMode;
}

/// Internal: Loads the persisted [ThemeMode] from SharedPreferences.
Future<ThemeMode> loadPersistedTheme() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kThemeKey);
  return raw == 'dark' ? ThemeMode.dark : ThemeMode.light;
}
