import 'dart:convert';

/// Domain Entity and Data Model representing a previously opened spreadsheet file.
class RecentFile {
  final String id;
  final String fileName;
  final String? filePath;
  final DateTime lastOpened;
  final int sizeBytes;
  final List<int>? cachedBytes;

  const RecentFile({
    required this.id,
    required this.fileName,
    this.filePath,
    required this.lastOpened,
    required this.sizeBytes,
    this.cachedBytes,
  });

  RecentFile copyWith({
    String? id,
    String? fileName,
    String? filePath,
    DateTime? lastOpened,
    int? sizeBytes,
    List<int>? cachedBytes,
  }) {
    return RecentFile(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      lastOpened: lastOpened ?? this.lastOpened,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      cachedBytes: cachedBytes ?? this.cachedBytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'lastOpened': lastOpened.toIso8601String(),
      'sizeBytes': sizeBytes,
      if (cachedBytes != null && cachedBytes!.isNotEmpty)
        'cachedBytes': base64Encode(cachedBytes!),
    };
  }

  factory RecentFile.fromJson(Map<String, dynamic> json) {
    return RecentFile(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String?,
      lastOpened: DateTime.parse(json['lastOpened'] as String),
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      cachedBytes: json['cachedBytes'] != null
          ? base64Decode(json['cachedBytes'] as String)
          : null,
    );
  }
}
