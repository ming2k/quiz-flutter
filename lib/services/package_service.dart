import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart'; // For ZipDecoder if needed, and InputFileStream if we used it, but mainly for consistent types. 
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'database_service.dart';

/// Result of a package import operation
class ImportResult {
  final bool success;
  final String? errorMessage;
  final String? packageName;

  ImportResult.success(this.packageName)
      : success = true,
        errorMessage = null;

  ImportResult.cancelled() 
      : success = false,
        errorMessage = null,
        packageName = null;

  ImportResult.error(this.errorMessage)
      : success = false,
        packageName = null;

  bool get isCancelled => !success && errorMessage == null;
}

/// Progress callback for import operation
typedef ImportProgressCallback = void Function(String status, double? progress);

class PackageService {
  static final PackageService _instance = PackageService._internal();
  factory PackageService() => _instance;
  PackageService._internal();

  final DatabaseService _db = DatabaseService();

  /// Safely delete a directory, ignoring errors
  Future<void> _safeDelete(Directory dir) async {
    try {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {
      // Ignore deletion errors
    }
  }

  /// Helper to extract archive manually to avoid issues with extractArchiveToDisk
  Future<void> _extractArchive(Archive archive, Directory destDir, {ImportProgressCallback? onProgress}) async {
    for (int i = 0; i < archive.length; i++) {
      final file = archive[i];
      final filename = file.name;
      
      // Basic security check
      if (filename.contains('..')) continue; 

      final destPath = p.join(destDir.path, filename);
      
      if (file.isFile) {
        final outFile = File(destPath);
        await outFile.parent.create(recursive: true);
        
        // file.content is dynamic (List<int> or InputStream)
        // We cast to List<int> assuming it's loaded in memory or compatible
        final data = file.content as List<int>;
        await outFile.writeAsBytes(data);
      } else {
        await Directory(destPath).create(recursive: true);
      }
      
      // Update progress occasionally
      if (onProgress != null && i % 20 == 0) {
        // Map 0..1 to 0.3..0.5 in the main flow
        onProgress('Extracting... ${(i / archive.length * 100).toInt()}%', 0.3 + (i / archive.length) * 0.2);
      }
    }
  }

  /// Import a package with progress reporting
  /// Returns [ImportResult] indicating success, cancellation, or error
  Future<ImportResult> importPackage({ImportProgressCallback? onProgress}) async {
    try {
      // 1. Pick File
      onProgress?.call('Selecting file...', null);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.single.path == null) {
        return ImportResult.cancelled();
      }

      String path = result.files.single.path!;
      String fileName = p.basename(path);

      // Validate file extension
      if (!path.toLowerCase().endsWith('.zip') && !path.toLowerCase().endsWith('.quizpkg')) {
        return ImportResult.error('Invalid file type. Please select a .zip or .quizpkg file.');
      }

      File zipFile = File(path);

      // Check if file exists and is readable
      if (!await zipFile.exists()) {
        return ImportResult.error('Selected file does not exist.');
      }

      // 2. Prepare Destination
      onProgress?.call('Preparing...', 0.1);

      final appDir = await getApplicationDocumentsDirectory();
      final packagesDir = Directory(p.join(appDir.path, 'packages'));
      if (!await packagesDir.exists()) {
        await packagesDir.create(recursive: true);
      }

      String packageName = p.basenameWithoutExtension(zipFile.path);
      String packageId = '${packageName}_${DateTime.now().millisecondsSinceEpoch}';
      final destDir = Directory(p.join(packagesDir.path, packageId));

      // 3. Unzip
      onProgress?.call('Extracting "$fileName"...', 0.3);

      int fileCount = 0;
      try {
        final bytes = await zipFile.readAsBytes();
        if (bytes.isEmpty) {
          return ImportResult.error('Failed to read package file. The file appears to be empty.');
        }

        final archive = ZipDecoder().decodeBytes(bytes);
        fileCount = archive.length;

        if (archive.isEmpty) {
          return ImportResult.error('The package file is empty or invalid.');
        }

        // Create destination directory
        if (!await destDir.exists()) {
          await destDir.create(recursive: true);
        }

        // Manual extraction
        await _extractArchive(archive, destDir, onProgress: onProgress);
        
      } catch (e) {
        return ImportResult.error('Failed to extract package: $e');
      }

      onProgress?.call('Extracted $fileCount files...', 0.5);

      // 4. Validate and Parse
      onProgress?.call('Validating package structure...', 0.6);

      // List all extracted files for debugging
      List<String> extractedFiles = [];
      try {
        await for (final entity in destDir.list(recursive: true)) {
          extractedFiles.add(p.relative(entity.path, from: destDir.path));
        }
      } catch (e) {
        // Ignore listing errors
      }

      File dataFile = File(p.join(destDir.path, 'data.json'));

      // Check for nested directory structure (common in some zip files)
      if (!await dataFile.exists()) {
        try {
          final entities = await destDir.list().toList();
          final directories = entities.whereType<Directory>().toList();

          for (final dir in directories) {
            final nestedData = File(p.join(dir.path, 'data.json'));
            if (await nestedData.exists()) {
              // Found data.json in subdirectory. Flatten this directory.
              onProgress?.call('Flattening package structure...', 0.7);

              await for (final entity in dir.list()) {
                final newPath = p.join(destDir.path, p.basename(entity.path));
                // Use rename to move files/directories
                await entity.rename(newPath);
              }

              // Remove the now empty directory
              try {
                await dir.delete(recursive: true);
              } catch (_) {}

              // Update dataFile reference
              dataFile = File(p.join(destDir.path, 'data.json'));
              break;
            }
          }
        } catch (e) {
          print('Error flattening package: $e');
        }
      }

      if (!await dataFile.exists()) {
        // Try finding any json file
        try {
          final entities = await destDir.list().toList();
          final jsonFiles = entities.where(
            (e) => e.path.endsWith('.json') && !e.path.endsWith('manifest.json')
          ).toList();

          if (jsonFiles.isEmpty) {
            // Clean up extracted files on error
            await _safeDelete(destDir);

            String fileList = extractedFiles.isEmpty
                ? 'No files were extracted.'
                : 'Extracted files:\n${extractedFiles.take(10).join('\n')}${extractedFiles.length > 10 ? '\n... and ${extractedFiles.length - 10} more' : ''}';

            return ImportResult.error(
              'Invalid package structure: No data.json found.\n\n'
              'The package should contain a data.json file with questions.\n\n'
              '$fileList'
            );
          }

          final jsonFile = jsonFiles.first;
          if (jsonFile is File) {
            onProgress?.call('Importing questions...', 0.8);
            final importError = await _importData(jsonFile, packageId);
            if (importError != null) {
              await _safeDelete(destDir);
              return ImportResult.error(importError);
            }
          }
        } catch (e) {
          await _safeDelete(destDir);
          return ImportResult.error('Failed to validate package: $e');
        }
      } else {
        onProgress?.call('Importing questions...', 0.8);
        final importError = await _importData(dataFile, packageId);
        if (importError != null) {
          await _safeDelete(destDir);
          return ImportResult.error(importError);
        }
      }

      onProgress?.call('Complete!', 1.0);
      return ImportResult.success(packageName);

    } catch (e) {
      return ImportResult.error('Unexpected error: $e');
    }
  }

