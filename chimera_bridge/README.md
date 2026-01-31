# 🦁 Chimera Bridge

**Run Flutter code inside React Native without requiring the Flutter SDK.**

Chimera Bridge is a **Mason Brick** that generates a "Headless" Flutter module wrapper. It scans your Flutter code to automatically generate:

1. **Native Modules:** Kotlin (Android) and Swift (iOS) bridges.
2. **TypeScript:** Typed interfaces for React Native.
3. **Dart API:** Abstract classes and MethodChannel setup for your Flutter app.

---

## 🚀 Features

* **Zero Flutter Dependency for Consumers:** The React Native app does *not* need the Flutter SDK installed.
* **Auto-Discovery:** Automatically finds your class if it matches the module name (no annotation needed!).
* **Annotation Support:** Use `@ReactBridge` to explicitly mark a class or override the module name.
* **Type-Safe:** Auto-generates TypeScript definitions (`.d.ts`) and Dart abstract interfaces.
* **Binary Distribution:** Automatically bundles compiled AARs (Android) and XCFrameworks (iOS).
* **Smart Formatting:** automatically formats generated code (Prettier, SwiftFormat, ktlint, Dart Format).

---

## 🛠️ Workflow for Module Creators

### 1. Prerequisites

* [Mason CLI](https://pub.dev/packages/mason_cli) (`dart pub global activate mason_cli`)
* Flutter SDK
* **Optional (for formatting):** `npx` (Node), `swift-format` (Homebrew), `ktlint`.

### 2. Create Your Spec

Inside your Flutter project, create a Dart file (e.g., `lib/specs/math_module.dart`) and define your interface.

**Option A: Auto-Discovery (Recommended)**
Name your class to match the `name` variable you will pass to Mason.
*Example:* `mason make ... --name MathModule` -> looks for `class MathModule`.

```dart
// lib/specs/math_module.dart
abstract class MathModule {
  Future<double> multiply(int a, int b);
}
```

**Option B: Explicit Annotation**
Use `@ReactBridge` if your class name differs or you want to be explicit.

```dart
// lib/specs/math_spec.dart
import 'package:chimera_annotations/chimera_annotations.dart'; 

@ReactBridge(name: "MathModule")
abstract class MyMathSpec {
  Future<double> multiply(int a, int b);
}
```

### 3. Build Flutter Artifacts

Before generating the bridge, you must build the Flutter binaries so they can be bundled.

```bash
# 1. Build Android AAR
flutter build aar

# 2. Build iOS Frameworks
flutter build ios-framework --output=build/ios/framework
```

### 4. Run the Generator

Run the Mason brick from your project root.

**Mac / Linux (Bash):**

```bash
mason make chimera_bridge \
  -o mobile_app_repo \
  --name MathModule \
  --package_name com.example.coolapp \
  --flutter_group_id com.example.my_flutter_project \
  --kotlin_version 1.9.0 \
  --compile_sdk 34 \
  --ios_platform 13.0
```

**Windows (PowerShell):**

```powershell
mason make chimera_bridge `
  -o mobile_app_repo `
  --name MathModule `
  --package_name com.example.coolapp `
  --flutter_group_id com.example.my_flutter_project `
  --kotlin_version 1.9.0 `
  --compile_sdk 34 `
  --ios_platform 13.0
```

### 5. Wire Up Flutter Logic

The generator creates a helper file in `mobile_app_repo/dart_api/`. Copy this folder to your Flutter project (or use the generated one directly if you set up a package path).

Simply initialize the bridge in your `main()` function.

```dart
// lib/main.dart
import 'dart_api/math_module_bridge.dart';

// 1. Implement the Logic
class MyMathLogic implements MathModuleImplementation {
  @override
  Future<double> multiply(int a, int b) async {
    return (a * b).toDouble();
  }
  
  @override
  Future<String> createUser(Map<String, dynamic> user) async {
    // Your business logic here...
    return "Success";
  }
  
  @override
  Future<void> syncItems(List<String> ids) async {
    print("Syncing ids: $ids");
  }
}

// 2. Initialize in main()
void main() {
  // This registers the MethodChannels so React Native can call them.
  MathModuleBridge.setup(MyMathLogic());
}
```

### 6. Package for Distribution

```bash
cd mobile_app_repo
npm pack
# This will generate a file like 'com-example-coolapp-1.0.0.tgz'
```

---

## 📱 For Module Consumers (React Native)

### 1. Installation

Install the tarball directly into your project.

```bash
npm install ./path/to/com-example-coolapp-1.0.0.tgz
```

### 2. Android Configuration (Crucial)

Open `android/build.gradle` (Root Level) in your React Native project.

```groovy
allprojects {
    repositories {
        google()
        mavenCentral()
        
        // 1. Required: Google Storage for Flutter Engine dependencies
        maven { url "[https://storage.googleapis.com/download.flutter.io](https://storage.googleapis.com/download.flutter.io)" }

        // 2. Required: Path to the local binaries inside your node_modules
        // NOTE: Use $rootDir to ensure the path is resolved correctly
        maven { 
            url "$rootDir/../node_modules/com.example.coolapp/android/libs" 
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

```typescript
import { multiply, createUser } from 'com.example.coolapp';

// Call methods directly
const result = await multiply(10, 5);
console.log(result); // 50

const status = await createUser({ name: "Karthik", role: "admin" });
```

---

## ⚠️ Troubleshooting

### 1. "Could not find com.generated..." (Android)

* **Error:** Gradle cannot resolve the Flutter dependencies.
* **Fix:** Ensure you added the `maven { url ... }` block pointing to `node_modules/.../android/libs` in your **Root** `build.gradle`, not the app's `build.gradle`.

### 2. "Unexpected token" in PowerShell

* **Error:** `Missing expression after unary operator '--'`
* **Cause:** You are using the bash line continuation character `\` in PowerShell.
* **Fix:** Use the backtick `` ` `` character for multi-line commands in PowerShell.

### 3. Formatting Skipped

* **Log:** `⚠️ Skipping Swift formatting (swift-format not found)`
* **Cause:** You don't have `swift-format` or `ktlint` installed.
* **Fix:** The generator will still work! The code just won't be pretty.
  * **Mac:** `brew install swift-format ktlint`
  * **Windows:** `scoop install ktlint` (Swift formatting is Mac-only).

### 4. "Map<String, dynamic>" appearing in Dart interface

* **Cause:** Mustache escaping.
* **Fix:** Ensure you used the updated template that uses `{{{triple_mustache}}}` for types to prevent HTML escaping.
