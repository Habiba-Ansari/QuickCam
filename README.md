# 📸 QuickClick - Temporary Camera App

## 🚀 Overview
QuickClick is a smart camera app designed for temporary photos that you only need for a short time. Capture bills, documents, receipts, or any temporary images that auto-delete after 30 days, keeping your phone storage clean without manual cleanup.

## ✨ Features
- **📷 Smart Temporary Storage**: Photos auto-delete after 30 days
- **🎯 Clean Interface**: Simple camera-first design
- **🔒 Local Storage**: No internet required, works offline
- **📂 Gallery with Download Option**: Save important photos permanently
- **⏰ Day Counter**: Shows remaining days for each photo
- **🚫 No Clutter**: Won't mix with your phone's main gallery
- **🔄 Auto Cleanup**: Expired photos are automatically removed

## 📱 Screenshots
```
1. Camera Screen - Full-screen camera with capture button
2. Gallery View - Grid layout with day counters
3. Image Preview - Download/Delete options
```

## 🛠️ Installation

### Prerequisites
- Flutter SDK (version 3.0.0 or higher)
- Android Studio/VSCode
- Android device/emulator with camera

### Steps
1. **Clone the repository**
```bash
git clone https://github.com/yourusername/quickclick.git
cd quickclick
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
flutter run
```

## 🏗️ Project Structure
```
quickclick/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── screens/
│   │   ├── camera_screen.dart    # Main camera interface
│   │   └── gallery_screen.dart   # Photo gallery with download
│   └── services/
│       ├── camera_service.dart   # Camera handling
│       └── local_storage_service.dart  # Local image management
├── android/                      # Android configuration
├── ios/                         # iOS configuration
├── assets/                      # App assets (logos, icons)
└── pubspec.yaml                 # Dependencies
```

## 🔧 Configuration

### Android Permissions
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### Dependencies (pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter
  camera: ^0.10.5           # Camera functionality
  path_provider: ^2.1.1     # Local file storage
  permission_handler: ^11.0.1 # Permission management
  path: ^1.8.3              # Path manipulation
```

## 📖 Usage Guide

### Taking Photos
1. Open QuickClick app
2. Point camera at subject
3. Tap capture button
4. Photo saves automatically (30-day timer starts)

### Managing Photos
- **View Gallery**: Tap gallery icon in camera screen
- **Download Permanently**: Tap any photo → Blue download button
- **Delete Early**: Tap any photo → Red delete button
- **Check Expiry**: See day counter on each thumbnail

### Photo Storage Location
- **Temporary**: App's private storage (auto-deletes)
- **Permanent**: Downloads/QuickClick folder (when downloaded)

## 🔄 How It Works

### Storage System
```
Camera → App Storage (30 days) → Auto Delete
                    ↓
            Download → Phone Gallery (Permanent)
```

### File Management
- Images stored in: `/data/data/com.example.quickclick/quickclick_images/`
- Metadata in JSON: Tracks creation/expiry dates
- Automatic daily cleanup on app launch

## 🚀 Building for Release

### Android
```bash
flutter build apk --release
# OR for app bundle
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 📊 Storage Efficiency
- Images compressed to JPEG medium quality
- Automatic cleanup saves storage space
- Metadata stored efficiently in JSON
- No duplicate files

## 🤝 Contributing
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 🐛 Troubleshooting

### Common Issues
1. **Camera not working**: Check camera permissions
2. **Storage full**: App auto-cleans expired photos
3. **Can't download**: Grant storage permission
4. **App crashes on launch**: Run `flutter clean`

### Solutions
```bash
# Clear build cache
flutter clean

# Update dependencies
flutter pub upgrade

# Reinstall app
flutter run --uninstall-and-reinstall
```

## 📈 Future Features
- [ ] Cloud backup option
- [ ] Custom retention periods (7, 15, 30 days)
- [ ] Image organization (folders/tags)
- [ ] OCR text extraction from bills
- [ ] Bulk delete functionality
- [ ] Dark mode

## 🧪 Testing
```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage
```

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments
- Flutter team for the amazing framework
- Camera plugin contributors
- All open-source dependencies used

## 📞 Support
For support, email [your-email] or create an issue in the GitHub repository.

## 🎯 Quick Start Commands
```bash
# First time setup
git clone [repo-url]
cd quickclick
flutter pub get
flutter run

# Development
flutter run           # Run app
flutter test          # Run tests
flutter build apk     # Build APK
flutter clean         # Clean build
```

---
**Made with ❤️ for temporary memories that don't need to last forever**

*"Capture today, forget tomorrow - automatically!"*
