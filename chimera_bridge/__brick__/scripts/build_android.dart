import 'dart:io';

void main() async {
  // 1. Resolve Project Root
  final currentDir = Directory.current;
  final rootDir = File('pubspec.yaml').existsSync()
      ? currentDir
      : Directory(currentDir.path + '/..');

  if (!File('${rootDir.path}/pubspec.yaml').existsSync()) {
    print(
      '❌ Error: Could not find pubspec.yaml. Run this from the project root.',
    );
    exit(1);
  }

  // 2. Clean
  print('[CLEAN] Cleaning Flutter build...');
  await _runCommand('flutter', ['clean'], workingDir: rootDir.path);

  // 3. Build AAR
  print('[BUILD] Building Android AAR...');
  await _runCommand('flutter', [
    'build',
    'aar',
    '--no-profile',
    '--no-release',
  ], workingDir: rootDir.path);

  // 4. Move Artifacts
  final sourceRepo = Directory('${rootDir.path}/build/host/outputs/repo');

  // CHANGED: Target the 'chimera' subdirectory
  final destRepo = Directory('${rootDir.path}/chimera/android/libs');

  if (!sourceRepo.existsSync()) {
    print('❌ Error: AAR build failed. Output directory not found.');
    exit(1);
  }

  print('[MOVE] Moving artifacts to chimera/android/libs...');
  if (destRepo.existsSync()) {
    destRepo.deleteSync(recursive: true);
  }
  destRepo.createSync(recursive: true);

  await _copyDirectory(sourceRepo, destRepo);

  print('✅ Android build complete!');
}

/// Helper: Cross-platform recursive copy
Future<void> _copyDirectory(Directory source, Directory destination) async {
  await for (var entity in source.list(recursive: false)) {
    if (entity is Directory) {
      final newDirectory = Directory(
        '${destination.path}/${entity.path.split(Platform.pathSeparator).last}',
      );
      await newDirectory.create();
      await _copyDirectory(entity.absolute, newDirectory);
    } else if (entity is File) {
      await entity.copy(
        '${destination.path}/${entity.path.split(Platform.pathSeparator).last}',
      );
    }
  }
}

/// Helper: Run shell command
Future<void> _runCommand(
  String cmd,
  List<String> args, {
  required String workingDir,
}) async {
  final executable = Platform.isWindows ? 'cmd' : cmd;
  final arguments = Platform.isWindows ? ['/c', cmd, ...args] : args;

  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDir,
    mode: ProcessStartMode.inheritStdio,
  );

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    print('❌ Command failed: $cmd ${args.join(' ')}');
    exit(exitCode);
  }
}
