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
- Flutter 3.10 or higher
- Dart 3.0 or higher
- Android 6.0+ or iOS 12.0+

### Getting Started

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/dcraft.git
   cd dcraft
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the App**:
   ```bash
   flutter run
   ```

## 📘 Usage Guide

1. **Capture or Select Image**: Use the camera button to photograph a sherd or select from your gallery
2. **Processing**: The app will analyze the image using the ConvNeXt model
3. **View Results**: Review the classification results, showing the most likely Tusayan White Ware types with confidence scores
4. **Save or Export**: Store results for later reference or export ino Google Drive
5. **Reference**: Compare with the reference database for verification

## 📂 Project Structure

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

## 🧪 Development

### Setting Up Development Environment
1. Install Flutter by following the [official guide](https://flutter.dev/docs/get-started/install)
2. Set up an emulator or connect a physical device
3. Use VS Code with Flutter extensions or Android Studio with Flutter plugin


## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📧 Contact

- **Project Lead**: [Leszek.Pawlowicz@nau.edu]