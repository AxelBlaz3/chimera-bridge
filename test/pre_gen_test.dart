import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

// Import the hook script
import '../chimera_bridge/hooks/pre_gen.dart' as pre_gen;
import 'utils/mocks.dart';

void main() {
  group('PreGen Hook', () {
    late Directory tempDir;
    late Directory originalCurrent;

    setUp(() {
      originalCurrent = Directory.current;
      tempDir = Directory.systemTemp.createTempSync('chimera_test_');
      Directory.current = tempDir;
    });

    tearDown(() {
      Directory.current = originalCurrent;
      tempDir.deleteSync(recursive: true);
    });

    test('Auto-Discovery: Finds class matching name without annotation', () async {
      // 1. Setup: Create a sample Dart file in the temp dir
      final libDir = Directory(path.join(tempDir.path, 'lib'))..createSync();
      final file = File(path.join(libDir.path, 'math_module.dart'));
      
      file.writeAsStringSync('''
        abstract class MathModule {
          Future<double> multiply(int a, int b);
        }
      ''');

      // 2. Setup Context
      final context = MockContext();
      context.vars = {'name': 'MathModule', 'package_name': 'com.test.app'};

      // 3. Run Hook
      await pre_gen.run(context);

      // 4. Verify
      final methods = context.vars['methods'] as List;
      expect(methods, isNotEmpty);
      
      final multiply = methods.firstWhere((m) => m['methodName'] == 'multiply');
      expect(multiply['returnType'], equals('double'));
      expect(multiply['returnTsType'], equals('number'));
      
      final params = multiply['params'] as List;
      expect(params.length, equals(2));
      expect(params[0]['name'], equals('a'));
      expect(params[0]['tsType'], equals('number'));
    });

    test('Annotation: Finds class with @ReactBridge even if name differs', () async {
       // 1. Setup: Create a file where class name != module name, but has annotation
      final libDir = Directory(path.join(tempDir.path, 'lib'))..createSync();
      final file = File(path.join(libDir.path, 'some_spec.dart'));
      
      file.writeAsStringSync('''
        @ReactBridge(name: "Calculator")
        abstract class MySpec {
          Future<String> getName();
        }
      ''');

      // 2. Setup Context (Name defaults to something else initially)
      final context = MockContext();
      context.vars = {'name': 'Calculator', 'package_name': 'com.test.app'};

      // 3. Run Hook
      await pre_gen.run(context);

      // 4. Verify
      expect(context.vars['name'], equals('Calculator')); // Should confirm the name
      
      final methods = context.vars['methods'] as List;
      final getName = methods.firstWhere((m) => m['methodName'] == 'getName');
      expect(getName['returnTsType'], equals('string'));
    });
  });
}
