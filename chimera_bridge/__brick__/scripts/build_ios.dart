import 'dart:io';

void main() async {
  // 1. Check Platform (iOS builds require macOS)
  if (Platform.isWindows || Platform.isLinux) {
    print('❌ Error: iOS builds can only be run on macOS.');
    exit(1);
  }

  // 2. Resolve Project Root
  // This allows running from root via "dart run scripts/..." or inside scripts/
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

  // 3. Clean Previous Builds
  print('[CLEAN] Cleaning previous artifacts...');

  // Target the isolated 'chimera' folder
  final frameworkDir = Directory('${rootDir.path}/chimera/ios/Frameworks');
  if (frameworkDir.existsSync()) {
    frameworkDir.deleteSync(recursive: true);
  }

  print('[CLEAN] Running flutter clean...');
  await _runCommand('flutter', ['clean'], workingDir: rootDir.path);

  // 4. Build Frameworks
  print('[BUILD] Building iOS Frameworks...');

  // Output directly to the chimera package folder
  await _runCommand('flutter', [
    'build',
    'ios-framework',
    '--output=chimera/ios/Frameworks',
  ], workingDir: rootDir.path);

  print('✅ iOS build complete! Frameworks are ready in chimera/ios/Frameworks');
}

/// Helper: Run shell command
Future<void> _runCommand(
  String cmd,
  List<String> args, {
  required String workingDir,
}) async {
  final process = await Process.start(
    cmd,
    args,
    workingDirectory: workingDir,
    mode: ProcessStartMode.inheritStdio, // Stream output to console
  );

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    print('❌ Command failed: $cmd ${args.join(' ')}');
    exit(exitCode);
  }
}
