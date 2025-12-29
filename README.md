# 🦁 Chimera Bridge

**Run Flutter code inside React Native without requiring the Flutter SDK.**

This tool generates a "Headless" Flutter module wrapper that allows you to define methods in Dart, compile them into native binaries (`.aar` for Android, `.xcframework` for iOS), and call them directly from JavaScript/TypeScript in a React Native app.

---

## 🚀 Features

* **Zero Flutter Dependency for Consumers:** The React Native app does *not* need the Flutter SDK installed.
* **Bi-directional Communication:** Call methods (JS->Dart) and Stream events (Dart->JS).
* **Binary Distribution:** Ships compiled AARs and XCFrameworks.
* **Type-Safe:** Auto-generates TypeScript definitions (`.d.ts`).
* **Offline Ready:** The bridge bundles the Flutter engine locally.

---

## 🛠️ For Module Creators (How to Build a Bridge)

### 1. Prerequisites

* Dart SDK (to run the generator)
* Flutter SDK (to compile the binaries)
* Node.js / NPM

### 2. Define Your Contract

Create a Dart file (e.g., `contract.dart`).

```dart
// contract.dart
abstract class BridgeContract {
  dynamic authenticate(String userName, String token);
  bool isDeviceSupported();
  Map<String, dynamic> getUserProfile(int userId);
}
```

### 3. Run the Generator

```bash
dart run bin/bridge_generator.dart \
  --input contract.dart \
  --output dist/my-bridge \
  --name my-bridge
```

### 4. Implement Your Logic

Open `dist/my-bridge/flutter_module/lib/main.dart`. The generator now provides a class named `BridgeService`.

```dart
// lib/main.dart
class BridgeService {
  dynamic authenticate(String userName, String token) {
    print("Authenticating $userName...");
    
    // Send an event back to JS
    Bridge.emit("auth_status", {"step": "verifying", "percent": 50});
    
    return {"status": "success", "token": "jwt-123"};
  }
}
```

### 5. Compile & Pack

Whenever you change Dart code:

```bash
# 1. Rebuild Android AARs
cd dist/my-bridge/flutter_module
flutter build aar

# 2. Rebuild iOS Frameworks (Mac only)
flutter build ios-framework --output=../ios/Frameworks

# 3. Pack for NPM
cd .. 
npm pack
```

---

## 📱 For Module Consumers (The React Native Dev)

### 1. Installation

```bash
npm install ./path/to/my-bridge-1.0.0.tgz
```

### 2. Android Configuration (Crucial Step)

Open `android/build.gradle` (Root Level) and add the repository paths using `$rootDir`.

```groovy
allprojects {
    repositories {
        google()
        mavenCentral()
        
        // 1. Required: Google Storage for Flutter Engine dependencies
        maven { url "https://storage.googleapis.com/download.flutter.io" }

        // 2. Required: Path to the local binaries inside your node_modules
        maven { 
            url "$rootDir/../node_modules/my-bridge/android/libs" 
        }
    }
}
```

### 3. iOS Configuration

```bash
cd ios
pod install
```

### 4. Usage

Import the module.

```typescript
import GeneratedModule from 'my-bridge';

// 1. Listen for Events
GeneratedModule.addListener("auth_status", (data) => {
  console.log("Progress:", data.percent);
});

// 2. Call Methods
const response = await GeneratedModule.authenticate("user1", "token123");
```

---

## ⚠️ Troubleshooting

* **Android Build Fail:** Ensure you use `$rootDir` in `android/build.gradle`.
* **"Profile" Build Type Error:** The generator handles this automatically. If manually editing, ensure `buildTypes { profile { initWith release } }` exists.
* **iOS "NO_ENGINE":** The bridge initializes lazily. On the very first call, there might be a split-second delay.
