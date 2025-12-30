# Chimera Bridge 🦁🐍🐐

**Seamlessly bridge Flutter logic into React Native apps.**

Chimera Bridge is a **Mason Brick** that generates the glue code required to run a Flutter module inside a React Native application. It automates the creation of MethodChannels, EventChannels, and Native Modules for Android (Kotlin), iOS (Swift), and TypeScript.

---

## 🚀 Features

- **Polyglot Generation:** Generates Kotlin, Swift, TypeScript, and Dart code from one source.
- **Type Safety:** Maps Dart types (`int`, `Map`, `List`) to Native equivalents (`Double/NSNumber`, `ReadableMap`, etc.).
- **Bi-Directional Communication:** Support for standard Promises and real-time Streams.
- **Local Binary Support:** Pre-configured for local `.aar` and `.xcframework` consumption.

---

## 🛠️ Installation

1. **Add the Brick**:

   ```bash
   mason add chimera_bridge --path ./chimera_bridge
   ```

2. **Add Dependencies** to `pubspec.yaml`:

   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     chimera_bridge:
       path: ./lib/
   ```

---

## 📖 Usage Guide

### 1. Define Your Contract

Annotate a class in `lib/specs/` with `@ReactBridge`.

```dart
@ReactBridge(name: "MathModule")
abstract class MathSpec {
  Future<double> multiply(double a, double b);
  Stream<int> countStream();
}
```

### 2. Generate the Bridge

Run the generator with your project-specific configurations.

```bash
mason make chimera_bridge \
  --name MathModule \
  --package_name com.example.coolapp \
  --agp_version 8.1.0 \
  --kotlin_version 1.8.10 \
  --flutter_group_id com.example.my_flutter_logic
```

#### Available Arguments (`vars`)

| Variable | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `name` | string | `MyModule` | Name of the Native Module |
| `package_name` | string | `com.myapp` | Android Package Name |
| `agp_version` | string | `7.4.2` | Android Gradle Plugin Version |
| `kotlin_version` | string | `1.8.0` | Kotlin Version |
| `compile_sdk` | string | `33` | Android Compile SDK |
| `min_sdk` | string | `21` | Android Min SDK |
| `ios_platform` | string | `11.0` | Minimum iOS version |
| `flutter_group_id` | string | `com.example.flutter_module` | Group ID used for Flutter AARs |

### 3. Implement Flutter Logic

Open `lib/main.dart` and initialize the bridge.

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
    for (int i = 0; i < 100; i++) {
      await Future.delayed(Duration(seconds: 1));
      yield i;
    }
  }
}
```

### 4. Binary Infrastructure

The brick configures native builds to consume local artifacts:

- **Android:** The `build.gradle` uses `namespace` (for AGP 8.0+) and looks for AARs in `android/libs` matching your `flutter_group_id`.
- **iOS:** The `.podspec` vends `Flutter.xcframework` and `App.xcframework` from the local `ios/` directory.

### 5. Consume in React Native

```typescript
import MathModule from 'math-module';

// Promise
const result = await MathModule.multiply(10, 5);

// Stream
const sub = MathModule.onCountStream(num => console.log(num));

// Cleanup (Important!)
sub.remove();
```

---
