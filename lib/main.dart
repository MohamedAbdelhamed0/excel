import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/DI/platform_factory.dart';
import 'core/DI/platform_providers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/table_analyzer/presentation/controllers/theme_controller.dart';

/// Fallback Entry Point.
/// Dynamically evaluates defaultTargetPlatform / kIsWeb to select and initialize the appropriate factory.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final PlatformServiceFactory platformFactory = _resolvePlatformFactory();
  await platformFactory.getInitializer().initialize();

  runApp(
    ProviderScope(
      overrides: [
        platformFactoryProvider.overrideWithValue(platformFactory),
      ],
      child: const ExcelAiApp(),
    ),
  );
}

PlatformServiceFactory _resolvePlatformFactory() {
  if (kIsWeb) {
    return WebFallbackServiceFactory();
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.windows:
    case TargetPlatform.macOS:
    case TargetPlatform.linux:
      return DesktopServiceFactory();
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      return MobileServiceFactory();
    case TargetPlatform.fuchsia:
      return WebFallbackServiceFactory();
  }
}

class ExcelAiApp extends ConsumerWidget {
  const ExcelAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Excel & CSV AI Analyzer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(themeState.palette),
      darkTheme: AppTheme.getDarkTheme(themeState.palette),
      themeMode: themeState.mode,
      routerConfig: appRouter,
    );
  }
}
