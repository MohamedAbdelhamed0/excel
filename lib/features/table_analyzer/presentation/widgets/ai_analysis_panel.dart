import 'package:flutter/material.dart';
import '../controllers/excel_data_controller.dart';

/// Interactive AI Analysis Panel displaying dataset insights, executive summary, and prompt queries.
class AiAnalysisPanel extends StatelessWidget {
  final TableDataState tableState;

  const AiAnalysisPanel({
    super.key,
    required this.tableState,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rowCount = tableState.totalRows;
    final colCount = tableState.headers.length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Analyzer Assistant',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Real-time automated data intelligence',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Metrics Summary Row
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Total Rows',
                  value: '$rowCount',
                  icon: Icons.table_rows,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Columns',
                  value: '$colCount',
                  icon: Icons.view_column,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Executive Summary Section
          Text(
            'Executive Summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInsightBullet(
                    context,
                    title: 'Dataset Capacity:',
                    body: 'Parsed $rowCount entries across $colCount fields successfully.',
                  ),
                  const Divider(height: 20),
                  _buildInsightBullet(
                    context,
                    title: 'Active Filters:',
                    body: tableState.searchQuery.isNotEmpty
                        ? 'Filtered by "${tableState.searchQuery}" (${tableState.totalRows} results).'
                        : 'No text search filter active.',
                  ),
                  const Divider(height: 20),
                  _buildInsightBullet(
                    context,
                    title: 'Sorting State:',
                    body: tableState.sortColumnIndex != null
                        ? 'Sorted by ${tableState.headers[tableState.sortColumnIndex!]} (${tableState.sortAscending ? "Ascending" : "Descending"}).'
                        : 'Original document row ordering.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Prompt Query Field
          Text(
            'Ask AI Assistant',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'e.g. Find highest growth items...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send_rounded),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Processing query with AI engine...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Quick Action Suggestion Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.show_chart, size: 16),
                label: const Text('Forecast Q3'),
                onPressed: () {},
              ),
              ActionChip(
                avatar: const Icon(Icons.cleaning_services, size: 16),
                label: const Text('Detect Anomalies'),
                onPressed: () {},
              ),
              ActionChip(
                avatar: const Icon(Icons.summarize, size: 16),
                label: const Text('Export Summary'),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: theme.hintColor),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightBullet(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline,
          color: theme.colorScheme.primary,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$title ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: body),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
