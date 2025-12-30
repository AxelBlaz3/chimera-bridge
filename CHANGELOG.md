# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-30

### Added

- **Core Generator:** Mason brick to parse Dart contracts (`@ReactBridge`) and generate native bridge code.
- **Bi-directional Communication:**
  - Call Dart methods from JavaScript using standard Promises.
  - Type-safe argument passing for Maps, Lists, and Primitives.

- **Android Support (Kotlin):**
  - **Thread Safety:** Automatic Main Thread dispatch (`Handler(Looper.getMainLooper())`) for Flutter Engine initialization and MethodChannel calls to prevent `@UiThread` crashes.
  - **Autolinking:** Generates `AndroidManifest.xml` and `ReactPackage` classes for seamless integration with React Native.
  - **Namespace Support:** Compatible with Android Gradle Plugin (AGP) 8.0+ via explicit namespace generation.
  - **Smart File Placement:** Post-generation hooks automatically move Kotlin files to the correct package directory (e.g., `com/example/app`).

- **iOS Support (Swift/Obj-C):**
  - Auto-generation of `GeneratedModule.swift` and `GeneratedModule.m`.
  - Lazy initialization of the Flutter Engine to ensure non-blocking app startup.
  - `Podspec` generation for easy integration via CocoaPods.

- **TypeScript & Developer Experience:**
  - **Hybrid Exports:** Generates `index.ts` barrel files supporting both Named imports (`import { multiply } ...`) and Default imports (`import MathModule ...`).
  - **Strict Typing:** mapping of Dart types to TypeScript (e.g., `int/double` → `number`, `Map` → `object`).
  - **Barrel Pattern:** automatic `package.json` configuration to point `main`, `types`, and `react-native` fields to the generated source.

- **Dart Bridge:**
  - **Robust Type Casting:** Custom `_cast<T>` helper to safely handle JavaScript's `double` numbers when Dart expects `int`.
  - **Void Handling:** Support for void methods returning `null` to JavaScript.
  - `BridgeService` scaffold for clean implementation of business logic.

### Fixed

- **N/A** (Initial Release)
