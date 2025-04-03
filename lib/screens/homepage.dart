import 'dart:io';
import 'dart:math';
import 'package:dcraft/provider/model_provider.dart';
import 'package:dcraft/screens/about/about_tww.dart';
import 'package:dcraft/screens/edit_results.dart';
import 'package:dcraft/screens/my_classificatoins.dart';
import 'package:dcraft/screens/settings_page.dart';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:page_transition/page_transition.dart';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class HomePage extends StatefulWidget {
  static const String id = 'home';
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker picker = ImagePicker();
  File? selectedImage;
  String? classificaitonData;
  Position? currentPosition;

  final TextEditingController siteIdController = TextEditingController();

  Interpreter? interpreter = null;

  late List<String> labels = [];

  List<String> regular_labels = [
    "Kana'a",
    "Black Mesa",
    "Sosi",
    "Dogoszhi",
    "Flagstaff",
    "Tusayan",
    "Kayenta"
  ];

  List<String> nd_labels = [
    "Kana'a",
    "Black Mesa",
    "Sosi",
    "Flagstaff",
    "Tusayan",
    "Kayenta"
  ];

  late List<int> _outputShape;

  Map<String, dynamic>? classificatoinMap;

  late ModelProvider modelProvider;
  late String modelPath = 'assets/convnext.tflite';

  @override
  void initState() {
    super.initState();

    loadModel(modelPath);

    modelProvider = Provider.of<ModelProvider>(context, listen: false);

    modelProvider.addListener(() {
      if (modelProvider.selectedModel == "ConvNexT") {
        modelPath = "assets/convnext.tflite";
        labels = regular_labels;
      }

      if (modelProvider.selectedModel == "ConvNext (Non-Dogoszi)") {
        modelPath = "assets/convnext_nd.tflite";
        labels = nd_labels;
      }
      loadModel(modelPath);
    });

    getSiteId();

    // Get initial position
    _determinePosition().then((position) {
      setState(() {
        currentPosition = position;
      });
    }).catchError((error) {
      print('Error getting initial position: $error');
    });

    // Listen for position changes
    final positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      ),
    );

    positionStream.listen((Position position) {
      setState(() {
        currentPosition = position;
      });
    }, onError: (error) {
      print('Position stream error: $error');
    });
  }

  Future<void> getSiteId() async {
    final prefs = await SharedPreferences.getInstance();
    final siteId = prefs.getString('siteId') ?? '';
    setState(() {
      siteIdController.text = siteId;
    });
  }

  Future<void> loadModel(String modelPath) async {
    interpreter?.close();
    interpreter = await Interpreter.fromAsset(modelPath);
    _outputShape = interpreter!.getOutputTensor(0).shape;
  }

  Future pickAndCropImage(ImageSource source) async {
    final pickedImage =
        await picker.pickImage(source: source, imageQuality: 50);

    if (pickedImage == null) {
      return;
    }

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedImage.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: true),
        IOSUiSettings(
          aspectRatioLockEnabled: true,
          title: 'Crop Image',
        ),
      ],
    );

    if (croppedFile == null) {
      return;
    }

    // Create a permanent directory path for the image
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String filePath = '${appDir.path}/$fileName';

    // Copy the temporary file to permanent storage
    await File(croppedFile.path).copy(filePath);

    // Convert the image to grayscale and resize to 400x400 pixels
    final grayscaleImage = img.grayscale(
        img.decodeImage(await File(croppedFile.path).readAsBytes())!);
    final resizedGrayscaleImage =
        img.copyResize(grayscaleImage, width: 800, height: 800);

    // Save the processed image to the permanent storage
    final processedImageFile = File(filePath);
    await processedImageFile
        .writeAsBytes(img.encodeJpg(resizedGrayscaleImage, quality: 70));

    setState(() {
      selectedImage = File(filePath);
    });

    classifyImage();
  }

  void resetScreen({bool hardReset = false}) async {
    if (selectedImage != null && hardReset) {
      await selectedImage!.delete();
    }
    setState(() {
      selectedImage = null;
      classificaitonData = null;
    });
  }

  Position randomizePosition(Position position, double distanceMeters) {
    // Constants
    const double earthRadius = 6371000; // Earth's radius in meters

    // Convert distanceMeters meters to degrees
    double randomDistance = distanceMeters; // 500 meters
    double latOffset = (randomDistance / earthRadius) * (180 / pi);
    double lonOffset =
        (randomDistance / (earthRadius * cos(pi * position.latitude / 180))) *
            (180 / pi);

    // Generate random numbers to decide the direction of change
    double randomLat = (Random().nextDouble() * 2 - 1) * latOffset;
    double randomLon = (Random().nextDouble() * 2 - 1) * lonOffset;

    // Calculate new random position
    double newLatitude = position.latitude + randomLat;
    double newLongitude = position.longitude + randomLon;

    return Position(
      latitude: newLatitude,
      longitude: newLongitude,
      headingAccuracy: position.headingAccuracy,
      altitudeAccuracy: position.altitudeAccuracy,
      timestamp: position.timestamp,
      accuracy: position.accuracy,
      altitude: position.altitude,
      heading: position.heading,
      speed: position.speed,
      speedAccuracy: position.speedAccuracy,
    );
  }

  late List<String> currentLabels = labels;

  void classifyImage() async {
    Position pos;

    //randomize the position by 500 meters
    if (currentPosition != null &&
        currentPosition!.latitude != 0.0 &&
        currentPosition!.longitude != 0.0) {
      pos = randomizePosition(currentPosition!, 500);
    } else if (currentPosition != null) {
      // Use the current position as is
      pos = currentPosition!;
    } else {
      // Create a default position if currentPosition is null
      pos = Position(
        latitude: 0,
        longitude: 0,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }

    const inputSize = 224;
    // Resize the image
    final imageBytes = await selectedImage!.readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);
    if (decodedImage == null) return;
    final resizedImage = img.copyResize(decodedImage,
        width: inputSize,
        height: inputSize,
        interpolation: img.Interpolation.average);

    // Prepare the input buffer for the TFLite model
    final input = List.generate(
        1,
        (_) => List.generate(
            inputSize,
            (_) =>
                List.generate(inputSize, (_) => List<double>.filled(3, 0.0))));

    // Keep original RGB values
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resizedImage.getPixel(x, y);
        input[0][y][x][0] = img.getRed(pixel).toDouble();
        input[0][y][x][1] = img.getGreen(pixel).toDouble();
        input[0][y][x][2] = img.getBlue(pixel).toDouble();
      }
    }

