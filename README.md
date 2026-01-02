# Chimera Bridge 🦁🐍🐐

**Seamlessly bridge Flutter logic into React Native apps.**

Chimera Bridge is a **Mason Brick** that generates a fully-functional React Native library from a Dart specification. It automates the "glue code" between TypeScript, Kotlin (Android), Swift (iOS), and the Flutter Engine.

---

## 🚀 Features

- **Polyglot Generation:** Automated Kotlin, Swift, TypeScript, and Dart generation.
- **Isolated Architecture:** Generates a standalone React Native package inside your Flutter module, preventing build conflicts.
- **Type Safety:** Intelligent mapping of Dart types to Native/TS equivalents.
- **Bi-Directional Communication:** Support for Promises (Futures) and Events (Streams).
- **Local Binary Strategy:** Optimized for consuming Flutter AARs and XCFrameworks directly from your library folder.

---

## 🚦 Project Status

| Platform | Status | Notes |
| :--- | :--- | :--- |
| **Android** | ✅ Stable | Fully tested with local AARs and AGP 8.0+. |
| **TypeScript** | ✅ Stable | Type definitions and Promise/Observable wrappers are verified. |
| **iOS** | 🚧 Beta | Scaffolded and currently being verified on device by the maintainer. |

## 🗺️ Roadmap

- [ ] 🍏 **iOS Verification:** Validate `RCTEventEmitter` and Swift selector mapping.
- [ ] 📦 **Distribution:** Publish brick to BrickHub.
- [ ] 🧪 **Testing:** Add unit tests for the Mason `pre_gen.dart` logic.
- [ ] 📝 **Docs:** Add examples for complex nested types (e.g., `List<Map<String, int>>`).

---

## 🛠️ Installation & Setup

### 1. Create a Flutter Module

Chimera runs inside a standard Flutter module. Create one using the CLI:

```bash
flutter create -t module math_module
cd math_module
```

### 2. Define the Spec

Create a file inside your new module (e.g., `lib/specs/math.dart`) to define your interface using the `@ReactBridge` annotation.

*Note: You may need to create a simple annotation class if you haven't installed the annotation package yet.*

```dart
// lib/specs/math.dart
@ReactBridge(name: "MathUtils")
abstract class MathSpec {
  Future<double> multiply(double a, double b);
  Stream<int> countStream();
}
```

### 3. Run the Generator

Run mason **inside the module directory**. This will generate the bridge artifacts (`chimera/`, `scripts/`, `lib/dart_api/`) and overlay them onto your project.

```bash
mason make chimera_bridge \
  --name MathUtils \
  --package_name com.example.mathutils \
  --agp_version 8.1.0 \
  --kotlin_version 1.8.10
```

### 4. Implement Flutter Logic

Wire up the generated bridge in your `lib/main.dart`.

```dart
import 'package:flutter/material.dart';
// Import the generated bridge
import 'package:math_module/dart_api/math_utils_bridge.dart'; 

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Connect the bridge implementation
  MathUtilsBridge.setup(MathUtilsImplementation());
}

class MathUtilsImplementation extends MathUtilsImplementation {
  @override
  Future<double> multiply(double a, double b) async => a * b;

  @override
  Stream<int> countStream() async* {
    yield* Stream.periodic(Duration(seconds: 1), (i) => i);
  }
}
```

### 5. Build Binaries

Use the generated Dart scripts to compile the Flutter code into native binaries. These scripts automatically move the artifacts into the `chimera` package folder.

```bash
# Android (Windows/Mac/Linux)
dart run scripts/build_android.dart

# iOS (Mac only)
dart run scripts/build_ios.dart
```

### 6. Pack and Install

The React Native package lives in the `chimera` subdirectory. Pack it and install it in your host app.

```bash
# 1. Enter the package directory
cd chimera

# 2. Create a tarball (.tgz)
npm pack

# 3. Go to your React Native root project
cd ../../my-react-native-app

# 4. Install the tarball
npm install ../math_module/chimera/math_utils-1.0.0.tgz
```

---

## 🤖 Android Configuration (Host App)

To support the local Flutter AARs without moving files into your host project, update `android/build.gradle` in your **React Native host project**:

```gradle
allprojects {
    repositories {
        google()
        mavenCentral()

        // 1. Point to the local AARs inside the node_modules bridge directory
        maven {
            url = uri("$rootDir/../node_modules/math_utils/android/libs/")
        }

        // 2. Add the Flutter engine repository
        maven {
            url = uri("[https://storage.googleapis.com/download.flutter.io](https://storage.googleapis.com/download.flutter.io)")
        }
    }
}
```

---

## 🍏 iOS Configuration (Host App)

Since the `build_ios.dart` script places the frameworks correctly inside the package, you only need to run Pod install.

```bash
cd ios
npx pod-install
```

---

## 💻 React Native Usage

```typescript
import MathUtils from 'math_utils';

// 1. Methods (Promises)
const result = await MathUtils.multiply(10, 5);

// 2. Streams (Events)
useEffect(() => {
  const subscription = MathUtils.onCountStream((count) => {
    console.log("Flutter says:", count);
  });

  return () => subscription.remove();
}, []);
```

---

## ⚙️ Generator Arguments (vars)

| Variable | Description | Default |
| :--- | :--- | :--- |
| `name` | Native Module Name | `MyModule` |
| `package_name` | Android Package (e.g. `com.myapp`) | `com.myapp` |
| `agp_version` | Android Gradle Plugin Version | `7.4.2` |
| `kotlin_version` | Kotlin Version | `1.8.0` |

---

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

### How to contribute

1. **Fork the Project**
2. **Create your Feature Branch** (`git checkout -b feature/AmazingFeature`)
3. **Commit your Changes** (`git commit -m 'Add some AmazingFeature'`)
4. **Push to the Branch** (`git checkout push origin feature/AmazingFeature`)
5. **Open a Pull Request**

### Development Note

This project uses **Mason**. When contributing:

- Native templates are located in `__brick__/chimera`.
- Generation logic and type-mapping are located in `hooks/pre_gen.dart`.
- Post-generation cleanup is located in `hooks/post_gen.dart`.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

## 💡 Troubleshooting

### `MissingPluginException`

This usually means `MathUtilsBridge.setup()` was not called in your Flutter `main.dart`, or the `setup` call happened before `WidgetsFlutterBinding.ensureInitialized()`.

### `Unresolved reference: reactContext` (Android)

The bridge uses `private val reactContext` in the constructor. Ensure your native templates are synced.

### Build Failures with `android/` folder

Ensure you are using the `chimera` subdirectory structure. If you have a stray `android/` folder in your root (outside of `chimera/`), Flutter will mistake your module for a full Android app and fail the build.
