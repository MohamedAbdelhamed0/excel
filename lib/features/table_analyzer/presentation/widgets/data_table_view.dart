import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/excel_data_controller.dart';

/// High-performance virtualized spreadsheet data grid with column sorting, text filtering, and pagination.
class DataTableView extends ConsumerWidget {
  final TableDataState tableState;

  const DataTableView({
    super.key,
    required this.tableState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (tableState.rawData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_chart_outlined, size: 64, color: theme.hintColor),
            const SizedBox(height: 16),
            const Text(
              'No Spreadsheet Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Click Open File to load a CSV or Excel file',
              style: TextStyle(color: theme.hintColor),
            ),
          ],
        ),
      );
    }

    final headers = tableState.headers;
    final pageRows = tableState.currentPageRows;

    return Column(
      children: [
        // Top Filter & Search Bar
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) {
                    ref.read(excelDataControllerProvider.notifier).setSearchQuery(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Filter data across columns...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    isDense: true,
                    suffixIcon: tableState.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              ref.read(excelDataControllerProvider.notifier).setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Rows: ${tableState.totalRows}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Virtualized Table Container
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  // Sticky Header Row with Column Sorting Triggers
                  Container(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: Row(
                        children: List.generate(headers.length, (colIdx) {
                          final header = headers[colIdx].toString();
                          final isSorted = tableState.sortColumnIndex == colIdx;
                          final sortIcon = isSorted
                              ? (tableState.sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                              : Icons.unfold_more;

                          return InkWell(
                            onTap: () {
                              ref.read(excelDataControllerProvider.notifier).sortByColumn(colIdx);
                            },
                            child: Container(
                              width: 160,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: theme.dividerColor.withValues(alpha: 0.15),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      header,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isSorted
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    sortIcon,
                                    size: 16,
                                    color: isSorted
                                        ? theme.colorScheme.primary
                                        : theme.hintColor.withValues(alpha: 0.6),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const Divider(height: 1),

                  // Virtualized Scrollable Rows Body (ListView.builder for maximum scrolling performance)
                  Expanded(
                    child: pageRows.isEmpty
                        ? Center(
                            child: Text(
                              'No matching rows found',
                              style: TextStyle(color: theme.hintColor),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: headers.length * 160.0,
                              child: ListView.separated(
                                itemCount: pageRows.length,
                                separatorBuilder: (_, _) => Divider(
                                  height: 1,
                                  color: theme.dividerColor.withValues(alpha: 0.1),
                                ),
                                itemBuilder: (context, rowIdx) {
                                  final row = pageRows[rowIdx];
                                  final isEven = rowIdx % 2 == 0;

                                  return Container(
                                    color: isEven
                                        ? Colors.transparent
                                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
                                    child: Row(
                                      children: List.generate(headers.length, (colIdx) {
                                        final cellVal = colIdx < row.length ? row[colIdx]?.toString() ?? '' : '';
                                        final isStatus = cellVal == 'Active' || cellVal == 'Delivered' || cellVal == 'In Review';

                                        return Container(
                                          width: 160,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          alignment: Alignment.centerLeft,
                                          child: isStatus
                                              ? _buildStatusBadge(context, cellVal)
                                              : Text(
                                                  cellVal,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                        );
                                      }),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom Pagination Controls
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Page Size Selector
                Text(
                  'Page Size:',
                  style: TextStyle(fontSize: 12, color: theme.hintColor),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: tableState.pageSize,
                  isDense: true,
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface),
                  items: const [25, 50, 100, 250, 500].map((size) {
                    return DropdownMenuItem<int>(
                      value: size,
                      child: Text('$size'),
                    );
                  }).toList(),
                  onChanged: (newSize) {
                    if (newSize != null) {
                      ref.read(excelDataControllerProvider.notifier).setPageSize(newSize);
                    }
                  },
                ),
                const SizedBox(width: 16),

                // Page Navigation Controls
                IconButton(
                  icon: const Icon(Icons.first_page, size: 20),
                  onPressed: tableState.currentPage > 0
                      ? () => ref.read(excelDataControllerProvider.notifier).setPage(0)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: tableState.currentPage > 0
                      ? () => ref.read(excelDataControllerProvider.notifier).setPage(tableState.currentPage - 1)
                      : null,
                ),
                Text(
                  'Page ${tableState.currentPage + 1} of ${tableState.totalPages}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: tableState.currentPage < tableState.totalPages - 1
                      ? () => ref.read(excelDataControllerProvider.notifier).setPage(tableState.currentPage + 1)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.last_page, size: 20),
                  onPressed: tableState.currentPage < tableState.totalPages - 1
                      ? () => ref.read(excelDataControllerProvider.notifier).setPage(tableState.totalPages - 1)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color badgeColor;
    switch (status) {
      case 'Active':
      case 'Delivered':
        badgeColor = Colors.green;
        break;
      case 'In Review':
      case 'Pending':
        badgeColor = Colors.orange;
        break;
      default:
        badgeColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
