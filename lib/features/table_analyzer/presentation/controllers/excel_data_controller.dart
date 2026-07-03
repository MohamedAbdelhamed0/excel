import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/DI/platform_providers.dart';
import '../../../../core/utils/excel_parser.dart';

/// State object representing table data, current sorting, search query, and pagination.
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

/// Riverpod AsyncNotifier managing background file parsing, sorting, filtering, and pagination.
class ExcelDataNotifier extends AsyncNotifier<TableDataState> {
  @override
  FutureOr<TableDataState> build() async {
    final sample = ExcelParser.generateSampleData();
    return TableDataState(
      rawData: sample,
      processedData: sample,
    );
  }

  /// Offloads parsing to a background isolate using [compute] to keep UI 60fps smooth.
  Future<void> pickAndLoadFile() async {
    final previousState = state.value;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final factory = ref.read(platformFactoryProvider);
      final picker = factory.getFilePicker();

      final bytes = await picker.pickFile(allowedExtensions: ['csv', 'xlsx', 'xls']);

      if (bytes != null && bytes.isNotEmpty) {
        // Run parsing in a background isolate using compute
        final parsedData = await compute(ExcelParser.parseBytes, bytes);
        if (parsedData.isNotEmpty) {
          return TableDataState(
            rawData: parsedData,
            processedData: parsedData,
          );
        }
      }
      return previousState ??
          TableDataState(
            rawData: ExcelParser.generateSampleData(),
            processedData: ExcelParser.generateSampleData(),
          );
    });
  }

  /// Sort dataset by specific column index.
  void sortByColumn(int columnIndex) {
    final currentState = state.value;
    if (currentState == null || currentState.rawData.length <= 1) return;

    final isSameColumn = currentState.sortColumnIndex == columnIndex;
    final newAscending = isSameColumn ? !currentState.sortAscending : true;

    final headers = currentState.rawData.first;
    final dataRows = List<List<dynamic>>.from(currentState.rows);

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
    state = AsyncValue.data(currentState.copyWith(
      processedData: newProcessed,
      sortColumnIndex: columnIndex,
      sortAscending: newAscending,
      currentPage: 0,
    ));
  }

  /// Filter rows matching search query across all cells.
  void setSearchQuery(String query) {
    final currentState = state.value;
    if (currentState == null || currentState.rawData.isEmpty) return;

    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      state = AsyncValue.data(currentState.copyWith(
        processedData: currentState.rawData,
        searchQuery: '',
        currentPage: 0,
      ));
      return;
    }

    final headers = currentState.rawData.first;
    final allRows = currentState.rawData.skip(1).toList();

    final filteredRows = allRows.where((row) {
      return row.any((cell) => cell.toString().toLowerCase().contains(trimmed));
    }).toList();

    state = AsyncValue.data(currentState.copyWith(
      processedData: [headers, ...filteredRows],
      searchQuery: query,
      currentPage: 0,
    ));
  }

  /// Navigate to target page.
  void setPage(int page) {
    final currentState = state.value;
    if (currentState == null) return;
    final validPage = page.clamp(0, currentState.totalPages - 1);
    state = AsyncValue.data(currentState.copyWith(currentPage: validPage));
  }

  /// Change pagination page size.
  void setPageSize(int size) {
    final currentState = state.value;
    if (currentState == null) return;
    state = AsyncValue.data(currentState.copyWith(
      pageSize: size,
      currentPage: 0,
    ));
  }

  /// Reload sample demo data.
  void loadSampleData() {
    final sample = ExcelParser.generateSampleData();
    state = AsyncValue.data(TableDataState(
      rawData: sample,
      processedData: sample,
    ));
  }
}

final excelDataControllerProvider =
    AsyncNotifierProvider<ExcelDataNotifier, TableDataState>(() {
  return ExcelDataNotifier();
});
