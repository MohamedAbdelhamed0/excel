import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/DI/platform_providers.dart';
import '../controllers/excel_data_controller.dart';
import '../controllers/theme_controller.dart';
import '../widgets/ai_analysis_panel.dart';
import '../widgets/data_table_view.dart';

/// Mobile-optimized layout: Vertical hierarchy, scrollable table view, floating action button, and AI bottom sheet.
class TableAnalyzerMobileLayout extends ConsumerWidget {
  const TableAnalyzerMobileLayout({super.key});

  void _showAiBottomSheet(BuildContext context, TableDataState tableState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: AiAnalysisPanel(tableState: tableState),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(excelDataControllerProvider);
    final platformFactory = ref.watch(platformFactoryProvider);
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Excel AI Analyzer'),
            Text(
              platformFactory.platformName,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeState.mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: asyncData.when(
          data: (state) {
            return Column(
              children: [
                Expanded(
                  child: DataTableView(tableState: state),
                ),
              ],
            );
          },
          loading: () => Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text(
                      'Parsing & Indexing Data...',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Processing file in background isolate for smooth UI',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
          error: (err, stack) => Center(
            child: Text('Error loading data: $err'),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'ai_sheet_fab',
            onPressed: () {
              if (asyncData.value != null) {
                _showAiBottomSheet(context, asyncData.value!);
              }
            },
            tooltip: 'AI Insights',
            child: const Icon(Icons.auto_awesome),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'import_fab',
            onPressed: () {
              ref.read(excelDataControllerProvider.notifier).pickAndLoadFile();
            },
            icon: const Icon(Icons.file_open_outlined),
            label: const Text('Import File'),
          ),
        ],
      ),
    );
  }
}
