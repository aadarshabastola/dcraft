import 'dart:convert';
import 'dart:io';

import 'package:googleapis/drive/v3.dart' as drive;

class DriveStorageService {
  final drive.DriveApi _driveApi;
  static const String _craftFolderName = 'CRAFT';
  static const String _csvFileName = 'craft_classifications.csv';
  static const String _imagesFolderName = 'images';

  /// Local cache to prevent duplicate folder creation
  final Map<String, String?> _folderCache = {};

  DriveStorageService(this._driveApi);

  Future<String?> _findOrCreateFolder(String folderName,
      [String? parentId]) async {
    if (_folderCache.containsKey(folderName)) {
      return _folderCache[folderName];
    }

    String query =
        "mimeType='application/vnd.google-apps.folder' and name='$folderName' and trashed=false";
    if (parentId != null) {
      query += " and '$parentId' in parents";
    }

    var response = await _driveApi.files.list(q: query);
    if (response.files?.isNotEmpty == true) {
      final folderId = response.files!.first.id;
      _folderCache[folderName] = folderId;
      return folderId;
    }

    // Create folder if it doesn't exist
    var folder = drive.File()
      ..name = folderName
      ..mimeType = 'application/vnd.google-apps.folder';
    if (parentId != null) {
      folder.parents = [parentId];
    }

    var createdFolder = await _driveApi.files.create(folder);
    _folderCache[folderName] = createdFolder.id;
    return createdFolder.id;
  }

  Future<void> initializeCraftFolder() async {
    // Avoid duplicate folder creation
    final craftFolderId = await _findOrCreateFolder(_craftFolderName);
    if (craftFolderId == null)
      throw Exception('Failed to create/find CRAFT folder');

    // Create or get images subfolder
    await _findOrCreateFolder(_imagesFolderName, craftFolderId);

    // Ensure CSV file exists
    final csvExists = await _checkCsvExists(craftFolderId);
    if (!csvExists) {
      await _createCsvWithHeaders(craftFolderId);
    }
  }

  Future<bool> _checkCsvExists(String parentId) async {
    var response = await _driveApi.files.list(
      q: "name='$_csvFileName' and '$parentId' in parents and trashed=false",
    );
    return response.files?.isNotEmpty == true;
  }

  Future<void> _createCsvWithHeaders(String parentId) async {
    final headers = [
      'Filename',
      'Kana\'a',
      'Black Mesa',
      'Sosi',
      'Dogoszhi',
      'Flagstaff',
      'Kayenta',
      'Tusayan',
      'Latitude',
      'Longitude',
      'Timestamp'
    ].join(',');

    var file = drive.File()
      ..name = _csvFileName
      ..parents = [parentId]
      ..mimeType = 'text/csv';

    await _driveApi.files.create(
      file,
      uploadMedia: drive.Media(
        Stream.fromIterable([headers.codeUnits]),
        headers.length,
        contentType: 'text/csv',
      ),
    );
  }

  Future<void> appendToCsv(Map<String, dynamic> data) async {
    final craftFolderId = await _findOrCreateFolder(_craftFolderName);
    if (craftFolderId == null) throw Exception('CRAFT folder not found');

    var response = await _driveApi.files.list(
      q: "name='$_csvFileName' and '$craftFolderId' in parents and trashed=false",
    );

    if (response.files?.isEmpty == true) {
      throw Exception('CSV file not found');
    }

    final csvFileId = response.files!.first.id!;
    final csvContent = await _driveApi.files.get(csvFileId,
        downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    final existingContent =
        await csvContent.stream.transform(utf8.decoder).join();

    // Append new data
    final newRow = [
      data['Filename'],
      data['Kana\'a'],
      data['Black Mesa'],
      data['Sosi'],
      data['Dogoszhi'],
      data['Flagstaff'],
      data['Kayenta'],
      data['Tusayan'],
      data['Latitude'],
      data['Longitude'],
      data['Timestamp'],
    ].join(',');

    final updatedContent = '$existingContent\n$newRow';

    // Update file with new content
    await _driveApi.files.update(
      drive.File(),
      csvFileId,
      uploadMedia: drive.Media(
        Stream.fromIterable([updatedContent.codeUnits]),
        updatedContent.length,
        contentType: 'text/csv',
      ),
    );
  }

  Future<void> uploadImage(String imagePath) async {
    final craftFolderId = await _findOrCreateFolder(_craftFolderName);
    if (craftFolderId == null) throw Exception('CRAFT folder not found');

    final imagesFolderId =
        await _findOrCreateFolder(_imagesFolderName, craftFolderId);
    if (imagesFolderId == null) throw Exception('Images folder not found');

    final fileName = imagePath.split('/').last;
    var file = drive.File()
      ..name = fileName
      ..parents = [imagesFolderId]
      ..mimeType = 'image/jpeg';

    final imageBytes = await File(imagePath).readAsBytes();
    await _driveApi.files.create(
      file,
      uploadMedia: drive.Media(
        Stream.fromIterable([imageBytes]),
        imageBytes.length,
      ),
    );
  }

  Future<void> uploadImageAndData(Map<String, dynamic> data) async {
    try {
      // Ensure folder structure is properly initialized before proceeding
      await initializeCraftFolder();

      await appendToCsv(data);
      await uploadImage(data['ImagePath']);
    } catch (e) {
      throw Exception('Failed to process image: $e');
    }
  }
}
