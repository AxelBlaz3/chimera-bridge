import 'dart:io';
import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final logger = context.logger;
  final name = context.vars['name'];

  // 1. Make scripts executable (Mac/Linux only)
  // This saves the user from typing "chmod +x ..." manually.
  if (!Platform.isWindows) {
    try {
      final scripts = ['scripts/build_android.sh', 'scripts/build_ios.sh'];

      for (final script in scripts) {
        final file = File(script);
        if (file.existsSync()) {
          await Process.run('chmod', ['+x', script]);
        }
      }
      logger.detail('✅ Made build scripts executable');
    } catch (e) {
      // Don't crash if permissions fail, just warn
      logger.warn('Could not set script permissions: $e');
    }
  }

  // 2. Success Message
  logger.success('''
  🦁 Chimera Bridge Created: $name
  
  NEXT STEPS:
  ---------------------------------------------------------
  1. Implement logic:  lib/main.dart
     -> call ${name}Bridge.setup(...)
  
  2. Build Binaries:
     -> ./scripts/build_android.sh
     -> ./scripts/build_ios.sh
     
  3. Install in React Native:
     -> npm install ./path/to/$name-1.0.0.tgz
  ---------------------------------------------------------
  ''');
}
