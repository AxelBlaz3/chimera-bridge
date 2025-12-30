import 'dart:io';
import 'package:mason/mason.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// ---------------------------------------------------------------------------
/// TYPE MAPPING CONFIGURATION
/// ---------------------------------------------------------------------------
const typeMap = {
  // Primitives
  'String': {'k': 'String', 's': 'String', 'o': 'NSString *', 't': 'string'},
  'int': {'k': 'Double', 's': 'NSNumber', 'o': 'NSNumber *', 't': 'number'},
  'double': {'k': 'Double', 's': 'NSNumber', 'o': 'NSNumber *', 't': 'number'},
  'bool': {'k': 'Boolean', 's': 'Bool', 'o': 'BOOL', 't': 'boolean'},
  'void': {'k': 'Void', 's': 'Void', 'o': 'void', 't': 'void'},

  // Collections
  'Map': {
    'k': 'ReadableMap',
    's': '[String: Any]',
    'o': 'NSDictionary *',
    't': 'object'
  },
  'List': {'k': 'ReadableArray', 's': '[Any]', 'o': 'NSArray *', 't': 'any[]'},
};

/// Helper to safely get the TS type from a Dart type string
String getTsType(String dartType) {
  String lookup = dartType;
  if (lookup.startsWith('List')) lookup = 'List';
  if (lookup.startsWith('Map')) lookup = 'Map';
  return typeMap[lookup]?['t'] ?? 'any';
}

Future<void> run(HookContext context) async {
  final logger = context.logger;

  // ========================================================================
  // 1. ROOT DETECTION & SCANNING
  // ========================================================================
  var searchDir = Directory.current;
  if (!Directory.fromUri(searchDir.uri.resolve('lib')).existsSync()) {
    final parentDir = searchDir.parent;
    if (Directory.fromUri(parentDir.uri.resolve('lib')).existsSync()) {
      searchDir = parentDir;
    }
  }

  final glob = Glob('**/*.dart', recursive: true);
  File? specFile;
  ClassDeclaration? annotatedClass;
  Annotation? bridgeAnnotation;

  logger.info('🔍 Scanning for @ReactBridge candidates...');

  await for (final entity
      in glob.list(root: searchDir.path, followLinks: false)) {
    if (entity.statSync().type != FileSystemEntityType.file) continue;
    if (entity.path.contains(RegExp(r'[\\/]\.'))) continue;
    if (entity.path.contains('chimera_bridge')) continue;
    if (entity.path.contains('mobile_app_repo')) continue;

    final file = File(entity.path);
    String content;
    try {
      content = await file.readAsString();
    } catch (_) {
      continue;
    }

    if (!content.contains('ReactBridge')) continue;

    try {
      final unit = parseString(content: content).unit;
      for (var decl in unit.declarations) {
        if (decl is ClassDeclaration) {
          if (decl.metadata.isEmpty) continue;
          for (var m in decl.metadata) {
            if (m.name.name == 'ReactBridge') {
              specFile = file;
              annotatedClass = decl;
              bridgeAnnotation = m;
              break;
            }
          }
        }
        if (specFile != null) break;
      }
    } catch (e) {
      // Ignore parsing errors
    }
    if (specFile != null) break;
  }

  if (specFile == null || annotatedClass == null) {
    logger.err('❌ Could not find any class annotated with @ReactBridge.');
    exit(1);
  }

  // ========================================================================
  // 2. VARIABLE EXTRACTION
  // ========================================================================
  final packageName = context.vars['package_name'] as String? ?? 'com.myapp';
  final packagePath = packageName.replaceAll('.', '/');

  // Get Module Name
  String moduleName = annotatedClass.name.lexeme;
  try {
    if (bridgeAnnotation!.arguments != null &&
        bridgeAnnotation.arguments!.arguments.isNotEmpty) {
      final firstArg = bridgeAnnotation.arguments!.arguments.first;
      if (firstArg is NamedExpression && firstArg.name.label.name == 'name') {
        moduleName = firstArg.expression
            .toSource()
            .replaceAll('"', '')
            .replaceAll("'", "");
      }
    }
  } catch (_) {}

  // Process Methods
  final methods = <Map<String, dynamic>>[];

  for (var member in annotatedClass.members) {
    if (member is MethodDeclaration) {
      final methodName = member.name.lexeme;

      // Extract Return Type & Check for Stream
      String rawReturnType = member.returnType?.toSource() ?? 'void';
      String returnType = rawReturnType;
      bool isStream = false;

      if (returnType.startsWith('Future<') && returnType.endsWith('>')) {
        returnType = returnType.substring(7, returnType.length - 1);
      } else if (returnType.startsWith('Stream<') && returnType.endsWith('>')) {
        returnType = returnType.substring(7, returnType.length - 1);
        isStream = true;
      }

      // Process Parameters
      final params = <Map<String, dynamic>>[];
      final parametersList = member.parameters?.parameters ?? [];
      final paramsCount = parametersList.length;
      var index = 0;

      for (var param in parametersList) {
        String rawDartType = 'String';
        String paramName = 'unknown';

        if (param is SimpleFormalParameter) {
          rawDartType = param.type?.toSource().replaceAll('?', '') ?? 'String';
          paramName = param.name!.lexeme;
        } else if (param is DefaultFormalParameter) {
          if (param.parameter is SimpleFormalParameter) {
            final simple = param.parameter as SimpleFormalParameter;
            rawDartType =
                simple.type?.toSource().replaceAll('?', '') ?? 'String';
            paramName = simple.name!.lexeme;
          }
        }

        // Generic Type Lookup
        String lookupType = rawDartType;
        if (lookupType.startsWith('List')) lookupType = 'List';
        if (lookupType.startsWith('Map')) lookupType = 'Map';

        final map = typeMap[lookupType] ?? typeMap['String']!;

        params.add({
          'name': paramName,
          'dType': rawDartType,

          // Language Specific Types
          'kType': map['k'],
          'sType': map['s'],
          'oType': map['o'],
          'tsType': map['t'],

          // Formatting Helpers
          'capName':
              paramName.substring(0, 1).toUpperCase() + paramName.substring(1),
          'isList': lookupType == 'List',
          'isMap': lookupType == 'Map',
          'isFirst': index == 0,
          'last': index == paramsCount - 1,
        });
        index++;
      }

      methods.add({
        'methodName': methodName,
        'returnType': returnType, // Dart type (e.g. double)
        'returnTsType': getTsType(returnType), // TypeScript type (e.g. number)
        'isVoid': returnType == 'void',
        'isStream': isStream,
        'params': params,
        'hasParams': params.isNotEmpty,
      });
    }
  }

  // Separate streams and futures to avoid whitespace in templates
  final streams = methods.where((m) => m['isStream'] == true).toList();
  final futures = methods.where((m) => m['isStream'] != true).toList();

  // Update Context
  context.vars = {
    ...context.vars,
    'name': moduleName,
    'methods': methods,
    'streams': streams,
    'futures': futures,
    'package_path': packagePath,
  };
}
