import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/DI/platform_providers.dart';
import '../../../../core/utils/excel_parser.dart';
import '../../../recent_files/presentation/controllers/recent_files_controller.dart';

/// State object representing table data, current sorting, search query, and pagination for a single spreadsheet.
class TableDataState {
  final List<List<dynamic>> rawData;
  final List<List<dynamic>> processedData; // Filtered and sorted rows
  final int? sortColumnIndex;
  final bool sortAscending;
  final String searchQuery;
  final int currentPage;
  final int pageSize;

  const TableDataState({
    required this.rawData,
    required this.processedData,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.searchQuery = '',
    this.currentPage = 0,
    this.pageSize = 50,
  });

  TableDataState copyWith({
    List<List<dynamic>>? rawData,
    List<List<dynamic>>? processedData,
    int? sortColumnIndex,
    bool? sortAscending,
    String? searchQuery,
    int? currentPage,
    int? pageSize,
  }) {
    return TableDataState(
      rawData: rawData ?? this.rawData,
      processedData: processedData ?? this.processedData,
      sortColumnIndex: sortColumnIndex ?? this.sortColumnIndex,
      sortAscending: sortAscending ?? this.sortAscending,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  List<dynamic> get headers => rawData.isNotEmpty ? rawData.first : [];
  List<List<dynamic>> get rows => processedData.isNotEmpty ? processedData.skip(1).toList() : [];
  int get totalRows => rows.length;
  int get totalPages => (totalRows / pageSize).ceil() == 0 ? 1 : (totalRows / pageSize).ceil();

  List<List<dynamic>> get currentPageRows {
    if (rows.isEmpty) return [];
    final start = currentPage * pageSize;
    if (start >= rows.length) return [];
    final end = (start + pageSize) < rows.length ? (start + pageSize) : rows.length;
    return rows.sublist(start, end);
  }
}

/// Data structure representing a single open spreadsheet tab.
class OpenFileTab {
  final String id;
  final String fileName;
  final String? filePath;
  final TableDataState tableState;

  const OpenFileTab({
    required this.id,
    required this.fileName,
    this.filePath,
    required this.tableState,
  });

  OpenFileTab copyWith({
    String? id,
    String? fileName,
    String? filePath,
    TableDataState? tableState,
  }) {
    return OpenFileTab(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      tableState: tableState ?? this.tableState,
    );
  }
}

/// Workspace state holding all open tabs and the index of the currently active tab.
class MultiTabWorkspaceState {
  final List<OpenFileTab> tabs;
  final int activeTabIndex;

  const MultiTabWorkspaceState({
    required this.tabs,
    required this.activeTabIndex,
  });

  OpenFileTab? get activeTab =>
      (tabs.isNotEmpty && activeTabIndex >= 0 && activeTabIndex < tabs.length)
          ? tabs[activeTabIndex]
          : null;

  TableDataState get activeTableState =>
      activeTab?.tableState ?? const TableDataState(rawData: [], processedData: []);

  MultiTabWorkspaceState copyWith({
    List<OpenFileTab>? tabs,
    int? activeTabIndex,
  }) {
    return MultiTabWorkspaceState(
      tabs: tabs ?? this.tabs,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
    );
  }
}

/// Riverpod AsyncNotifier managing the multi-tab workspace state.
class ExcelDataNotifier extends AsyncNotifier<MultiTabWorkspaceState> {
  @override
  FutureOr<MultiTabWorkspaceState> build() async {
    final sample = ExcelParser.generateSampleData();
    final defaultTab = OpenFileTab(
      id: 'sample_default',
      fileName: 'Sample Dataset.xlsx',
      tableState: TableDataState(
        rawData: sample,
        processedData: sample,
      ),
    );

    return MultiTabWorkspaceState(
      tabs: [defaultTab],
      activeTabIndex: 0,
    );
  }

  /// Switch active tab index.
  void setActiveTab(int index) {
    final currentState = state.value;
    if (currentState == null || index < 0 || index >= currentState.tabs.length) return;
    state = AsyncValue.data(currentState.copyWith(activeTabIndex: index));
  }

  /// Close tab at given index.
  void closeTab(int index) {
    final currentState = state.value;
    if (currentState == null || index < 0 || index >= currentState.tabs.length) return;

    final newTabs = List<OpenFileTab>.from(currentState.tabs)..removeAt(index);

    if (newTabs.isEmpty) {
      // If all tabs closed, recreate default sample tab
      final sample = ExcelParser.generateSampleData();
      final defaultTab = OpenFileTab(
        id: 'sample_default',
        fileName: 'Sample Dataset.xlsx',
        tableState: TableDataState(
          rawData: sample,
          processedData: sample,
        ),
      );
      state = AsyncValue.data(MultiTabWorkspaceState(tabs: [defaultTab], activeTabIndex: 0));
      return;
    }

    int newIndex = currentState.activeTabIndex;
    if (index <= currentState.activeTabIndex) {
      newIndex = (currentState.activeTabIndex - 1).clamp(0, newTabs.length - 1);
    }

    state = AsyncValue.data(MultiTabWorkspaceState(tabs: newTabs, activeTabIndex: newIndex));
  }

  /// Prompts file picker, offloads parsing to a background isolate, adds/switches to a tab, and saves to local DB.
  Future<void> pickAndLoadFile() async {
    final previousState = state.value;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final factory = ref.read(platformFactoryProvider);
      final picker = factory.getFilePicker();

      final fileInfo = await picker.pickFileDetails(allowedExtensions: ['csv', 'xlsx', 'xls']);

      if (fileInfo != null && fileInfo.bytes.isNotEmpty) {
        // Check if file is already open in an existing tab
        if (previousState != null) {
          final existingIdx = previousState.tabs.indexWhere(
            (tab) =>
                (fileInfo.path != null && tab.filePath == fileInfo.path) ||
                tab.fileName == fileInfo.name,
          );
          if (existingIdx != -1) {
            return previousState.copyWith(activeTabIndex: existingIdx);
          }
        }

        // Parse bytes in background isolate using compute
        final parsedData = await compute(ExcelParser.parseBytes, fileInfo.bytes);
        if (parsedData.isNotEmpty) {
          await ref.read(recentFilesControllerProvider.notifier).addOrUpdateFile(
                name: fileInfo.name,
                path: fileInfo.path,
                bytes: fileInfo.bytes,
                sizeBytes: fileInfo.sizeBytes,
              );

          final newTab = OpenFileTab(
            id: fileInfo.path ?? '${fileInfo.name}_${DateTime.now().millisecondsSinceEpoch}',
            fileName: fileInfo.name,
            filePath: fileInfo.path,
            tableState: TableDataState(
              rawData: parsedData,
              processedData: parsedData,
            ),
          );

          final currentTabs = previousState != null ? List<OpenFileTab>.from(previousState.tabs) : <OpenFileTab>[];
          currentTabs.add(newTab);

          return MultiTabWorkspaceState(
            tabs: currentTabs,
            activeTabIndex: currentTabs.length - 1,
          );
        }
      }
      return previousState ?? _createFallbackState();
    });
  }

