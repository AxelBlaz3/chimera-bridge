import 'dart:io';
import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final logger = context.logger;
  final vars = context.vars;
  final name = vars['name'] as String;
  final packageName = vars['package_name'] as String;

  // Update pubspec.yaml (NEW STEP)
  // This ensures the Flutter module's internal package name matches the bridge.
  await _updatePubspec(logger, packageName);

  // 1. Calculate Paths to Generated Files
  // We only want to format what we created, not the whole project.
  final dartFile = 'lib/dart_api/${name.snakeCase}_bridge.dart';

  // Convert package dots to path slashes (e.g. com.example -> com/example)
  final packagePath = packageName.replaceAll('.', '/');
  final kotlinModule =
      'chimera/android/src/main/java/$packagePath/${name.pascalCase}Module.kt';
  final kotlinPackage =
      'chimera/android/src/main/java/$packagePath/${name.pascalCase}Package.kt';

  final swiftFile = 'chimera/ios/${name.pascalCase}.swift';
  final objcFile = 'chimera/ios/${name.pascalCase}.m';

  // 2. Format Dart (Built-in, safe to run)
  await _formatFile(logger, 'dart', ['format'], dartFile);

  // 3. Format Kotlin (ktlint)
  await _runFormatterIfExists(
    logger,
    executable: 'ktlint',
    args: ['-F'], // -F flag usually means "Format" in ktlint CLI
    files: [kotlinModule, kotlinPackage],
    installHint:
        'brew install ktlint (Mac) or curl -sSLO https://github.com/pinterest/ktlint/releases/latest/download/ktlint && chmod a+x ktlint (Linux/Windows)',
  );

  // 4. Format Swift (swift-format)
  await _runFormatterIfExists(
    logger,
    executable: 'swift-format',
    args: ['-i'], // -i for in-place
    files: [swiftFile],
    installHint: 'brew install swift-format (Mac)',
  );

  // 5. Format ObjC (clang-format)
  await _runFormatterIfExists(
    logger,
    executable: 'clang-format',
    args: ['-i'], // -i for in-place
    files: [objcFile],
    installHint:
        'brew install clang-format (Mac) or apt install clang-format (Linux)',
  );

  // 6. Make scripts executable
  if (!Platform.isWindows) {
    try {
      final scripts = ['scripts/build_android.sh', 'scripts/build_ios.sh'];
      for (final script in scripts) {
        if (File(script).existsSync()) {
          await Process.run('chmod', ['+x', script]);
        }
      }
      logger.detail('✅ Made build scripts executable');
    } catch (e) {
      logger.warn('Could not set script permissions: $e');
    }
  }

  // 7. Success Message
  logger.success('''
  🦁 Chimera Bridge Created: $name
  
  NEXT STEPS:
  ---------------------------------------------------------
  1. Implement logic:  lib/main.dart
     -> import 'package:$packageName/dart_api/${name.snakeCase}_bridge.dart';
     -> call ${name}Bridge.setup(...)
  
  2. Build Binaries:
     -> ./scripts/build_android.sh
     -> ./scripts/build_ios.sh
     
  3. Install in React Native:
     -> npm install ./path/to/${name.snakeCase}-1.0.0.tgz
  ---------------------------------------------------------
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
