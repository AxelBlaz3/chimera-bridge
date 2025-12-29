import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;
// TODO: Ensure this matches your package name in pubspec.yaml
import 'package:bridge_generator/generator_core.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'input',
      abbr: 'i',
      help: 'Path to Dart contract',
      mandatory: true,
    )
    ..addOption('output', abbr: 'o', help: 'Output directory', mandatory: true)
    ..addOption(
      'name',
      abbr: 'n',
      help: 'Package Name',
      defaultsTo: 'my-bridge',
    );

  try {
    final results = parser.parse(arguments);
    final inputPath = results['input'];
    final outputPath = results['output'];
    final pkgName = results['name'];

    print("🚀 Analyzing contract...");
    final contractContent = File(inputPath).readAsStringSync();
    final methods = parseContract(contractContent);

    // Setup Directories
    final androidDir = Directory(
      p.join(outputPath, 'android/src/main/java/com/generated/bridge'),
    );
    final iosDir = Directory(p.join(outputPath, 'ios'));
    androidDir.createSync(recursive: true);
    iosDir.createSync(recursive: true);

    // Generate Code
    final generator = CodeGenerator(packageName: "com.generated.bridge");
    print("📝 Writing Native & JS Code...");

    File(
      p.join(androidDir.path, 'GeneratedModule.kt'),
    ).writeAsStringSync(generator.generateKotlin(methods));
    File(
      p.join(androidDir.path, 'GeneratedPackage.kt'),
    ).writeAsStringSync(generator.generateGeneratedPackage());
    File(
      p.join(outputPath, 'android/src/main/AndroidManifest.xml'),
    ).writeAsStringSync(generator.generateAndroidManifest());
    File(
      p.join(outputPath, 'android/build.gradle'),
    ).writeAsStringSync(generator.generateAndroidBuildGradle());

    File(
      p.join(iosDir.path, 'GeneratedModule.swift'),
    ).writeAsStringSync(generator.generateSwift(methods));
    File(
      p.join(outputPath, '$pkgName.podspec'),
    ).writeAsStringSync(generator.generatePodspec(pkgName));

    File(
      p.join(outputPath, 'index.js'),
    ).writeAsStringSync(generator.generateIndexJs(methods));
    File(
      p.join(outputPath, 'index.d.ts'),
    ).writeAsStringSync(generator.generateTypeDefs(methods));
    File(
      p.join(outputPath, 'package.json'),
    ).writeAsStringSync(generator.generatePackageJson(pkgName));

    // Flutter Module
    print("🔨 Scaffolding Flutter Module...");
    final flutterPath = p.join(outputPath, 'flutter_module');
    if (!Directory(flutterPath).existsSync()) {
      final result = await Process.run(
        'flutter',
        [
          'create', '-t', 'module',
          '--org', 'com.generated', // Ensure correct package structure for AAR
          'flutter_module',
        ],
        workingDirectory: outputPath,
        runInShell: true,
      );
      if (result.exitCode != 0) exit(1);
    }
    File(
      p.join(flutterPath, 'lib/main.dart'),
    ).writeAsStringSync(generator.generateFlutterMain(methods));

    // Build Binaries
    print("🏗️  Compiling Binaries...");
    print("   🤖 Building Android AARs...");
    final aarResult = await Process.run(
      'flutter',
      ['build', 'aar'],
      workingDirectory: flutterPath,
      runInShell: true,
    );
    if (aarResult.exitCode == 0) {
      await _copyDirectory(
        Directory(p.join(flutterPath, 'build/host/outputs/repo')),
        Directory(p.join(outputPath, 'android/libs')),
      );
    } else {
      print("❌ Android Build Failed: ${aarResult.stderr}");
    }

    if (Platform.isMacOS) {
      print("   🍎 Building iOS Frameworks...");
      await Process.run(
        'flutter',
        ['build', 'ios-framework', '--output=../ios/Frameworks'],
        workingDirectory: flutterPath,
        runInShell: true,
      );
    }

    print("\n✅ Success! Package created at: $outputPath");
    print(
      "   👉 Run 'npm pack' in that directory, then 'npm install' the tarball.",
    );
  } catch (e) {
    print('Error: $e');
  }
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  await destination.create(recursive: true);
  await for (final entity in source.list(recursive: false)) {
    if (entity is Directory) {
      var newDirectory = Directory(
        p.join(destination.absolute.path, p.basename(entity.path)),
      );
      await newDirectory.create();
      await _copyDirectory(entity.absolute, newDirectory);
    } else if (entity is File) {
      await entity.copy(p.join(destination.path, p.basename(entity.path)));
    }
  }
}
