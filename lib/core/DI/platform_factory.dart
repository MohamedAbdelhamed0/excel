import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Abstract service interface for picking Excel/CSV files across platforms.
abstract class IFilePickerService {
  /// Prompt the user to select a file and return its raw byte contents.
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
Future<List<int>?> _pickFileFromOS({List<String>? allowedExtensions}) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions ?? ['csv', 'xlsx', 'xls'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;

      // In web or withData=true environments
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        return file.bytes!;
      }

      // In native desktop/mobile environments where file path is available
      if (!kIsWeb && file.path != null && file.path!.isNotEmpty) {
        final localFile = File(file.path!);
        if (await localFile.exists()) {
          return await localFile.readAsBytes();
        }
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
  Future<List<int>?> pickFile({List<String>? allowedExtensions}) async {
    debugPrint('[DesktopFilePicker] Opening native desktop file dialog...');
    return await _pickFileFromOS(allowedExtensions: allowedExtensions);
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
  Future<List<int>?> pickFile({List<String>? allowedExtensions}) async {
    debugPrint('[MobileFilePicker] Opening mobile document picker...');
    return await _pickFileFromOS(allowedExtensions: allowedExtensions);
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
  Future<List<int>?> pickFile({List<String>? allowedExtensions}) async {
    debugPrint('[WebFallbackFilePicker] Opening browser file input...');
    return await _pickFileFromOS(allowedExtensions: allowedExtensions);
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
