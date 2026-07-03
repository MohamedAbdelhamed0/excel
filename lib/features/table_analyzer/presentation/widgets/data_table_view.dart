import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/excel_data_controller.dart';

/// High-performance virtualized spreadsheet data grid with unified header/body scrolling,
/// cell selection, right-click context menu, and clipboard copy capabilities.
class DataTableView extends ConsumerStatefulWidget {
  final TableDataState tableState;

  const DataTableView({
    super.key,
    required this.tableState,
  });

  @override
  ConsumerState<DataTableView> createState() => _DataTableViewState();
}

class _DataTableViewState extends ConsumerState<DataTableView> {
  final Set<String> _selectedCellKeys = {};

  void _toggleCellSelection(int rowIdx, int colIdx, {required bool isMultiSelect}) {
    final key = '${rowIdx}_$colIdx';
    setState(() {
      if (isMultiSelect) {
        if (_selectedCellKeys.contains(key)) {
          _selectedCellKeys.remove(key);
        } else {
          _selectedCellKeys.add(key);
        }
      } else {
        _selectedCellKeys.clear();
        _selectedCellKeys.add(key);
      }
    });
  }

  void _selectAllInRow(int rowIdx, int colCount) {
    setState(() {
      for (int c = 0; c < colCount; c++) {
        _selectedCellKeys.add('${rowIdx}_$c');
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedCellKeys.clear();
    });
  }

  void _copyToClipboard(
    BuildContext context,
    List<List<dynamic>> pageRows, {
    required bool spaceSeparated,
    int? targetRowIdx,
    int? targetColIdx,
  }) {
    if (_selectedCellKeys.isEmpty && targetRowIdx != null && targetColIdx != null) {
      _selectedCellKeys.add('${targetRowIdx}_$targetColIdx');
    }

    if (_selectedCellKeys.isEmpty) return;

    // Parse selected cell keys into sorted coordinates (row, col)
    final sortedCoords = _selectedCellKeys.map((key) {
      final parts = key.split('_');
      return MapEntry(int.parse(parts[0]), int.parse(parts[1]));
    }).toList()
      ..sort((a, b) {
        final rowCmp = a.key.compareTo(b.key);
        if (rowCmp != 0) return rowCmp;
        return a.value.compareTo(b.value);
      });

    final headers = widget.tableState.headers;
    final extractedValues = <String>[];
    for (final coord in sortedCoords) {
      final r = coord.key;
      final c = coord.value;
      if (r < pageRows.length) {
        final row = pageRows[r];
        final headerName = c < headers.length ? headers[c]?.toString() ?? '' : '';
        final val = c < row.length ? row[c]?.toString() ?? '' : '';

        if (headerName.isNotEmpty) {
          extractedValues.add('$headerName: $val');
        } else {
          extractedValues.add(val);
        }
      }
    }

    final delimiter = spaceSeparated ? '  ' : '\n';
    final textToCopy = extractedValues.join(delimiter);

    Clipboard.setData(ClipboardData(text: textToCopy));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied ${extractedValues.length} cell(s): "$textToCopy"',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  void _showContextMenu(
    BuildContext context,
    TapUpDetails details,
    int rowIdx,
    int colIdx,
    List<List<dynamic>> pageRows,
    int totalCols,
  ) {
    final key = '${rowIdx}_$colIdx';
    if (!_selectedCellKeys.contains(key)) {
      _toggleCellSelection(rowIdx, colIdx, isMultiSelect: false);
    }

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      details.globalPosition & Size.zero,
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 300),
      items: [
        PopupMenuItem<String>(
          value: 'copy_cell',
          child: Row(
            children: const [
              Icon(Icons.copy, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Copy Selected Cell',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'copy_space_separated',
          child: Row(
            children: const [
              Icon(Icons.space_bar, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Copy Selected with Headers',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'copy_row',
          child: Row(
            children: const [
              Icon(Icons.table_rows_outlined, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Select & Copy Entire Row',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'clear_selection',
          child: Row(
            children: const [
              Icon(Icons.clear_all, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Clear Selection',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((choice) {
      if (!mounted || !context.mounted || choice == null) return;
      switch (choice) {
        case 'copy_cell':
          _copyToClipboard(context, pageRows, spaceSeparated: true, targetRowIdx: rowIdx, targetColIdx: colIdx);
          break;
        case 'copy_space_separated':
          _copyToClipboard(context, pageRows, spaceSeparated: true);
          break;
        case 'copy_row':
          _selectAllInRow(rowIdx, totalCols);
          _copyToClipboard(context, pageRows, spaceSeparated: true);
          break;
        case 'clear_selection':
          _clearSelection();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tableState = widget.tableState;

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
        // Top Filter, Search Bar & Selection Actions
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
              if (_selectedCellKeys.isNotEmpty) ...[
                OutlinedButton.icon(
                  onPressed: () => _copyToClipboard(context, pageRows, spaceSeparated: true),
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text('Copy (${_selectedCellKeys.length})'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _clearSelection,
                  child: const Text('Clear'),
                ),
                const SizedBox(width: 8),
              ],
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

        // Virtualized Table Container with Unified Horizontal Scroll
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: headers.length * 160.0,
                  child: Column(
                    children: [
                      // Synchronized Header Row with Column Sorting Triggers
                      Container(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
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
                      const Divider(height: 1),

                      // Virtualized Scrollable Rows Body (ListView.builder)
                      Expanded(
                        child: pageRows.isEmpty
                            ? Center(
                                child: Text(
                                  'No matching rows found',
                                  style: TextStyle(color: theme.hintColor),
                                ),
                              )
                            : ListView.separated(
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
                                        final cellKey = '${rowIdx}_$colIdx';
                                        final isSelected = _selectedCellKeys.contains(cellKey);
                                        final isStatus = cellVal == 'Active' || cellVal == 'Delivered' || cellVal == 'In Review';

                                        return GestureDetector(
                                          onTap: () {
                                            final isMulti = HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) ||
                                                HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlRight) ||
                                                HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.metaLeft);
                                            _toggleCellSelection(rowIdx, colIdx, isMultiSelect: isMulti);
                                          },
                                          onSecondaryTapUp: (details) {
                                            _showContextMenu(context, details, rowIdx, colIdx, pageRows, headers.length);
                                          },
                                          onLongPressStart: (details) {
                                            final tapDetails = TapUpDetails(
                                              kind: PointerDeviceKind.touch,
                                              globalPosition: details.globalPosition,
                                              localPosition: details.localPosition,
                                            );
                                            _showContextMenu(context, tapDetails, rowIdx, colIdx, pageRows, headers.length);
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 150),
                                            width: 160,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            alignment: Alignment.centerLeft,
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                                                  : Colors.transparent,
                                              border: Border.all(
                                                color: isSelected
                                                    ? theme.colorScheme.primary
                                                    : Colors.transparent,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: isStatus
                                                ? _buildStatusBadge(context, cellVal)
                                                : Text(
                                                    cellVal,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                      color: isSelected
                                                          ? theme.colorScheme.primary
                                                          : theme.colorScheme.onSurface.withValues(alpha: 0.9),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                          ),
                                        );
                                      }),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
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
