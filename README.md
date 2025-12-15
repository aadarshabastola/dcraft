# dCraft: Tusayan White Ware Sherd Classifier

A specialized Flutter application for archaeological research that uses a ConvNeXt Image Classification Model to identify and classify Tusayan White Ware pottery sherds.

## 📝 Description

dCraft is designed to assist archaeologists, researchers, and cultural heritage professionals in the identification and classification of Tusayan White Ware ceramic fragments. This application leverages advanced computer vision techniques through the ConvNeXt model to provide accurate and efficient classification of pottery sherds directly from field photographs.

### What is Tusayan White Ware?

Tusayan White Ware is a significant ceramic tradition from the American Southwest, primarily produced between 825-1300 CE. These ceramics feature distinctive black designs on white slipped surfaces and are important chronological and cultural markers in archaeological research.

## ✨ Features

- **AI-Powered Classification**: Utilizes the state-of-the-art ConvNeXt neural network architecture for high-accuracy pottery sherd identification
- **Real-time Analysis**: Process images directly from your device camera
- **Offline Capability**: Perform classifications without internet connectivity
- **Image Management**: Import images from gallery, organize, and manage your sherd collection
- **Detailed Results**: View classification confidence scores and alternative matches
- **Export Functionality**: Share results in app or in CSV
- **Reference Database**: Built-in reference images of classified sherds for comparison
- **Cross-Platform**: Available on Android, iOS, and as a web application

## 🔧 Technical Details

### Flutter Implementation
- Built with Flutter 3.10+
- TensorFlow Lite integration for model inference
- Camera integration
- Local Hive database for result storage

## 📱 Installation

### Prerequisites
- Android 6.0+ or iOS 12.0+

### Android Installation

1. **Download the APK**:
   - Visit the [Releases](https://github.com/aadarshabastola/dcraft/releases) page
   - Download the latest APK file for Android

2. **Install on Your Device**:
   - Enable "Install from Unknown Sources" in your Android settings
   - Open the downloaded APK file and follow the installation prompts

3. **Launch the App**:
   - Open dCraft from your app drawer and start classifying sherds

### iOS Installation
**Official Distribution**: Coming soon via TestFlight

**Workaround - Manual Installation via Xcode**:
1. Clone or download this repository
2. Open the project in Xcode
3. Connect your iOS device via USB
4. In Xcode, select your device from the target device list
5. Select **Product** → **Scheme** → **Edit Scheme**
6. Under **Run**, change **Build Configuration** to **Release**
7. Click **Run** (or press Cmd+R) to build and install on your device
8. Trust the developer certificate on your device: **Settings** → **General** → **VPN & Device Management**

## 📘 Usage Guide

1. **Capture or Select Image**: Use the camera button to photograph a sherd or select from your gallery
2. **Processing**: The app will analyze the image using the ConvNeXt model
3. **View Results**: Review the classification results, showing the most likely Tusayan White Ware types with confidence scores
4. **Save or Export**: Store results for later reference or export ino Google Drive
5. **Reference**: Compare with the reference database for verification


## 🧪 Development

### Setting Up Development Environment
1. Install Flutter by following the [official guide](https://flutter.dev/docs/get-started/install)
2. Set up an emulator or connect a physical device
3. Use VS Code with Flutter extensions or Android Studio with Flutter plugin

### 📂 Project Structure

```
dcraft/
├── android/            # Android-specific code
├── ios/                # iOS-specific code
├── lib/
│   ├── main.dart       # Application entry point
│   ├── screens/        # UI screens
│   ├── services/       # Services
│   ├── providers/      # State management providers
│   └── widgets/        # Reusable UI components
├── assets/             # ML models
├── fonts/              # Custom fonts         
├── images/             # Static images
```


## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📧 Contact

- **Project Lead**: [Leszek Pawlowicz](mailto:Leszek.Pawlowicz@nau.edu)
- **Developer**: [Aadarsha Bastola](mailto:Aadarsha.Bastola@nau.edu)