import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/DI/platform_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../table_analyzer/presentation/controllers/theme_controller.dart';

/// App Settings Screen providing theme mode, color palette preferences, and platform information.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final platformFactory = ref.watch(platformFactoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Configuration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Theme Mode Section
          Text(
            'Appearance Mode',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: RadioGroup<ThemeMode>(
              groupValue: themeState.mode,
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeProvider.notifier).setThemeMode(mode);
                }
              },
              child: const Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: Text('System Default'),
                    value: ThemeMode.system,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text('Light Mode'),
                    value: ThemeMode.light,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text('Dark Mode'),
                    value: ThemeMode.dark,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Color Palette Section
          Text(
            'Color Palette',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select a primary accent palette for the workspace UI:',
                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: AppColorPalette.values.map((palette) {
                      final isSelected = themeState.palette == palette;
                      return ChoiceChip(
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            ref.read(themeProvider.notifier).setColorPalette(palette);
                          }
                        },
                        avatar: CircleAvatar(
                          backgroundColor: palette.primaryColor,
                          radius: 8,
                        ),
                        label: Text(palette.label),
                        selectedColor: palette.primaryColor.withValues(alpha: 0.2),
                        side: isSelected
                            ? BorderSide(color: palette.primaryColor, width: 1.5)
                            : null,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Platform & DI Information Section
          Text(
            'Platform & Dependency Injection',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.devices),
                  title: const Text('Platform Factory Target'),
                  subtitle: Text(platformFactory.platformName),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: const Text('File Picker Service'),
                  subtitle: Text(platformFactory.getFilePicker().pickerName),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.build_circle_outlined),
                  title: const Text('Architecture Pattern'),
                  subtitle: const Text('Clean Architecture + Abstract Factory DI + Riverpod'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
