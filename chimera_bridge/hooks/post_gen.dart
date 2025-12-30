import 'dart:io';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;

Future<void> run(HookContext context) async {
  final logger = context.logger;

  // The directory where the brick was generated (e.g. mobile_app_repo)
  final outputDir = Directory.current;

  // We assume the Flutter Project Root is the parent (for finding build artifacts)
  final flutterRootDir = outputDir.parent;

  logger.info('🧹 Running post-generation tasks in: ${outputDir.path}');

  // =======================================================================
  // 1. COPY ANDROID AARs (Host -> Output)
  // =======================================================================
  final aarSource = Directory(
      p.join(flutterRootDir.path, 'build', 'host', 'outputs', 'repo'));
  final aarDest = Directory(p.join(outputDir.path, 'android', 'libs'));

  if (aarSource.existsSync()) {
    final progress = logger.progress('📦 Copying Android AARs...');
    try {
      if (!aarDest.existsSync()) await aarDest.create(recursive: true);
      if (Platform.isWindows) {
        await Process.run(
            'xcopy', [aarSource.path, aarDest.path, '/E', '/I', '/Y', '/Q']);
      } else {
        await Process.run('cp', ['-R', '${aarSource.path}/.', aarDest.path]);
      }
      progress.complete('Copied Android AARs.');
    } catch (e) {
      progress.fail('Failed to copy AARs: $e');
    }
  } else {
    logger.warn('⚠️  Could not find Flutter AARs at: ${aarSource.path}');
  }

  // =======================================================================
  // 2. COPY iOS FRAMEWORKS (Host -> Output)
  // =======================================================================
  final frameworkSource = Directory(
      p.join(flutterRootDir.path, 'build', 'ios', 'framework', 'Release'));
  final frameworkDest = Directory(p.join(outputDir.path, 'ios', 'Frameworks'));

  if (frameworkSource.existsSync()) {
    final progress = logger.progress('📦 Copying iOS Frameworks...');
    try {
      if (!frameworkDest.existsSync())
        await frameworkDest.create(recursive: true);
      if (Platform.isWindows) {
        await Process.run('xcopy',
            [frameworkSource.path, frameworkDest.path, '/E', '/I', '/Y', '/Q']);
      } else {
        await Process.run(
            'cp', ['-R', '${frameworkSource.path}/.', frameworkDest.path]);
      }
      progress.complete('Copied iOS Frameworks.');
    } catch (e) {
      progress.fail('Failed to copy Frameworks: $e');
    }
  } else {
    logger
        .warn('⚠️  Could not find iOS Frameworks at: ${frameworkSource.path}');
  }

  // =======================================================================
  // 3. MOVE KOTLIN FILES TO PACKAGE FOLDER
  // =======================================================================
  // We generated files in 'android/src/main/java/', but they need to be in
  // 'android/src/main/java/com/example/coolapp/'

  final packageName = context.vars['package_name'] as String;
  final packagePath =
      packageName.replaceAll('.', p.separator); // e.g. com\example\coolapp

  final javaRoot =
      Directory(p.join(outputDir.path, 'android', 'src', 'main', 'java'));
  final packageDest = Directory(p.join(javaRoot.path, packagePath));

  if (javaRoot.existsSync()) {
    final progress =
        logger.progress('🚚 Moving Kotlin files to package folder...');
    try {
      if (!packageDest.existsSync()) await packageDest.create(recursive: true);

      // List all .kt files in the root java folder
      final files = javaRoot
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.kt'));

      for (var file in files) {
        final filename = p.basename(file.path);
        final destFile = File(p.join(packageDest.path, filename));
        await file.rename(destFile.path); // Move the file
      }
      progress.complete('Moved Kotlin files to: $packagePath');
    } catch (e) {
      progress.fail('Failed to move Kotlin files: $e');
    }
  }

  // =======================================================================
  // 4. CODE FORMATTING (In Place)
  // =======================================================================

  // --- TypeScript ---
  if (await _isExecutable('npx')) {
    try {
      await Process.run('npx', ['prettier', '--write', '**/*.{ts,tsx,js}'],
          workingDirectory: outputDir.path, runInShell: true);
      logger.info('   ✓ Formatted TypeScript');
    } catch (_) {}
  }

  // --- Swift ---
  if (await _isExecutable('swift-format')) {
    try {
      await Process.run(
          'swift-format', ['format', '--in-place', '--recursive', './ios'],
          workingDirectory: outputDir.path, runInShell: true);
      logger.info('   ✓ Formatted Swift');
    } catch (_) {}
  }

  // --- Kotlin ---
  if (await _isExecutable('ktlint')) {
    try {
      await Process.run('ktlint', ['-F', '**/*.kt'],
          workingDirectory: outputDir.path, runInShell: true);
      logger.info('   ✓ Formatted Kotlin');
    } catch (_) {}
  }

  // --- Dart ---
  // Now we format the Dart files residing INSIDE the output directory
  if (await _isExecutable('dart')) {
    try {
      await Process.run('dart', ['format', '.'],
          workingDirectory: outputDir.path, runInShell: true);
      logger.info('   ✓ Formatted Dart');
    } catch (_) {}
  }

  logger.success('✨ Generation Complete! Output at: ${outputDir.path}');
}

Future<bool> _isExecutable(String cmd) async {
  try {
    final result = await Process.run(
        Platform.isWindows ? 'where' : 'which', [cmd],
        runInShell: true);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}
