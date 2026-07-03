import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/DI/platform_factory.dart';
import 'core/DI/platform_providers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/table_analyzer/presentation/controllers/theme_controller.dart';

/// Desktop Entry Point.
/// Initializes DesktopServiceFactory, executes desktop hooks, and overrides Riverpod provider.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final desktopFactory = DesktopServiceFactory();
  await desktopFactory.getInitializer().initialize();

  runApp(
    ProviderScope(
      overrides: [
        platformFactoryProvider.overrideWithValue(desktopFactory),
      ],
      child: const ExcelAiApp(),
    ),
  );
}

class ExcelAiApp extends ConsumerWidget {
  const ExcelAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Excel & CSV AI Analyzer (Desktop)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
