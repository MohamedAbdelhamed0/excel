import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'platform_factory.dart';

/// Riverpod provider for [PlatformServiceFactory].
/// This provider must be overridden in the [ProviderScope] of entry points
/// (`main_desktop.dart`, `main_mobile.dart`, or auto-detected in `main.dart`).
final platformFactoryProvider = Provider<PlatformServiceFactory>((ref) {
  throw UnimplementedError(
    'platformFactoryProvider must be overridden in main entry points via ProviderScope overrides.',
  );
});
