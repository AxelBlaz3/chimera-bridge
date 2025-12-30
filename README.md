# Chimera Bridge 🦁🐍🐐

**Seamlessly bridge Flutter logic into React Native apps.**

Chimera Bridge is a **Mason Brick** that generates a fully-functional React Native library from a Dart specification. It automates the "glue code" between TypeScript, Kotlin (Android), Swift (iOS), and the Flutter Engine.

---

## 🚀 Features

- **Polyglot Generation:** Automated Kotlin, Swift, TypeScript, and Dart generation.
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

## 🛠️ Installation & Setup

### 1. The Dart Specification

Define your interface in `lib/specs/` using the `@ReactBridge` annotation.

```dart
@ReactBridge(name: "MathModule")
abstract class MathSpec {
  Future<double> multiply(double a, double b);
  Stream<int> countStream();
}
```

### 2. Run the Generator

Run mason with your project-specific configurations:

```bash
mason make chimera_bridge \
  --name MathModule \
  --package_name com.example.app \
  --agp_version 8.1.0 \
  --kotlin_version 1.8.10
```

### 3. Pack and Install the Module

To ensure a clean installation that mimics a production environment, pack the generated module into a tarball and install it:

```bash
# 1. Go to the generated module directory
cd math-module

# 2. Create a tarball (.tgz)
npm pack

# 3. Go to your React Native root project
cd ../my-react-native-app

# 4. Install the tarball
npm install ../path/to/math-module-1.0.0.tgz
```

---

## 🤖 Android Configuration

To support the local Flutter AARs without moving files into your host project, update `android/build.gradle` in your **React Native host project**:

```gradle
allprojects {
    repositories {
        google()
        mavenCentral()

        // 1. Point to the local AARs inside the node_modules bridge directory
        maven {
            url = uri("$rootDir/../node_modules/math-module/android/libs/")
        }

        // 2. Add the Flutter engine repository
        maven {
            url = uri("[https://storage.googleapis.com/download.flutter.io](https://storage.googleapis.com/download.flutter.io)")
        }
    }
}
```

---

## 🍏 iOS Configuration

#### A. Framework Placement

Run `flutter build ios-framework` and place the generated `.xcframework` files into the `ios/` directory of the generated module (e.g., `math-module/ios/`) **before** running `npm pack`.

#### B. Pod Installation

```bash
cd ios
npx pod-install
```

---

## 🏗️ Flutter Implementation

Initialize the bridge in your Flutter `main.dart`. Chimera runs "headless," so `runApp` is typically not required.

```dart
import 'package:flutter/material.dart';
import 'chimera_bridge/dart_api/math_module_bridge.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MathModuleBridge.setup(MathModuleImplementation());
}

class MathModuleImplementation extends MathModuleImplementation {
  @override
  Future<double> multiply(double a, double b) async => a * b;

  @override
  Stream<int> countStream() async* {
    yield* Stream.periodic(Duration(seconds: 1), (i) => i);
  }
}
```

---

## 💻 React Native Usage

```typescript
import MathModule from 'math-module';

// 1. Methods (Promises)
const result = await MathModule.multiply(10, 5);

// 2. Streams (Events)
useEffect(() => {
  const subscription = MathModule.onCountStream((count) => {
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
| `flutter_group_id` | Group ID for AAR lookup | `com.example.flutter_module` |

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

- Native templates are located in `__brick__`.
- Generation logic and type-mapping are located in `hooks/pre_gen.dart`.
- Post-generation cleanup is located in `hooks/post_gen.dart`.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

## 💡 Troubleshooting

### `MissingPluginException`

This usually means `MathModuleBridge.setup()` was not called in your Flutter `main.dart`.

### `Unresolved reference: reactContext` (Android)

The bridge uses `private val reactContext` in the constructor. Ensure your native templates are synced.

### White-space in generated code

The bridge logic separates `streams` and `futures` in the `pre_gen` hook to ensure clean Mustache rendering.
