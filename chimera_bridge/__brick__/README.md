# Chimera Bridge Templates 🧱

This directory contains the Mustache templates that are rendered into the final Chimera Bridge code.

## 📂 Output Structure

When the brick is run, it overlays the following structure onto the user's Flutter module.

```
.
├── chimera/                  <-- The React Native Package
│   ├── package.json          <-- npm package definition
│   ├── android/              <-- Android Native Module (Kotlin)
│   ├── ios/                  <-- iOS Native Module (Swift/ObjC)
│   └── src/                  <-- TypeScript Definitions
│
├── lib/
│   └── dart_api/             <-- Dart Abstract Interface & Bridge
│
└── scripts/                  <-- Build Helpers
    ├── build_android.dart    <-- Compiles Flutter AAR
    └── build_ios.dart        <-- Compiles iOS Frameworks
```

## 🧠 Key Templates

### 1. Dart Bridge (`lib/dart_api/`)
*   **File:** `{{name.snakeCase()}}_bridge.dart`
*   **Purpose:** Defines the abstract class the user must implement and handles the `MethodChannel` logic (including Stream subscriptions).

### 2. Android Module (`chimera/android/`)
*   **File:** `{{name.pascalCase()}}Module.kt`
*   **Purpose:** The Kotlin implementation of a React Native module. It launches the Flutter Engine (cached) and forwards calls via MethodChannels.

### 3. iOS Module (`chimera/ios/`)
*   **File:** `{{name.pascalCase()}}.swift`
*   **Purpose:** The Swift implementation using `RCTBridgeModule`. It handles the `FlutterEngine` lifecycle and method delegation.

### 4. TypeScript (`chimera/src/`)
*   **File:** `{{name.pascalCase()}}.ts`
*   **Purpose:** Provides a type-safe wrapper around the Native Module, converting `NativeModules` calls into typed Promises and Observables.