  /// Import data from JSON file. Returns error message on failure, null on success.
  Future<String?> _importData(File jsonFile, String packageId) async {
    try {
      final content = await jsonFile.readAsString();

      dynamic decoded;
      try {
        decoded = jsonDecode(content);
      } catch (e) {
        return 'Invalid JSON format in data file.';
      }

      if (decoded is! Map<String, dynamic>) {
        return 'Invalid data format: Expected a JSON object.';
      }

      await _db.importData(decoded, packageId);
      return null; // Success
    } catch (e) {
      return 'Failed to import data: $e';
    }
  }
  
  // Helper to get image root for a package
  Future<String?> getPackageImagePath(String packageId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final packageDir = Directory(p.join(appDir.path, 'packages', packageId));
    
    // Always return the package root directory.
    // Since data.json is located here, relative paths in the HTML (e.g., "images/pic.png")
    // should be resolved relative to this directory.
    if (await packageDir.exists()) {
      return packageDir.path;
    }
    
    return null;
  }

  /// Import a built-in package from assets
  /// [assetPath] should be like 'assets/packages/sample-quiz.zip'
  Future<ImportResult> importBuiltInPackage(String assetPath) async {
    try {
      // Load from assets
      final bytes = await rootBundle.load(assetPath);
      final data = bytes.buffer.asUint8List();

      if (data.isEmpty) {
        return ImportResult.error('Built-in package is empty.');
      }

      // Prepare destination
      final appDir = await getApplicationDocumentsDirectory();
      final packagesDir = Directory(p.join(appDir.path, 'packages'));
      if (!await packagesDir.exists()) {
        await packagesDir.create(recursive: true);
      }

      String packageName = p.basenameWithoutExtension(assetPath);
      String packageId = '${packageName}_builtin';
      final destDir = Directory(p.join(packagesDir.path, packageId));

      // Extract
      try {
        final archive = ZipDecoder().decodeBytes(data);
        if (archive.isEmpty) {
          return ImportResult.error('Built-in package is invalid.');
        }

        if (!await destDir.exists()) {
          await destDir.create(recursive: true);
        }

        // Manual extraction
        await _extractArchive(archive, destDir);
        
      } catch (e) {
        return ImportResult.error('Failed to extract built-in package: $e');
      }

      // Find and import data.json
      final dataFile = File(p.join(destDir.path, 'data.json'));

      if (!await dataFile.exists()) {
        // Try finding any json file
        final entities = await destDir.list().toList();
        final jsonFiles = entities.where(
          (e) => e.path.endsWith('.json') && !e.path.endsWith('manifest.json')
        ).toList();

        if (jsonFiles.isEmpty) {
          await _safeDelete(destDir);
          return ImportResult.error('Built-in package has no data.json.');
        }

        final jsonFile = jsonFiles.first;
        if (jsonFile is File) {
          final importError = await _importData(jsonFile, packageId);
          if (importError != null) {
            await _safeDelete(destDir);
            return ImportResult.error(importError);
          }
        }
      } else {
        final importError = await _importData(dataFile, packageId);
        if (importError != null) {
          await _safeDelete(destDir);
          return ImportResult.error(importError);
        }
      }

      return ImportResult.success(packageName);
    } catch (e) {
      return ImportResult.error('Failed to load built-in package: $e');
    }
  }
}