import 'dart:io';

import 'package:dcraft/provider/drive_auth_provider.dart';
import 'package:dcraft/screens/settings_page.dart';
import 'package:dcraft/services/drive_storage_service.dart';
import 'package:dcraft/widgets/sherd_details.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:hive/hive.dart';

import 'package:dcraft/widgets/classification_item.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

class MyClassifications extends StatefulWidget {
  const MyClassifications({super.key});

  @override
  State<MyClassifications> createState() => _MyClassificationsState();
}

class _MyClassificationsState extends State<MyClassifications> {
  List<Map<dynamic, dynamic>> classificationHistory = [];

  late int numClassifications;
  late bool isLoggedIn;

  @override
  void initState() {
    super.initState();
    // Load data from Hive
    loadClassificationsFromHive();
  }

  void loadClassificationsFromHive() async {
    var box = Hive.box('classificationBox');

    // Fetch all classifications
    List<Map<dynamic, dynamic>> classifications = [];
    for (var i = 0; i < box.length; i++) {
      classifications.add(box.getAt(i));
    }

    setState(() {
      classificationHistory = classifications;
      numClassifications = classifications.length;
    });
  }

  List<Map<String, dynamic>> convertData(List<Map<dynamic, dynamic>> data) {
    List<Map<String, dynamic>> result = [];

    for (var entry in data) {
      Map<String, dynamic> newEntry = {};

      // Filename: Extract from imageLocation
      newEntry['ImagePath'] = entry['imageLocation'];
      newEntry['Filename'] = entry['imageLocation'].split('/').last;

      // Extract classifications and round them to 1 decimal place
      entry['allClassifications'].forEach((key, value) {
        newEntry[key] =
            (value * 100).toStringAsFixed(2); // Convert to percentage and round
      });

      // Add latitude, longitude, and timestamp
      newEntry['Latitude'] = entry['latitude'];
      newEntry['Longitude'] = entry['longitude'];
      newEntry['Timestamp'] = entry['timestamp']; // Remove milliseconds

      result.add(newEntry);
    }

    return result;
  }

  void uploadToDrive() async {
    final driveApi =
        Provider.of<GoogleDriveAuthProvider>(context, listen: false).driveApi;
    if (driveApi == null) {
      debugPrint('Drive API not initialized');
      return;
    }

    DriveStorageService _driveStorageService = DriveStorageService(driveApi);

    // _driveStorageService.initializeCraftFolder();

    // await Future.delayed(const Duration(seconds: 5));

    List<Map<String, dynamic>> formattedDataList =
        convertData(classificationHistory);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Uploading'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('Uploading to Drive...'),
                  ],
                ),
              );
            },
          );
        },
      );

      for (var i = 0; i < formattedDataList.length; i++) {
        await _driveStorageService.uploadImageAndData(formattedDataList[i]);
        Navigator.of(context).pop(); // Remove current dialog
        if (i < formattedDataList.length - 1) {
          // Don't show for last item
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Uploading'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: (i + 1) / formattedDataList.length,
                    ),
                    const SizedBox(height: 16),
                    Text('Uploading ${i + 1} of ${formattedDataList.length}'),
                  ],
                ),
              );
            },
          );
        }
      }

      var box = Hive.box('classificationBox');
      // Delete images from their respective paths
      for (var classification in classificationHistory) {
        String imagePath = classification['imageLocation'];
        final imageFile = File(imagePath);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      }

      await box.clear(); // Clear all data in the Hive box

      setState(() {
        classificationHistory.clear();
      });

      _showMessage('Data uploaded to Drive successfully.');
    } catch (e) {
      Navigator.of(context, rootNavigator: true)
          .pop(); // Remove progress dialog

      _showMessage('Failed to upload: ${e.toString()}', 'Error');
    }
  }

  void _showMessage(String message, [String? title]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? 'Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void removeSpecificClassification(int index) async {
    // Show confirmation dialog
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text(
              'Are you sure you want to delete this classification?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        var box = Hive.box('classificationBox');
        // Get image location before deleting from Hive
        String imageLocation = box.getAt(index)['imageLocation'];
        await box.deleteAt(index);
        // Delete the image file
        final imageFile = File(imageLocation);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
        loadClassificationsFromHive(); // Refresh the list
      } catch (e) {
        _showMessage('Failed to remove classification: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider =
        Provider.of<GoogleDriveAuthProvider>(context, listen: false);

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 80,
            title: FittedBox(
              fit: BoxFit.scaleDown,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'History',
                  style: TextStyle(
                      fontFamily: 'Uber',
                      fontSize: 60,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  child: classificationHistory.isEmpty
                      ? const Center(
                          child: Text(
                              'There is no saved data in your device currently.'))
                      : ListView.builder(
                          itemCount: classificationHistory.length,
                          itemBuilder: (context, index) {
                            var data = classificationHistory[index];
                            return GestureDetector(
                              onTap: () {
                                showSherdDetailsDialog(
                                  context,
                                  imageUrl: data['imageLocation'],
                                  title: data['primaryClassification'],
                                  details: data['allClassifications'],
                                  timestamp: data['timestamp'],
                                  fromHive: true,
                                  latitude: data['latitude'],
                                  longitude: data['longitude'],
                                );
                              },
                              child: ClassificationItem(
                                fromHive: true,
                                imageUrl: data['imageLocation'],
                                title: data['primaryClassification'],
                                timestamp: data['timestamp'],
                                onDelete: () =>
                                    removeSpecificClassification(index),
                              ),
                            );
                          },
                        ),
                ),
                authProvider.authService.isSignedIn
                    ? FilledButton.icon(
                        icon: Icon(FontAwesomeIcons.googleDrive),
                        onPressed: () => uploadToDrive(),
                        label: Text('Upload to Google Drive'),
                      )
                    : FilledButton.icon(
                        icon: Icon(FontAwesomeIcons.googleDrive),
                        onPressed: () {
                          Navigator.push(
                              context,
                              PageTransition(
                                  child: SettingsPage(),
                                  type: PageTransitionType.fade));
                        },
                        label: Text('Connect to Google Drive'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
