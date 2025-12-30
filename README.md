# NutriScan 🍎

Aplikasi Flutter untuk memindai label Informasi Nilai Gizi (Nutrition Facts) pada kemasan makanan Indonesia menggunakan AI.

## Features ✨

- **📷 Scan Label Nutrisi** - Foto label nutrition facts dan extract datanya otomatis
- **🤖 Gemini AI** - Menggunakan Google Gemini 2.5 Flash untuk akurasi tinggi (~95%)
- **🔄 Offline Fallback** - Bisa digunakan offline dengan ML Kit (akurasi lebih rendah)
- **⚠️ Analisis Risiko** - Peringatan berdasarkan kondisi kesehatan user (diabetes, hipertensi, diet)
- **📋 Riwayat Scan** - Menyimpan semua hasil scan
- **🇮🇩 Format Indonesia** - Mendukung format label BPOM

## Screenshots

*Coming soon*

## Tech Stack 🛠️

- **Flutter** 3.10+
- **Google Gemini 2.5 Flash** - Vision AI untuk OCR
- **Google ML Kit** - Offline text recognition
- **Image Cropper** - Fokus pada area label

## Getting Started 🚀

### Prerequisites

- Flutter SDK 3.10+
- Dart SDK 3.0+
- Android Studio / Xcode
- Gemini API Key (gratis dari [Google AI Studio](https://aistudio.google.com/apikey))

### Installation

```bash
# Clone repository
git clone https://github.com/joelaey/nutriscan.git
cd nutriscan

# Install dependencies
flutter pub get

# Run app
flutter run
```

### Configuration

Gemini API Key sudah termasuk di aplikasi. Untuk production, disarankan memindahkan ke secure storage atau environment variable.

## Build Release 📦

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle (untuk Google Play)
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Project Structure 📁

```
lib/
├── config/
│   └── theme.dart           # App theme configuration
├── models/
│   ├── nutrition_data.dart  # Nutrition data model
│   ├── scan_result.dart     # Scan result model
│   └── user_data.dart       # User profile model
├── screens/
│   ├── home_screen.dart     # Main dashboard
│   ├── scan_screen.dart     # Camera scan
│   ├── result_screen.dart   # Scan results
│   └── ...
├── services/
│   ├── gemini_vision_service.dart  # Gemini AI integration
│   ├── nutri_scan_service.dart     # Main scanning service
│   ├── nutrition_parser.dart       # Offline parser
│   ├── risk_analyzer.dart          # Health risk analysis
│   └── storage_service.dart        # Local storage
└── main.dart
```

## License 📄

This project is for educational purposes (Tugas Kuliah PAM Semester 5).

## Author

**joelaey** - [GitHub](https://github.com/joelaey)
