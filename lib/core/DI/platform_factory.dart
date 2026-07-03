import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Data structure containing picked file metadata and raw content bytes.
class PickedFileInfo {
  final String name;
  final String? path;
  final List<int> bytes;
  final int sizeBytes;

  PickedFileInfo({
    required this.name,
    this.path,
    required this.bytes,
    required this.sizeBytes,
  });
}

/// Abstract service interface for picking Excel/CSV files across platforms.
abstract class IFilePickerService {
  /// Prompt user to select a file and return [PickedFileInfo].
  Future<PickedFileInfo?> pickFileDetails({List<String>? allowedExtensions});

  /// Backward-compatible method returning bytes.
  Future<List<int>?> pickFile({List<String>? allowedExtensions});

  /// Name or description of the picker strategy.
  String get pickerName;
}

/// Abstract service interface for platform initialization (window sizing, permissions, etc.).
abstract class IPlatformInitializer {
  /// Run platform-specific initializations before or during app start.
  Future<void> initialize();
}

/// Abstract Factory interface for platform-specific dependencies.
abstract class PlatformServiceFactory {
  /// Returns the platform-appropriate file picker implementation.
  IFilePickerService getFilePicker();

  /// Returns the platform initializer.
  IPlatformInitializer getInitializer();

  /// Returns the current platform name identifier.
  String get platformName;
}

// Helper method to execute real file picking across platforms
Future<PickedFileInfo?> _pickFileInfoFromOS({List<String>? allowedExtensions}) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions ?? ['csv', 'xlsx', 'xls'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      List<int>? bytes = file.bytes;

      if ((bytes == null || bytes.isEmpty) && !kIsWeb && file.path != null && file.path!.isNotEmpty) {
        final localFile = File(file.path!);
        if (await localFile.exists()) {
          bytes = await localFile.readAsBytes();
        }
      }

      if (bytes != null && bytes.isNotEmpty) {
        return PickedFileInfo(
          name: file.name,
          path: file.path,
          bytes: bytes,
          sizeBytes: file.size,
        );
      }
    }
  } catch (e) {
    debugPrint('[FilePicker] Error selecting file from OS: $e');
  }
  return null;
}

// -----------------------------------------------------------------------------
// Desktop Implementation
// -----------------------------------------------------------------------------

class DesktopFilePickerService implements IFilePickerService {
  @override
  String get pickerName => 'Desktop Native File Dialog (FilePicker)';

  @override
  Future<PickedFileInfo?> pickFileDetails({List<String>? allowedExtensions}) async {
    debugPrint('[DesktopFilePicker] Opening native desktop file dialog...');
    return await _pickFileInfoFromOS(allowedExtensions: allowedExtensions);
  }

  @override
  Future<List<int>?> pickFile({List<String>? allowedExtensions}) async {
    final info = await pickFileDetails(allowedExtensions: allowedExtensions);
    return info?.bytes;
  }
}

class DesktopInitializer implements IPlatformInitializer {
  @override
  Future<void> initialize() async {
    debugPrint('[DesktopInitializer] Initializing desktop environment');
  }
}

class DesktopServiceFactory implements PlatformServiceFactory {
  final DesktopFilePickerService _picker = DesktopFilePickerService();
  final DesktopInitializer _initializer = DesktopInitializer();

  @override
  IFilePickerService getFilePicker() => _picker;

  @override
  IPlatformInitializer getInitializer() => _initializer;

  @override
  String get platformName => 'Desktop (${defaultTargetPlatform.name})';
}

// -----------------------------------------------------------------------------
// Mobile Implementation
// -----------------------------------------------------------------------------

class MobileFilePickerService implements IFilePickerService {
  @override
  String get pickerName => 'Mobile Document Picker (FilePicker)';

  @override
  Future<PickedFileInfo?> pickFileDetails({List<String>? allowedExtensions}) async {
    debugPrint('[MobileFilePicker] Opening mobile document picker...');
    return await _pickFileInfoFromOS(allowedExtensions: allowedExtensions);
  }

  @override
  Future<List<int>?> pickFile({List<String>? allowedExtensions}) async {
    final info = await pickFileDetails(allowedExtensions: allowedExtensions);
    return info?.bytes;
  }
}

class MobileInitializer implements IPlatformInitializer {
  @override
  Future<void> initialize() async {
    debugPrint('[MobileInitializer] Initializing mobile environment');
  }
}

class MobileServiceFactory implements PlatformServiceFactory {
  final MobileFilePickerService _picker = MobileFilePickerService();
  final MobileInitializer _initializer = MobileInitializer();

  @override
  IFilePickerService getFilePicker() => _picker;

  @override
  IPlatformInitializer getInitializer() => _initializer;

  @override
  String get platformName => 'Mobile (${defaultTargetPlatform.name})';
}

// -----------------------------------------------------------------------------
// Web / Fallback Implementation
// -----------------------------------------------------------------------------

class WebFallbackFilePickerService implements IFilePickerService {
  @override
  String get pickerName => 'Web / Browser File Input (FilePicker)';

  @override
  Future<PickedFileInfo?> pickFileDetails({List<String>? allowedExtensions}) async {
    debugPrint('[WebFallbackFilePicker] Opening browser file input...');
    return await _pickFileInfoFromOS(allowedExtensions: allowedExtensions);
  }

  @override
  Future<List<int>?> pickFile({List<String>? allowedExtensions}) async {
    final info = await pickFileDetails(allowedExtensions: allowedExtensions);
    return info?.bytes;
  }
}

class WebFallbackInitializer implements IPlatformInitializer {
  @override
  Future<void> initialize() async {
    debugPrint('[WebFallbackInitializer] Initializing web environment');
  }
}

class WebFallbackServiceFactory implements PlatformServiceFactory {
  final WebFallbackFilePickerService _picker = WebFallbackFilePickerService();
  final WebFallbackInitializer _initializer = WebFallbackInitializer();

  @override
  IFilePickerService getFilePicker() => _picker;

  @override
  IPlatformInitializer getInitializer() => _initializer;

  @override
  String get platformName => 'Web / Fallback';
}
