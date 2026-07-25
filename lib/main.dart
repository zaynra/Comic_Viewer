import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/settings/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('=== FLUTTER ERROR ===');
    debugPrint('${details.exception}');
    debugPrint('${details.stack}');
    debugPrint('=====================');
  };

  final prefs = await SharedPreferences.getInstance();

  runZonedGuarded(() {
    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const ComicViewerApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('=== ZONE ERROR ===');
    debugPrint('$error');
    debugPrint('$stack');
    debugPrint('==================');
  });
}

class ComicViewerApp extends ConsumerWidget {
  const ComicViewerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'Comic Viewer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      routerConfig: router,
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          debugPrint('=== WIDGET ERROR ===');
          debugPrint('${details.exception}');
          debugPrint('${details.stack}');
          debugPrint('====================');
          return Material(
            color: Colors.red.shade900,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'ERROR:\n${details.exception}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          );
        };
        return child ?? const SizedBox();
      },
    );
  }
}
