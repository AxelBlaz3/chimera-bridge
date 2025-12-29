# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-28

### Added

- **Core Generator:** CLI tool to parse Dart contracts and generate native bridge code.
- **Bi-directional Communication:**
  - Support for calling Dart methods from JavaScript (`GeneratedModule.methodName()`).
  - Support for streaming events from Dart to JavaScript (`Bridge.emit()`).
- **Android Support:**
  - Auto-generation of `GeneratedPackage.kt` and `GeneratedModule.kt`.
  - Automatic `HashMap` and `ArrayList` conversion to React Native types.
  - Support for Flutter `profile` build mode to prevent Gradle sync crashes.
  - Local Maven repository setup for offline AAR consumption.
- **iOS Support:**
  - Auto-generation of `GeneratedModule.swift` using `RCTEventEmitter`.
  - Lazy initialization of the Flutter Engine to ensure non-blocking startup.
  - `Podspec` generation for easy integration via CocoaPods.
- **Type Safety:**
  - Automatic generation of TypeScript definitions (`index.d.ts`) based on the Dart contract.
- **Developer Experience:**
  - `BridgeService` class scaffolded in Flutter for clean logic implementation.
  - Comprehensive `README.md` with integration steps and troubleshooting.

### Fixed

- N/A (Initial Release)
