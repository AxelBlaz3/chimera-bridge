import 'dart:io';
import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final logger = context.logger;
  final vars = context.vars;
  final name = vars['name'] as String;
  final packageName = vars['package_name'] as String;

  // 1. Update pubspec.yaml
  await _updatePubspec(logger, packageName);

  // 2. Calculate Paths
  final dartFile = 'lib/dart_api/${name.snakeCase}_bridge.dart';
  final packagePath = packageName.replaceAll('.', '/');
  final kotlinModule =
      'chimera/android/src/main/java/$packagePath/${name.pascalCase}Module.kt';
  final kotlinPackage =
      'chimera/android/src/main/java/$packagePath/${name.pascalCase}Package.kt';
  final swiftFile = 'chimera/ios/${name.pascalCase}.swift';
  final objcFile = 'chimera/ios/${name.pascalCase}.m';

  // 3. Format Code (Dart, Kotlin, Swift, ObjC)
  await _formatFile(logger, 'dart', ['format'], dartFile);

  await _runFormatterIfExists(
    logger,
    executable: 'ktlint',
    args: ['-F'],
    files: [kotlinModule, kotlinPackage],
    installHint:
        'brew install ktlint (Mac) or curl -sSLO https://github.com/pinterest/ktlint/releases/latest/download/ktlint && chmod a+x ktlint (Linux/Windows)',
  );

  await _runFormatterIfExists(
    logger,
    executable: 'swift-format',
    args: ['-i'],
    files: [swiftFile],
    installHint: 'brew install swift-format (Mac)',
  );

  await _runFormatterIfExists(
    logger,
    executable: 'clang-format',
    args: ['-i'],
    files: [objcFile],
    installHint:
        'brew install clang-format (Mac) or apt install clang-format (Linux)',
  );

  // 4. Success Message with Host Instructions
  // Note: We use \${} to escape the dollar sign for Gradle variables in the printout
  logger.success('''
  🦁 Chimera Bridge Created: $name
  
  NEXT STEPS:
  =========================================================
  
  1. IMPLEMENT FLUTTER LOGIC:
     File: lib/main.dart
     -----------------------------------------------------
     import 'package:$packageName/dart_api/${name.snakeCase}_bridge.dart';
     
     void main() {
       WidgetsFlutterBinding.ensureInitialized();
       ${name}Bridge.setup(MyImplementation());
     }
  
  2. BUILD BINARIES:
     -----------------------------------------------------
     dart run scripts/build_android.dart
     dart run scripts/build_ios.dart
     
  3. INSTALL IN REACT NATIVE:
     -----------------------------------------------------
     cd chimera
     npm pack
     # In your RN app:
     npm install ../path/to/chimera/${name.snakeCase}-1.0.0.tgz

  4. CONFIGURE HOST (ANDROID):
     File: android/build.gradle (Root)
     -----------------------------------------------------
     allprojects {
       repositories {
         // ...
         maven { url("\$rootDir/../node_modules/${name.snakeCase}/android/libs") }
         maven { url("https://storage.googleapis.com/download.flutter.io") }
       }
     }

  5. REGISTER PACKAGE (MainApplication.kt):
     (Only if autolinking fails)
     -----------------------------------------------------
     import $packageName.${name.pascalCase}Package

     // In getPackages():
     add(${name.pascalCase}Package())

  =========================================================
  ''');
}

/// Helper to check for binary existence and run formatting
Future<void> _runFormatterIfExists(
  Logger logger, {
  required String executable,
  required List<String> args,
  required List<String> files,
  required String installHint,
}) async {
  if (files.isEmpty || files.every((f) => !File(f).existsSync())) return;

  if (await _isBinaryAvailable(executable)) {
    await _formatFile(logger, executable, args, files.join(' '));
  } else {
    logger.detail(
        '⚠️  Skipping $executable (not found). Install via: $installHint');
  }
}

/// Helper to actually run the process
Future<void> _formatFile(
    Logger logger, String exe, List<String> args, String filePaths) async {
  try {
    // Split file paths into individual arguments if multiple are passed
    final finalArgs = [...args, ...filePaths.split(' ')];
    final result = await Process.run(exe, finalArgs);

    if (result.exitCode == 0) {
      logger.detail('✅ Formatted with $exe: $filePaths');
    } else {
      logger.detail('Failed to format with $exe: ${result.stderr}');
    }
  } catch (e) {
    logger.warn('Error running $exe: $e');
  }
}

/// Cross-platform check for binary existence
Future<bool> _isBinaryAvailable(String executable) async {
  if (Platform.isWindows) {
    final result = await Process.run('where', [executable]);
    return result.exitCode == 0;
  } else {
    final result = await Process.run('which', [executable]);
    return result.exitCode == 0;
  }
}

/// Helper: Patch the existing pubspec.yaml
Future<void> _updatePubspec(Logger logger, String packageName) async {
  final pubspecFile = File('pubspec.yaml');

  if (!pubspecFile.existsSync()) {
    logger.warn('⚠️ pubspec.yaml not found. Skipping package name update.');
    return;
  }

  try {
    var content = await pubspecFile.readAsString();

    // 1. Regex for androidPackage
    // ^ = Start of line
    // \s* = Any indentation
    // (.*)$ = Capture the rest of the line to replace it
    final androidRegex =
        RegExp(r'^(\s*androidPackage:\s+)(.*)$', multiLine: true);
    if (androidRegex.hasMatch(content)) {
      content = content.replaceAllMapped(androidRegex, (match) {
        // match.group(1) preserves the indentation and key (e.g. "  androidPackage: ")
        return '${match.group(1)}$packageName';
      });
    }

    // 2. Regex for iosBundleIdentifier
    final iosRegex =
        RegExp(r'^(\s*iosBundleIdentifier:\s+)(.*)$', multiLine: true);
    if (iosRegex.hasMatch(content)) {
      content = content.replaceAllMapped(iosRegex, (match) {
        return '${match.group(1)}$packageName';
      });
    }

    await pubspecFile.writeAsString(content);
    logger.detail('✅ Synced pubspec.yaml identifiers to $packageName');
  } catch (e) {
    logger.warn('Could not update pubspec.yaml: $e');
  }
}
