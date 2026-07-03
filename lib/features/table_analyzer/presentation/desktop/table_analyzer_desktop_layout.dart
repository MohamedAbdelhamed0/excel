import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/DI/platform_providers.dart';
import '../../../recent_files/presentation/recent_files_dialog.dart';
import '../controllers/excel_data_controller.dart';
import '../controllers/theme_controller.dart';
import '../widgets/ai_analysis_panel.dart';
import '../widgets/data_table_view.dart';

/// Desktop-optimized layout: Persistent navigation rail, horizontal split-pane workspace, AI sidebar panel, and desktop status bar.
class TableAnalyzerDesktopLayout extends ConsumerWidget {
  const TableAnalyzerDesktopLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(excelDataControllerProvider);
    final themeState = ref.watch(themeProvider);
    final platformFactory = ref.watch(platformFactoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          // Desktop Persistent Sidebar Navigation
          NavigationRail(
            selectedIndex: 0,
            extended: true,
            minExtendedWidth: 200,
            backgroundColor: theme.colorScheme.surface,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                children: [
                  Icon(Icons.analytics, color: theme.colorScheme.primary, size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    'Excel AI Pro',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.table_chart_outlined),
                selectedIcon: Icon(Icons.table_chart),
                label: Text('Analyzer'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: Text('Recent Files'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
            onDestinationSelected: (index) {
              if (index == 1) {
                RecentFilesDialog.show(context);
              } else if (index == 2) {
                context.push('/settings');
              }
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),

          // Workspace Area
          Expanded(
            child: Column(
              children: [
                // Desktop Top Header & Toolbar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Spreadsheet Intelligence Dashboard',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Platform Context: ${platformFactory.platformName} • Engine: Isolate Threading',
                              style: TextStyle(fontSize: 12, color: theme.hintColor),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.read(excelDataControllerProvider.notifier).pickAndLoadFile();
                          },
                          icon: const Icon(Icons.file_open),
                          label: const Text('Open File (Ctrl+O)'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            RecentFilesDialog.show(context);
                          },
                          icon: const Icon(Icons.history),
                          label: const Text('Recent Files'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            ref.read(excelDataControllerProvider.notifier).loadSampleData();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reload Sample'),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: Icon(
                            themeState.mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                          ),
                          tooltip: 'Toggle Light/Dark Theme',
                          onPressed: () {
                            ref.read(themeProvider.notifier).toggleTheme();
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Split Pane: Left (Data Grid View) & Right (AI Analysis Panel)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: asyncData.when(
                      data: (state) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main Data Grid View (Left Split)
                            Expanded(
                              flex: 3,
                              child: DataTableView(workspaceState: state),
                            ),
                            const SizedBox(width: 16),
                            // AI Analysis Panel (Right Split - Fixed Width)
                            SizedBox(
                              width: 380,
                              child: AiAnalysisPanel(tableState: state.activeTableState),
                            ),
                          ],
                        );
                      },
                      loading: () => Center(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 36.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 20),
                                const Text(
                                  'Parsing & Indexing Spreadsheet Data...',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Offloading binary file processing to background Isolate thread',
                                  style: TextStyle(color: theme.hintColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      error: (err, stack) => Center(child: Text('Error loading data: $err')),
                    ),
                  ),
                ),

                // Desktop Bottom Status Bar & Keyboard Hints
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Icon(Icons.keyboard, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Shortcuts: Ctrl+O (Open) | Click Headers (Sort) | Type to Filter',
                          style: TextStyle(fontSize: 11, color: theme.hintColor),
                        ),
                        const SizedBox(width: 32),
                        Text(
                          'Status: ${asyncData.isLoading ? "Parsing..." : "Ready"} | Isolate Multithreading Enabled',
                          style: TextStyle(fontSize: 11, color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
