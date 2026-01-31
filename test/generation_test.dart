import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

void main() {
  group('Golden Generation Test', () {
    late Directory tempDir;
    late Directory projectRoot;

    setUp(() {
      projectRoot = Directory.current;
      tempDir = Directory.systemTemp.createTempSync('chimera_golden_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('Generates matching artifacts for AllTypes spec', () async {
      // 1. Setup Temp Project
      final libDir = Directory(path.join(tempDir.path, 'lib'))..createSync();

      // Copy Spec
      File(path.join(projectRoot.path, 'test/fixtures/spec/all_types.dart'))
          .copySync(path.join(libDir.path, 'all_types.dart'));

      // Create mason.yaml pointing to local brick

      File(path.join(tempDir.path, 'mason.yaml')).writeAsStringSync('''

      bricks:

        chimera_bridge:

          path: ${projectRoot.path}/chimera_bridge

      ''');

      // Create minimal pubspec.yaml for mason_cli

      File(path.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''

      name: temp_test

      environment:

        sdk: '>=3.0.0 <4.0.0'

      dev_dependencies:

        mason_cli: ^0.1.0

      ''');

      // Create config.json to avoid interactive prompts

      File(path.join(tempDir.path, 'config.json')).writeAsStringSync('''

      

            {

      

              "name": "AllTypes",

      

              "package_name": "com.example.alltypes",

      

              "kotlin_version": "1.8.0",

      

              "agp_version": "7.4.2",

      

              "compile_sdk": "33",

      

              "min_sdk": "21",

      

              "ios_platform": "11.0"

      

            }

      

            ''');

      final dartDir = path.dirname(Platform.executable);

      final env = {
        'PATH': '$dartDir:${Platform.environment['PATH'] ?? ''}',
      };

      // 1.5 Run Pub Get

      final pubGetResult = await Process.run(
        Platform.executable,
        ['pub', 'get'],
        workingDirectory: tempDir.path,
        environment: env,
      );

      expect(pubGetResult.exitCode, 0,
          reason: 'pub get failed: ${pubGetResult.stderr}');

      // 2. Run Mason Get

      final getResult = await Process.run(
        Platform.executable,
        ['run', 'mason_cli:mason', 'get'],
        workingDirectory: tempDir.path,
        environment: env,
      );

      expect(getResult.exitCode, 0,
          reason: 'mason get failed: ${getResult.stderr}');

      // 3. Run Mason Make

      final makeResult = await Process.run(
        Platform.executable,
        [
          'run',
          'mason_cli:mason',
          'make',
          'chimera_bridge',
          '-c',
          'config.json',
          '--on-conflict',
          'overwrite'
        ],
        workingDirectory: tempDir.path,
        environment: env,
      );

      if (makeResult.exitCode != 0) {
        print('Mason Make Stdout: ${makeResult.stdout}');
        print('Mason Make Stderr: ${makeResult.stderr}');
      }
      expect(makeResult.exitCode, 0, reason: 'mason make failed');

      // 4. Compare with Goldens
      final goldenDir =
          Directory(path.join(projectRoot.path, 'test/fixtures/goldens'));

      final filesToVerify = {
        'lib/dart_api/all_types_bridge.dart': 'all_types_bridge.dart',
        'chimera/src/AllTypes.ts': 'AllTypes.ts',
        'chimera/android/src/main/java/AllTypesModule.kt': 'AllTypesModule.kt',
        'chimera/ios/AllTypes.swift': 'AllTypes.swift',
      };

      for (var entry in filesToVerify.entries) {
        final generatedPath = path.join(tempDir.path, entry.key);
        final goldenPath = path.join(goldenDir.path, entry.value);

        final generatedFile = File(generatedPath);
        final goldenFile = File(goldenPath);

        expect(generatedFile.existsSync(), isTrue,
            reason: 'Generated file missing: ${entry.key}');

        final generatedContent = generatedFile.readAsStringSync().trim();
        final goldenContent = goldenFile.readAsStringSync().trim();

        // Normalize line endings for cross-platform stability
        final normalizedGen = generatedContent.replaceAll('\r\n', '\n');
        final normalizedGold = goldenContent.replaceAll('\r\n', '\n');

        expect(normalizedGen, equals(normalizedGold),
            reason: 'Content mismatch in ${entry.key}');
      }
    });
  });
}