  /// Opens a file from raw bytes (used when selecting from recent files history).
  Future<void> loadBytes({
    required String name,
    required List<int> bytes,
    String? path,
  }) async {
    final previousState = state.value;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Check if file is already open in an existing tab
      if (previousState != null) {
        final existingIdx = previousState.tabs.indexWhere(
          (tab) => (path != null && tab.filePath == path) || tab.fileName == name,
        );
        if (existingIdx != -1) {
          return previousState.copyWith(activeTabIndex: existingIdx);
        }
      }

      final parsedData = await compute(ExcelParser.parseBytes, bytes);
      if (parsedData.isNotEmpty) {
        await ref.read(recentFilesControllerProvider.notifier).addOrUpdateFile(
              name: name,
              path: path,
              bytes: bytes,
              sizeBytes: bytes.length,
            );

        final newTab = OpenFileTab(
          id: path ?? '${name}_${DateTime.now().millisecondsSinceEpoch}',
          fileName: name,
          filePath: path,
          tableState: TableDataState(
            rawData: parsedData,
            processedData: parsedData,
          ),
        );

        final currentTabs = previousState != null ? List<OpenFileTab>.from(previousState.tabs) : <OpenFileTab>[];
        currentTabs.add(newTab);

        return MultiTabWorkspaceState(
          tabs: currentTabs,
          activeTabIndex: currentTabs.length - 1,
        );
      }
      return previousState ?? _createFallbackState();
    });
  }

  /// Sort dataset by specific column index for the active tab.
  void sortByColumn(int columnIndex) {
    final currentState = state.value;
    final activeTab = currentState?.activeTab;
    if (currentState == null || activeTab == null || activeTab.tableState.rawData.length <= 1) return;

    final tableState = activeTab.tableState;
    final isSameColumn = tableState.sortColumnIndex == columnIndex;
    final newAscending = isSameColumn ? !tableState.sortAscending : true;

    final headers = tableState.rawData.first;
    final dataRows = List<List<dynamic>>.from(tableState.rows);

    dataRows.sort((a, b) {
      final valA = columnIndex < a.length ? a[columnIndex] : '';
      final valB = columnIndex < b.length ? b[columnIndex] : '';

      int cmp;
      if (valA is num && valB is num) {
        cmp = valA.compareTo(valB);
      } else {
        final numA = num.tryParse(valA.toString());
        final numB = num.tryParse(valB.toString());
        if (numA != null && numB != null) {
          cmp = numA.compareTo(numB);
        } else {
          cmp = valA.toString().toLowerCase().compareTo(valB.toString().toLowerCase());
        }
      }
      return newAscending ? cmp : -cmp;
    });

    final newProcessed = [headers, ...dataRows];
    final updatedTableState = tableState.copyWith(
      processedData: newProcessed,
      sortColumnIndex: columnIndex,
      sortAscending: newAscending,
      currentPage: 0,
    );

    _updateActiveTabState(currentState, updatedTableState);
  }

  /// Filter rows matching search query across all cells for the active tab.
  void setSearchQuery(String query) {
    final currentState = state.value;
    final activeTab = currentState?.activeTab;
    if (currentState == null || activeTab == null || activeTab.tableState.rawData.isEmpty) return;

    final tableState = activeTab.tableState;
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      _updateActiveTabState(
        currentState,
        tableState.copyWith(
          processedData: tableState.rawData,
          searchQuery: '',
          currentPage: 0,
        ),
      );
      return;
    }

    final headers = tableState.rawData.first;
    final allRows = tableState.rawData.skip(1).toList();

    final filteredRows = allRows.where((row) {
      return row.any((cell) => cell.toString().toLowerCase().contains(trimmed));
    }).toList();

    _updateActiveTabState(
      currentState,
      tableState.copyWith(
        processedData: [headers, ...filteredRows],
        searchQuery: query,
        currentPage: 0,
      ),
    );
  }

  /// Navigate to target page for the active tab.
  void setPage(int page) {
    final currentState = state.value;
    final activeTab = currentState?.activeTab;
    if (currentState == null || activeTab == null) return;

    final tableState = activeTab.tableState;
    final validPage = page.clamp(0, tableState.totalPages - 1);
    _updateActiveTabState(currentState, tableState.copyWith(currentPage: validPage));
  }

  /// Change pagination page size for the active tab.
  void setPageSize(int size) {
    final currentState = state.value;
    final activeTab = currentState?.activeTab;
    if (currentState == null || activeTab == null) return;

    final tableState = activeTab.tableState;
    _updateActiveTabState(currentState, tableState.copyWith(pageSize: size, currentPage: 0));
  }

  /// Reload sample demo data.
  void loadSampleData() {
    final sample = ExcelParser.generateSampleData();
    final defaultTab = OpenFileTab(
      id: 'sample_${DateTime.now().millisecondsSinceEpoch}',
      fileName: 'Sample Dataset.xlsx',
      tableState: TableDataState(
        rawData: sample,
        processedData: sample,
      ),
    );

    state = AsyncValue.data(MultiTabWorkspaceState(
      tabs: [defaultTab],
      activeTabIndex: 0,
    ));
  }

  void _updateActiveTabState(MultiTabWorkspaceState currentState, TableDataState newTableState) {
    final newTabs = List<OpenFileTab>.from(currentState.tabs);
    final activeIdx = currentState.activeTabIndex;
    if (activeIdx >= 0 && activeIdx < newTabs.length) {
      newTabs[activeIdx] = newTabs[activeIdx].copyWith(tableState: newTableState);
      state = AsyncValue.data(currentState.copyWith(tabs: newTabs));
    }
  }

  MultiTabWorkspaceState _createFallbackState() {
    final sample = ExcelParser.generateSampleData();
    final defaultTab = OpenFileTab(
      id: 'sample_default',
      fileName: 'Sample Dataset.xlsx',
      tableState: TableDataState(rawData: sample, processedData: sample),
    );
    return MultiTabWorkspaceState(tabs: [defaultTab], activeTabIndex: 0);
  }
}

final excelDataControllerProvider =
    AsyncNotifierProvider<ExcelDataNotifier, MultiTabWorkspaceState>(() {
  return ExcelDataNotifier();
});
