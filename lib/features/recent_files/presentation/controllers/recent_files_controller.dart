import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/recent_files_local_datasource.dart';
import '../../domain/entities/recent_file.dart';

/// Riverpod AsyncNotifier managing the local database state of recent opened files.
class RecentFilesNotifier extends AsyncNotifier<List<RecentFile>> {
  late final RecentFilesLocalDataSource _dataSource;

  @override
  FutureOr<List<RecentFile>> build() async {
    _dataSource = RecentFilesLocalDataSource();
    return await _dataSource.getRecentFiles();
  }

  /// Adds or updates a file entry in the local database when a file is opened.
  Future<void> addOrUpdateFile({
    required String name,
    String? path,
    required List<int> bytes,
    required int sizeBytes,
  }) async {
    final file = RecentFile(
      id: path ?? '${name}_${DateTime.now().millisecondsSinceEpoch}',
      fileName: name,
      filePath: path,
      lastOpened: DateTime.now(),
      sizeBytes: sizeBytes,
      // Cache bytes for small files (< 5MB) or web environments without file paths
      cachedBytes: bytes.length < 5 * 1024 * 1024 ? bytes : null,
    );

    await _dataSource.saveRecentFile(file);
    state = AsyncValue.data(await _dataSource.getRecentFiles());
  }

  /// Removes a file record from the database.
  Future<void> removeFile(String id) async {
    await _dataSource.removeRecentFile(id);
    state = AsyncValue.data(await _dataSource.getRecentFiles());
  }

  /// Clears all recent file history.
  Future<void> clearAll() async {
    await _dataSource.clearAll();
    state = const AsyncValue.data([]);
  }
}

final recentFilesControllerProvider =
    AsyncNotifierProvider<RecentFilesNotifier, List<RecentFile>>(() {
  return RecentFilesNotifier();
});
