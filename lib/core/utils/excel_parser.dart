import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';

/// Helper utility for converting raw file bytes (CSV or Excel) into standard table row matrices (`List<List<dynamic>>`).
class ExcelParser {
  ExcelParser._();

  /// Parse raw byte data into rows.
  /// Dynamically detects whether the file is an Excel binary (.xlsx / .xls) or a CSV text file.
  static List<List<dynamic>> parseBytes(List<int> bytes) {
    if (bytes.isEmpty) return [];

    // Check for ZIP magic bytes (0x50, 0x4B - PK) used by .xlsx files
    // or OLE magic bytes (0xD0, 0xCF) used by .xls legacy files.
    final isExcelBinary = (bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B) ||
        (bytes.length >= 2 && bytes[0] == 0xD0 && bytes[1] == 0xCF);

    if (isExcelBinary) {
      final rows = _parseExcel(bytes);
      if (rows.isNotEmpty) return rows;
    }

    // Try CSV parsing
    final csvRows = _parseCsv(bytes);
    if (csvRows.isNotEmpty) return csvRows;

    // Fallback attempt Excel parsing if CSV parsing yielded empty
    return _parseExcel(bytes);
  }

  static List<List<dynamic>> _parseExcel(List<int> bytes) {
    try {
      final excel = Excel.decodeBytes(bytes);
      for (final table in excel.tables.keys) {
        final sheet = excel.tables[table];
        if (sheet != null && sheet.maxRows > 0) {
          final List<List<dynamic>> rows = [];
          for (final row in sheet.rows) {
            final rowData = row.map((cell) {
              if (cell == null || cell.value == null) return '';
              final val = cell.value;
              if (val is TextCellValue) return val.value.toString();
              if (val is IntCellValue) return val.value;
              if (val is DoubleCellValue) return val.value;
              return val.toString();
            }).toList();

            // Ignore completely empty trailing rows
            if (rowData.any((cell) => cell.toString().trim().isNotEmpty)) {
              rows.add(rowData);
            }
          }
          if (rows.isNotEmpty) return rows;
        }
      }
    } catch (e) {
      debugPrint('[ExcelParser] Error decoding Excel bytes: $e');
    }
    return [];
  }

  static List<List<dynamic>> _parseCsv(List<int> bytes) {
    try {
      final content = utf8.decode(bytes, allowMalformed: true);
      const csvConverter = CsvToListConverter(
        shouldParseNumbers: true,
        allowInvalid: true,
        eol: '\n',
      );
      final rows = csvConverter.convert(content);
      return rows.where((row) => row.any((cell) => cell.toString().trim().isNotEmpty)).toList();
    } catch (e) {
      debugPrint('[ExcelParser] Error decoding CSV text: $e');
    }
    return [];
  }

  /// Create default sample data for initial application launch.
  static List<List<dynamic>> generateSampleData() {
    return [
      ['ID', 'Product Name', 'Category', 'Quarter 1 (\$)', 'Quarter 2 (\$)', 'Status', 'Growth (%)'],
      [101, 'Quantum Laptop Pro', 'Hardware', 14500, 18200, 'Delivered', 25.5],
      [102, 'Cloud AI Suite', 'Software', 32000, 41500, 'Active', 29.6],
      [103, 'Smart Workspace Hub', 'Hardware', 8900, 9400, 'In Review', 5.6],
      [104, 'Enterprise Security Pass', 'Services', 21000, 24800, 'Delivered', 18.0],
      [105, 'Data Analytics Engine', 'Software', 54000, 68900, 'Active', 27.5],
      [106, 'Ergonomic Standing Desk', 'Furniture', 4300, 5100, 'Delivered', 18.6],
      [107, 'High-Thread Fiber Optic', 'Networking', 19200, 21500, 'Active', 11.9],
      [108, 'Virtual GPU Pods', 'Infrastructure', 67000, 89000, 'Active', 32.8],
    ];
  }
}
