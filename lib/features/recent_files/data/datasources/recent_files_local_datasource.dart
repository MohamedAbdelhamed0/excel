import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/recent_file.dart';

/// Local database data source managing stored spreadsheet history records in SharedPreferences.
class RecentFilesLocalDataSource {
  static const String _storageKey = 'excel_ai_recent_files_v1';

  /// Fetch all stored recent files ordered by last opened timestamp descending.
  Future<List<RecentFile>> getRecentFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final list = jsonList
          .map((item) => RecentFile.fromJson(item as Map<String, dynamic>))
          .toList();

      list.sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
      return list;
    } catch (e) {
      debugPrint('[RecentFilesLocalDataSource] Error reading local DB: $e');
      return [];
    }
  }

  /// Insert or update a file record in the local database.
  Future<void> saveRecentFile(RecentFile file) async {
    try {
      final currentList = await getRecentFiles();

      // Remove existing record with same path or name
      currentList.removeWhere(
        (existing) =>
            (file.filePath != null && existing.filePath == file.filePath) ||
            existing.fileName == file.fileName,
      );

      // Add new / updated file at the top
      currentList.insert(0, file);

      // Limit history to top 30 most recent files
      final trimmedList = currentList.take(30).toList();

      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(trimmedList.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('[RecentFilesLocalDataSource] Error saving to local DB: $e');
    }
  }

  /// Delete a single file record from history.
  Future<void> removeRecentFile(String id) async {
    try {
      final currentList = await getRecentFiles();
      currentList.removeWhere((item) => item.id == id);

      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(currentList.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('[RecentFilesLocalDataSource] Error deleting from local DB: $e');
    }
  }

  /// Clear all recent file history.
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('[RecentFilesLocalDataSource] Error clearing local DB: $e');
    }
  }
}
