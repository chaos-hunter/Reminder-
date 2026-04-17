# Reminder App

A full-scale, production-ready Reminder and Journal application built with **Flutter**. This application features a robust backend powered by Firebase, secure authentication, native local notifications, and background services to ensure timely reminders.

## Features

- **Firebase Backend:** Cloud synchronization and storage using Cloud Firestore.
- **Secure Authentication:** User management via Firebase Authentication (Email/Password).
- **Timezone-Aware Scheduling:** Local notifications integration for precise, time-based event triggers.
- **Background Execution:** `flutter_background_service` ensures tasks and reminders process even when the app is minimized.
- **Geolocation Support:** Fetches and processes location data using `geolocator`.
- **Persistent Local Storage:** Retains user session and preferences locally via `shared_preferences`.
- **Environment Driven:** Secure configuration for API keys using `.env` files.

## Prerequisites

Before running this project locally, ensure you have the following installed:
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- IDE of your choice (VS Code, Android Studio, IntelliJ) with Flutter extensions installed.
- Android Studio / Android SDK (for Android development)
- Xcode (for iOS development, macOS only)

## Getting Started

Follow these steps to set up the project locally after cloning the repository from GitHub.

### 1. Clone the Repository

```bash
git clone <your-repository-url>
cd reminder-app
```

### 2. Install Dependencies

Fetch all the required Flutter and Dart packages:

```bash
flutter pub get
```

### 3. Setup Environment Variables

This project requires a `.env` file at the root of the directory to securely store Firebase API keys, Maps credentials, and other sensitive configurations.

1. Locate the `.env.example` file provided in the repository.
2. Copy it to create your active `.env` file. You can do this via terminal:
   ```bash
   cp .env.example .env
   ```
   *(On Windows Command Prompt/PowerShell, you can manually copy/paste the file or use `copy .env.example .env`)*
3. Open `.env` and fill in the missing values with your actual Firebase configuration keys and API credentials.

**Note:** The `.env` file is explicitly ignored in `.gitignore` to prevent secret leakage.

### 4. Connect a Device or Emulator

You can run the app on a physical device or an emulator. 

**For a Physical Android Device:**
1. Enable **Developer Mode** and **USB Debugging** on your phone.
2. Connect your phone via USB to your computer.
3. Verify the connection by running:
   ```bash
   flutter devices
   ```

**For an Emulator:**
Start an Android Virtual Device (AVD) using Android Studio or an iOS Simulator via Xcode.

### 5. Run the Application

Once your device is connected and dependencies are installed, start the app:

```bash
flutter run
```

*(You may need to ensure location and notification permissions are allowed upon the first launch).*

## Running Tests

Testing is crucial for maintaining this application's reliability. This project includes automated tests utilizing the `flutter_test` package.

To run the entire automated test suite (including widget and unit tests located in the `test/` directory):

```bash
flutter test
```

To execute a specific test file, for instance, the default widget test:

```bash
flutter test test/widget_test.dart
```

## Building for Production

To generate a standalone APK for Android deployment:

```bash
flutter build apk --release
```

The compiled `.apk` file will be located in the `build/app/outputs/flutter-apk/` directory.
