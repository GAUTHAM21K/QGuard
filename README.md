# Q-Guard: Post-Quantum Cryptographic Messaging Platform

A Flutter-based cross-platform messaging application implementing CRYSTALS-Kyber post-quantum cryptography for secure end-to-end encrypted communication.


---

## 🔐 Features

-   **Post-Quantum Cryptography**: Implements **CRYSTALS-Kyber** (a NIST standardized algorithm) for quantum-resistant key exchange.
-   **End-to-End Encryption**: Uses **AES-GCM-256** for symmetric encryption of all message content.
-   **Cross-Platform**: A single codebase supports Android, iOS, Windows, macOS, and Linux.
-   **Real-time Messaging**: Leverages **Firebase Firestore** for a scalable, real-time communication backend.
-   **Secure Key Management**: A hybrid approach stores public keys in Firestore for distribution and private keys securely in local device storage.
-   **User Authentication**: Built-in user registration and login using **Firebase Authentication** with email/password.

---

## 🏗️ Architecture

-   **Frontend**: Flutter SDK 3.7.2 with Dart
-   **Backend**: Python Flask API server for handling cryptographic operations.
-   **Database**: Firebase Firestore for message storage and public key distribution.
-   **Cryptography**: CRYSTALS-Kyber implementation via the `pyky` library.
-   **Key Storage**: `SharedPreferences` for local private key storage and Firestore for public keys.



---

## 📋 Prerequisites

-   Flutter SDK `3.7.2` or higher
-   Python `3.8` or higher
-   Git
-   A Firebase project with **Firestore** and **Authentication** enabled.
-   Android Studio / Xcode (for mobile development)
-   Visual Studio / Xcode (for desktop development)

---

## 🚀 Installation & Setup

### Step 1: Clone and Setup Python Cryptography Backend

1.  **Clone the `pyky` repository:**
    ```bash
    git clone [https://github.com/asdfjkl/pyky.git](https://github.com/asdfjkl/pyky.git)
    cd pyky
    ```

2.  **Add the API server file:** Create a file named `api.py` in the root of the `pyky` directory and paste the following content:
    

3.  **Install Python dependencies:**
    ```bash
    pip install flask pycryptodome
    ```

4.  **Test the API server:**
    ```bash
     flask --app api run --host=0.0.0.0
    ```
    The server should start on `http://0.0.0.0:5000`.

### Step 2: Setup Flutter Application

1.  **Clone the Flutter project:**
    ```bash
    git clone [your-flutter-project-repository]
    cd chatinng
    ```

2.  **Install Flutter dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Configure Firebase:**
    -   Create a new Firebase project at the [Firebase Console](https://console.firebase.google.com/).
    -   Enable **Authentication** (Email/Password provider).
    -   Enable **Firestore Database**.
    -   Download and add configuration files:
        -   `google-services.json` for Android (place in `android/app/`).
        -   `GoogleService-Info.plist` for iOS (place in `ios/Runner/`).
    -   Update `lib/firebase_options.dart` with your Firebase configuration.

4.  **Update API server IP address:**
    -   Find your computer's local IP address:
        -   Windows: `ipconfig`
        -   macOS/Linux: `ifconfig` or `ip addr show`
    -   Update the `serverIp` constant in your Dart files to match your computer's IP address.

### Step 3: Platform-Specific Setup

#### Android Setup

1.  **Update minimum SDK version** in `android/app/build.gradle`:
    ```groovy
    android {
        compileSdkVersion 34
        defaultConfig {
            minSdkVersion 21
            targetSdkVersion 34
        }
    }
    ```
2.  **Add internet permission** in `android/app/src/main/AndroidManifest.xml`:
    ```xml
    <uses-permission android:name="android.permission.INTERNET" />
    ```

#### iOS Setup

1.  **Update minimum iOS version** in `ios/Runner.xcodeproj/project.pbxproj`:
    ```
    IPHONEOS_DEPLOYMENT_TARGET = 12.0;
    ```
2.  **Add network permissions** in `ios/Runner/Info.plist`:
    ```xml
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
    ```

#### Desktop Setup (Optional)

For Windows, macOS, and Linux desktop support, ensure you have the appropriate development tools installed:
-   **Windows**: Visual Studio 2019 or later
-   **macOS**: Xcode 12 or later
-   **Linux**: GTK development libraries

---

## 🏃‍♂️ Running the Application

### Step 1: Start the Python API Server

Navigate to your `pyky` directory and run the server. Keep this terminal window open.
```bash
cd pyky
 flask --app api run --host=0.0.0.0
```

#### Step 2: Run the Flutter Application
Navigate to your chatinng directory and run the Flutter app.
```
Bash

cd chatinng
flutter run
```

#### Folder Structure
```
chatinng/
├── lib/
│   ├── main.dart               # App entry point
│   ├── firebase_options.dart   # Firebase configuration
│   └── loginpage/
│       ├── auth_gate.dart      # Authentication state management
│       ├── auth_services.dart  # Authentication methods
│       ├── chat_services.dart  # Message encryption/decryption
│       ├── kyber_key_service.dart # Kyber key management
│       ├── loginpage.dart      # Login UI
│       ├── chatpage.dart       # Chat interface
│       └── homepage.dart       # Main app screen
├── android/                    # Android-specific files
├── ios/                        # iOS-specific files
├── windows/                    # Windows-specific files
├── macos/                      # macOS-specific files
├── linux/                      # Linux-specific files
└── pubspec.yaml                # Flutter dependencies
```

#### Key Dependencies

```
firebase_core: ^2.31.0
cloud_firestore: ^4.17.3
firebase_auth: ^4.19.5
shared_preferences: ^2.2.2
http: ^1.1.0
encrypt: ^5.0.1
```
