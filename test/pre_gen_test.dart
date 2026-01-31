import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:mockito/mockito.dart';

// Import the hook script
import '../chimera_bridge/hooks/pre_gen.dart' as pre_gen;
import 'utils/mocks.mocks.dart';

void main() {
  group('PreGen Hook', () {
    late Directory tempDir;
    late Directory originalCurrent;
    late MockHookContext context;
    late MockLogger logger;

    setUp(() {
      originalCurrent = Directory.current;
      tempDir = Directory.systemTemp.createTempSync('chimera_test_');
      Directory.current = tempDir;

      context = MockHookContext();
      logger = MockLogger();

      // Default stubs
      when(context.logger).thenReturn(logger);
    });

    tearDown(() {
      Directory.current = originalCurrent;
      tempDir.deleteSync(recursive: true);
    });

    test('Auto-Discovery: Finds class matching name without annotation',
        () async {
      // 1. Setup: Create a sample Dart file in the temp dir
      final libDir = Directory(path.join(tempDir.path, 'lib'))..createSync();
      final file = File(path.join(libDir.path, 'math_module.dart'));

      file.writeAsStringSync('''
        abstract class MathModule {
          Future<double> multiply(int a, int b);
        }
      ''');

      // 2. Setup Context
      final initialVars = <String, dynamic>{
        'name': 'MathModule',
        'package_name': 'com.test.app'
      };
      when(context.vars).thenReturn(initialVars);

      // 3. Run Hook
      await pre_gen.run(context);

      // 4. Verify
      // Capture the argument passed to the context.vars setter
      final verification = verify(context.vars = captureAny);
      final updatedVars = verification.captured.last as Map<String, dynamic>;

      final methods = updatedVars['methods'] as List;
      expect(methods, isNotEmpty);

      final multiply = methods.firstWhere((m) => m['methodName'] == 'multiply');
      expect(multiply['returnType'], equals('double'));
      expect(multiply['returnTsType'], equals('number'));

      final params = multiply['params'] as List;
      expect(params.length, equals(2));
      expect(params[0]['name'], equals('a'));
      expect(params[0]['tsType'], equals('number'));
    });

    test('Annotation: Finds class with @ReactBridge even if name differs',
        () async {
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
      final initialVars = <String, dynamic>{
        'name': 'Calculator',
        'package_name': 'com.test.app'
      };
      when(context.vars).thenReturn(initialVars);

      // 3. Run Hook
      await pre_gen.run(context);

      // 4. Verify
      final verification = verify(context.vars = captureAny);
      final updatedVars = verification.captured.last as Map<String, dynamic>;

      expect(
          updatedVars['name'], equals('Calculator')); // Should confirm the name

      final methods = updatedVars['methods'] as List;
      final getName = methods.firstWhere((m) => m['methodName'] == 'getName');
      expect(getName['returnTsType'], equals('string'));
    });
  });
}
