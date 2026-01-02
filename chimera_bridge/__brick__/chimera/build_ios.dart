import 'dart:io';

void main() async {
  if (Platform.isWindows) {
    print('❌ Error: iOS builds cannot be run on Windows.');
    exit(1);
  }

  // 1. Resolve Root
  final currentDir = Directory.current;
  final rootDir = File('pubspec.yaml').existsSync()
      ? currentDir
      : Directory(currentDir.path + '/..');

  // 2. Clean
  print('[CLEAN] Cleaning Flutter build...');
  final frameworkDir = Directory('${rootDir.path}/ios/Frameworks');
  if (frameworkDir.existsSync()) {
    frameworkDir.deleteSync(recursive: true);
  }
  await _runCommand('flutter', ['clean'], workingDir: rootDir.path);

  // 3. Build Framework
  print('[BUILD] Building iOS Frameworks...');
  await _runCommand('flutter', [
    'build',
    'ios-framework',
    '--output=ios/Frameworks',
  ], workingDir: rootDir.path);

  print('✅ iOS build complete!');
}

Future<void> _runCommand(
  String cmd,
  List<String> args, {
  required String workingDir,
}) async {
  final process = await Process.start(
    cmd,
    args,
    workingDirectory: workingDir,
    mode: ProcessStartMode.inheritStdio,
  );
  if (await process.exitCode != 0) exit(await process.exitCode);
}