// Run the model inference
    final outputBuffer =
        List.generate(1, (_) => List.filled(_outputShape[1], 0.0));

    interpreter!.run(input, outputBuffer);

    Map<String, double> resultMap = {};

    for (int i = 0; i < labels.length; i++) {
      double confidence = outputBuffer[0][i];

      resultMap[labels[i]] = confidence;
    }

    if (modelProvider.selectedModel == "ConvNext (Non-Dogoszi)") {
      resultMap['Dogoszhi'] = 0.0;
    }

    String highestConfidenceLabel = '';
    double highestConfidenceValue = 0.0;

    resultMap.forEach((label, value) {
      if (value > highestConfidenceValue) {
        highestConfidenceValue = value;
        highestConfidenceLabel = label;
      }
    });

    setState(() {
      classificatoinMap = {
        'primaryClassification': highestConfidenceLabel,
        'allClassifications': resultMap,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'edited': false,
      };
    });

    setState(() {
      currentPosition = pos;
      classificaitonData = "Classified";
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Show dialog informing the user that location services are disabled
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Location Disabled'),
              content: const Text(
                  'Location services are disabled. Please enable location save location data'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    resetScreen();
                    setState(() {
                      currentPosition = Position(
                        latitude: 0,
                        longitude: 0,
                        timestamp: DateTime.now(),
                        accuracy: 0,
                        altitude: 0,
                        heading: 0,
                        speed: 0,
                        speedAccuracy: 0,
                        altitudeAccuracy: 0,
                        headingAccuracy: 0,
                      );
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        distanceFilter: 100,
      ),
    );
  }

  // Saving Data locally
  void saveClassificationLocally() async {
    if (siteIdController.text.isEmpty) {
      _showError('Site ID cannot be empty.');
      return;
    }

    // Open the Hive box for classifications
    var box = Hive.box('classificationBox');
    String imageLocation = selectedImage!.path;

    // Add additional fields to the classification map
    classificatoinMap!['timestamp'] = DateTime.now();
    classificatoinMap!['imageLocation'] = imageLocation;
    classificatoinMap!['latitude'] = currentPosition!.latitude;
    classificatoinMap!['longitude'] = currentPosition!.longitude;
    classificatoinMap!['siteId'] = siteIdController.text;

    classificatoinMap!['modelUsed'] = modelProvider.selectedModel;

    // Save the site ID to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('siteId', siteIdController.text);

    try {
      // Save the classification data locally to Hive
      await box.add(classificatoinMap!);
      resetScreen(); // Reset the screen after saving
    } catch (e) {
      _showError('Error saving classification: $e');
    }
  }

  void editClassification() async {
    Map<String, dynamic>? editedClassificatoin = await Navigator.push(
        context,
        PageTransition(
            child: EditResults(
              classificatoinMap: classificatoinMap,
            ),
            type: PageTransitionType.fade));

    setState(() {
      classificatoinMap = editedClassificatoin;
    });
  }

  void clearBox() {
    var box = Hive.box('classificationBox');

    box.clear();
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            toolbarHeight: 80,
            title: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'dCRAFT',
                  style: TextStyle(
                      fontFamily: 'Uber',
                      fontSize: 60,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  selectedImage == null
                      ? Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        pickAndCropImage(ImageSource.camera),
                                    child: Container(
                                      height:
                                          MediaQuery.of(context).size.width / 3,
                                      decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary, // select color from current theme scheme
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(5))),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 40, vertical: 8),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.camera_alt_rounded,
                                              size: 80,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                            ),
                                            Text(
                                              'CAMERA',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontFamily: 'Uber',
                                                fontWeight: FontWeight.w900,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        pickAndCropImage(ImageSource.gallery),
                                    child: Container(
                                      width: MediaQuery.of(context).size.width /
                                          2.3,
                                      height:
                                          MediaQuery.of(context).size.width / 3,
                                      decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary, // select color from current theme scheme
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(5))),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 40, vertical: 8),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.image_rounded,
                                              size: 80,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                            ),
                                            Text(
                                              'GALLERY',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontFamily: 'Uber',
                                                fontWeight: FontWeight.w900,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                  context,
                                  PageTransition(
                                      child: const MyClassifications(),
                                      type: PageTransitionType.fade)),
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                height: MediaQuery.of(context).size.width / 3,
                                decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary, // select color from current theme scheme
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(5))),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.history_rounded,
                                        size: 80,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
                                      Text(
                                        'CLASSIFICATION HISTORY',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontFamily: 'Uber',
                                          fontWeight: FontWeight.w900,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          PageTransition(
                                              child: const AboutTww(),
                                              type: PageTransitionType.fade));
                                    },
                                    child: Container(
                                      height:
                                          MediaQuery.of(context).size.width / 3,
                                      decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary, // select color from current theme scheme
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(5))),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 40, vertical: 8),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            FittedBox(
                                              fit: BoxFit.contain,
                                              child: Text(
                                                'ABOUT\nTUSAYAN\nWHITE\nWARE',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontFamily: 'Uber',
                                                  fontWeight: FontWeight.w900,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          PageTransition(
                                              child: SettingsPage(),
                                              type: PageTransitionType.fade));
                                    },
                                    child: Container(
                                      // width: MediaQuery.of(context).size.width / 2.3,
                                      height:
                                          MediaQuery.of(context).size.width / 3,
                                      decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary, // select color from current theme scheme
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(5))),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 40, vertical: 8),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.settings_rounded,
                                              size: 80,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                            ),
                                            Text(
                                              "SETTINGS",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontFamily: 'Uber',
                                                fontWeight: FontWeight.w900,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary,
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Container(),
                  selectedImage != null
                      ? AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer, // select color from current theme scheme
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(5))),
                            width: MediaQuery.of(context).size.width,
                            // height: 100,
                            child: Center(
                                child: selectedImage != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(5),
                                        child: Image.file(
                                          selectedImage!,
                                          fit: BoxFit.cover,
                                          width:
                                              MediaQuery.of(context).size.width,
                                        ))
                                    : Container()),
                          ),
                        )
                      : Container(),
                  const SizedBox(
                    height: 30,
                  ),
                  classificaitonData != null
                      ? Column(
                          children: [
                            TextField(
                              controller: siteIdController,
                              decoration: InputDecoration(
                                labelText: 'Site ID',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(
                              height: 16,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer, // select color from current theme scheme
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(5))),
                              width: MediaQuery.of(context).size.width,
                              child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        "${classificatoinMap!['primaryClassification'].toString()} [${classificatoinMap!['allClassifications']?[classificatoinMap!['primaryClassification']]?.toStringAsFixed(3) ?? "0.0"}]",
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const Text(
                                        'Model Prediction:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      ...classificatoinMap![
                                              'allClassifications']
                                          .entries
                                          .where((entry) =>
                                              (entry as MapEntry<String,
                                                      double>)
                                                  .value >
                                              0.10)
                                          .map((entry) => Text(
                                              '${entry.key}: ${entry.value.toStringAsFixed(3)}')),
                                      SizedBox(height: 8),
                                      const Text(
                                        'Model Used:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(modelProvider.selectedModel),
                                      // Text(
                                      //     "Longitude: ${classificatoinMap!['longitude'].toStringAsFixed(4)}"),
                                    ],
                                  )),
                            ),
                          ],
                        )
                      : Container(),
                  const SizedBox(
                    height: 16,
                  ),
                  selectedImage != null && classificaitonData == null
                      // ? Center(
                      //     child: FilledButton(
                      //         onPressed: classifyImage,
                      //         child: const Text('Classify')),
                      //   )
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : Container(),
                  selectedImage != null && classificaitonData == null
                      ? Center(
                          child: TextButton(
                              onPressed: () => resetScreen(hardReset: true),
                              child: const Text('Clear Image')),
                        )
                      : Container(),
                  selectedImage != null && classificaitonData != null
                      ? Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              FilledButton(
                                  onPressed: saveClassificationLocally,
                                  child: const Text('Save Classification')),
                              FilledButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        PageTransition(
                                            child: const AboutTww(),
                                            type: PageTransitionType.fade));
                                  },
                                  child: const Text('TWW About')),
                            ],
                          ),
                        )
                      : Container(),

                  selectedImage != null && classificaitonData != null
                      ? Center(
                          child: TextButton(
                              onPressed: resetScreen,
                              child:
                                  const Text('Clear Image and Classification')),
                        )
                      : Container(),
                  selectedImage != null && classificaitonData != null
                      ? Center(
                          child: TextButton(
                              onPressed: editClassification,
                              child: const Text('Edit Classification')),
                        )
                      : Container(),

                  // for testing purposes
                  // Center(
                  //   child: FilledButton(
                  //       onPressed: () {
                  //         var box = Hive.box('classificationBox');

                  //         box.clear();
                  //       },
                  //       child: const Text('Clear Local Storage')),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
