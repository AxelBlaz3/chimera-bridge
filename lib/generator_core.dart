import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

// ==========================================
// 1. DATA MODELS & TYPE MAPPING
// ==========================================

class ParameterModel {
  final String name;
  final String type;
  final bool isNamed;

  ParameterModel(this.name, this.type, {this.isNamed = false});
}

class MethodModel {
  final String name;
  final String returnType;
  final List<ParameterModel> parameters;

  MethodModel(this.name, this.returnType, this.parameters);

  String get kotlinSignature {
    final paramList = parameters.map((p) {
      final kotlinType = TypeMapper.toKotlinInput(p.type);
      return '${p.name}: $kotlinType';
    }).toList();
    paramList.add('promise: Promise');
    return 'fun $name(${paramList.join(', ')})';
  }

  String get swiftSignature {
    final paramList = parameters.map((p) {
      final swiftType = TypeMapper.toSwiftInput(p.type);
      return '_ ${p.name}: $swiftType';
    }).toList();
    paramList.add('resolve: @escaping RCTPromiseResolveBlock');
    paramList.add('reject: @escaping RCTPromiseRejectBlock');
    return 'func $name(${paramList.join(', ')})';
  }
}

class TypeMapper {
  static String toKotlinInput(String dartType) {
    if (dartType.contains('<'))
      dartType = dartType.substring(0, dartType.indexOf('<'));
    switch (dartType) {
      case 'int':
      case 'double':
        return 'Double';
      case 'bool':
        return 'Boolean';
      case 'String':
        return 'String';
      case 'List':
        return 'ReadableArray';
      case 'Map':
        return 'ReadableMap';
      default:
        return 'ReadableMap';
    }
  }

  static String toSwiftInput(String dartType) {
    if (dartType.contains('<'))
      dartType = dartType.substring(0, dartType.indexOf('<'));
    switch (dartType) {
      case 'int':
      case 'double':
        return 'NSNumber';
      case 'bool':
        return 'Bool';
      case 'String':
        return 'String';
      case 'List':
        return 'NSArray';
      case 'Map':
        return 'NSDictionary';
      default:
        return 'NSDictionary';
    }
  }
}

// ==========================================
// 2. ANALYZER VISITOR
// ==========================================

class MethodExtractor extends GeneralizingAstVisitor<void> {
  final List<MethodModel> methods = [];

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final name = node.name.lexeme;
    String returnType = node.returnType?.toSource() ?? 'dynamic';
    if (returnType.startsWith('Future<'))
      returnType = returnType.substring(7, returnType.length - 1);

    final List<ParameterModel> params = [];
    if (node.parameters != null) {
      for (var param in node.parameters!.parameters) {
        String type = 'dynamic';
        String paramName = 'param';

        if (param is SimpleFormalParameter) {
          type = param.type?.toSource() ?? 'dynamic';
          paramName = param.name!.lexeme;
        } else if (param is DefaultFormalParameter) {
          if (param.parameter is SimpleFormalParameter) {
            final simple = param.parameter as SimpleFormalParameter;
            type = simple.type?.toSource() ?? 'dynamic';
            paramName = simple.name!.lexeme;
          }
        }
        params.add(ParameterModel(paramName, type, isNamed: param.isNamed));
      }
    }
    methods.add(MethodModel(name, returnType, params));
    super.visitMethodDeclaration(node);
  }
}

List<MethodModel> parseContract(String fileContent) {
  final parseResult = parseString(content: fileContent);
  final visitor = MethodExtractor();
  parseResult.unit.visitChildren(visitor);
  return visitor.methods;
}

// ==========================================
// 3. CODE GENERATOR FACTORY
// ==========================================

class CodeGenerator {
  final String packageName;
  final String channelName;

  CodeGenerator({
    this.packageName = "com.generated.bridge",
    this.channelName = "com.generated.bridge/channel",
  });

  // --- ANDROID: MODULE ---
  String generateKotlin(List<MethodModel> methods) {
    final funcs = methods
        .map((m) {
          final mapEntries = m.parameters
              .map((p) => '"${p.name}" to ${p.name}')
              .join(', ');
          return '''
    @ReactMethod
    ${m.kotlinSignature} {
        val args = mapOf<String, Any?>($mapEntries)
        Handler(Looper.getMainLooper()).post {
             // Use the cached channel if available
             methodChannel?.invokeMethod("${m.name}", args, object : MethodChannel.Result {
                override fun success(r: Any?) {
                    try {
                        when (r) {
                            is Map<*, *> -> promise.resolve(Arguments.makeNativeMap(r as Map<String, Any>))
                            is List<*> -> promise.resolve(Arguments.makeNativeArray(r as List<Any>))
                            else -> promise.resolve(r)
                        }
                    } catch (e: Exception) {
                        promise.reject("CONVERSION_ERROR", e.message)
                    }
                }
                override fun error(c: String, m: String?, d: Any?) = promise.reject(c, m)
                override fun notImplemented() = promise.reject("NOT_IMPL", "Not implemented")
            })
        }
    }''';
        })
        .join('\n');

    return '''package $packageName
import android.os.Handler
import android.os.Looper
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class GeneratedModule(ctx: ReactApplicationContext) : ReactContextBaseJavaModule(ctx) {
    override fun getName() = "GeneratedModule"
    
    // Shared channel instance
    private var methodChannel: MethodChannel? = null

    init {
        Handler(Looper.getMainLooper()).post {
            // 1. Setup Engine
            var engine = FlutterEngineCache.getInstance().get("$channelName")
            if (engine == null) {
                engine = FlutterEngine(ctx)
                engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
                FlutterEngineCache.getInstance().put("$channelName", engine)
            }

            // 2. Setup Channel & Listener
            methodChannel = MethodChannel(engine!!.dartExecutor.binaryMessenger, "$channelName")
            methodChannel!!.setMethodCallHandler { call, result ->
                if (call.method == "__emit_event__") {
                    val eventName = call.argument<String>("name")
                    val data = call.argument<Any>("data")
                    
                    val params = Arguments.createMap()
                    params.putString("name", eventName)
                    
                    when (data) {
                        is String -> params.putString("data", data)
                        is Int -> params.putInt("data", data)
                        is Double -> params.putDouble("data", data)
                        is Boolean -> params.putBoolean("data", data)
                        is Map<*, *> -> params.putMap("data", Arguments.makeNativeMap(data as Map<String, Any>))
                        is List<*> -> params.putArray("data", Arguments.makeNativeArray(data as List<Any>))
                    }

                    reactApplicationContext
                        .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                        .emit("FlutterBridgeEvent", params)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
        }
    }
$funcs
}''';
  }

  // --- ANDROID: PACKAGE ---
  String generateGeneratedPackage() {
    return '''package $packageName
import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager

class GeneratedPackage : ReactPackage {
    override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> {
        return listOf(GeneratedModule(reactContext))
    }
    override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
        return emptyList()
    }
}''';
  }

  // --- ANDROID: MANIFEST ---
  String generateAndroidManifest() {
    return '''<manifest xmlns:android="http://schemas.android.com/apk/res/android"
          package="$packageName">
</manifest>''';
  }

  // --- ANDROID: BUILD.GRADLE ---
  String generateAndroidBuildGradle() {
    return '''
buildscript {
    repositories { google(); mavenCentral() }
    dependencies {
        classpath 'com.android.tools.build:gradle:7.0.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.0"
    }
}
apply plugin: 'com.android.library'
apply plugin: 'kotlin-android'

android {
    compileSdkVersion 33
    defaultConfig { minSdkVersion 21 }
    buildTypes {
        release { minifyEnabled false }
        profile { initWith release; matchingFallbacks = ['release'] }
        debug { minifyEnabled false }
    }
}

repositories {
    mavenCentral()
    maven { url(new File(projectDir, "libs")) }
}

dependencies {
    implementation "com.facebook.react:react-native:+"
    implementation "org.jetbrains.kotlin:kotlin-stdlib:1.8.0"
    debugImplementation 'com.generated.flutter_module:flutter_debug:1.0'
    profileImplementation 'com.generated.flutter_module:flutter_profile:1.0'
    releaseImplementation 'com.generated.flutter_module:flutter_release:1.0'
}
''';
  }

  // --- IOS: SWIFT ---
  String generateSwift(List<MethodModel> methods) {
    final funcs = methods
        .map((m) {
          final dictEntries = m.parameters
              .map((p) => '"${p.name}": ${p.name}')
              .join(', ');
          return '''
    @objc
    ${m.swiftSignature} {
        DispatchQueue.main.async {
            guard let channel = self.methodChannel else { 
                return reject("NO_ENGINE", "Engine not ready", nil) 
            }
            
            channel.invokeMethod("${m.name}", arguments: [$dictEntries]) { (res) in
                if let err = res as? FlutterError { 
                    reject(err.code, err.message, nil) 
                } else { 
                    resolve(res) 
                }
            }
        }
    }''';
        })
        .join('\n');

    return '''import Foundation
import Flutter
import React

@objc(GeneratedModule)
class GeneratedModule: RCTEventEmitter {
    static var engine: FlutterEngine?
    var methodChannel: FlutterMethodChannel?

    override init() {
        super.init()
        DispatchQueue.main.async {
            // 1. Setup Engine
            if GeneratedModule.engine == nil {
                GeneratedModule.engine = FlutterEngine(name: "$channelName")
                GeneratedModule.engine?.run()
            }
            
            // 2. Setup Channel & Listener
            if let engine = GeneratedModule.engine {
                self.methodChannel = FlutterMethodChannel(name: "$channelName", binaryMessenger: engine.binaryMessenger)
                
                self.methodChannel?.setMethodCallHandler { [weak self] (call, result) in
                    if call.method == "__emit_event__" {
                        guard let args = call.arguments as? [String: Any],
                              let name = args["name"] as? String else { return }
                        
                        self?.sendEvent(withName: "FlutterBridgeEvent", body: ["name": name, "data": args["data"]])
                        result(nil)
                    } else {
                        result(FlutterMethodNotImplemented)
                    }
                }
            }
        }
    }
    
    override func supportedEvents() -> [String]! {
        return ["FlutterBridgeEvent"]
    }
    
    @objc override static func requiresMainQueueSetup() -> Bool { return true }
    
$funcs
}''';
  }

  // --- IOS: PODSPEC ---
  String generatePodspec(String pkgName) {
    return '''
Pod::Spec.new do |s|
  s.name         = "$pkgName"
  s.version      = "1.0.0"
  s.summary      = "Flutter Bridge"
  s.homepage     = "https://example.com"
  s.license      = "MIT"
  s.authors      = { "Your Name" => "your@email.com" }
  s.platform     = :ios, "11.0"
  s.source       = { :git => "", :tag => "#{s.version}" }
  s.source_files = "ios/**/*.{h,m,swift}"
  s.vendored_frameworks = 'ios/Frameworks/App.xcframework', 'ios/Frameworks/Flutter.xcframework'
  s.dependency "React-Core"
end
''';
  }

  // --- FLUTTER ---
  // --- FLUTTER: MAIN.DART ---
  String generateFlutterMain(List<MethodModel> methods) {
    final cases = methods
        .map((m) {
          final extractions = m.parameters
              .map((p) {
                if (p.type == 'int') {
                  return "final int ${p.name} = (call.arguments['${p.name}'] as num).toInt();";
                }
                return "final ${p.type} ${p.name} = call.arguments['${p.name}'];";
              })
              .join('\n      ');

          final callArgs = m.parameters
              .map((p) => p.isNamed ? "${p.name}: ${p.name}" : p.name)
              .join(', ');
          return '''
    case '${m.name}':
      $extractions
      return service.${m.name}($callArgs);
      ''';
        })
        .join('');

    return '''import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

// 1. Shared Channel
const MethodChannel _channel = MethodChannel('$channelName');

// 2. Bridge Helper (To send events to JS)
class Bridge {
  static Future<void> emit(String eventName, dynamic data) async {
    try {
      await _channel.invokeMethod('__emit_event__', {'name': eventName, 'data': data});
    } catch (e) {
      print("Failed to emit event: \$e");
    }
  }
}

// 3. Service Implementation (Your Logic Goes Here)
class BridgeService { 
  ${methods.map((m) {
      final positional = m.parameters.where((p) => !p.isNamed).map((p) => "dynamic ${p.name}").join(', ');
      final named = m.parameters.where((p) => p.isNamed).map((p) => "required dynamic ${p.name}").join(', ');
      String args = positional;
      if (named.isNotEmpty) {
        if (args.isNotEmpty) args += ", ";
        args += "{$named}";
      }
      return "dynamic ${m.name}($args) => null;";
    }).join('\n  ')}
}

// 4. Main Entry Point
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final BridgeService service = BridgeService();

  _channel.setMethodCallHandler((call) async {
    switch (call.method) {
$cases
      default:
        throw PlatformException(code: 'Unimplemented', message: 'Method \${call.method} not found');
    }
  });
}
''';
  }

  // --- JS & TS ---
  String generateIndexJs(List<MethodModel> methods) => '''
import { NativeModules, NativeEventEmitter } from 'react-native';
const { GeneratedModule } = NativeModules;
const eventEmitter = new NativeEventEmitter(GeneratedModule);

export default {
  ...GeneratedModule,
  addListener: (eventName, callback) => {
    return eventEmitter.addListener('FlutterBridgeEvent', (payload) => {
      if (payload.name === eventName) {
        callback(payload.data);
      }
    });
  }
};
''';

  String generateTypeDefs(List<MethodModel> methods) {
    final functions = methods
        .map((m) {
          final params = m.parameters
              .map((p) {
                String tsType = 'any';
                if (p.type.contains('String'))
                  tsType = 'string';
                else if (p.type.contains('int') || p.type.contains('double'))
                  tsType = 'number';
                else if (p.type.contains('bool'))
                  tsType = 'boolean';
                return '${p.name}: $tsType';
              })
              .join(', ');
          return '  ${m.name}(${params}): Promise<any>;';
        })
        .join('\n');

    return '''
export interface BridgeInterface {
$functions
  addListener(eventName: string, callback: (data: any) => void): { remove: () => void };
}
declare const _default: BridgeInterface;
export default _default;
''';
  }

  String generatePackageJson(String name) =>
      '''{
  "name": "$name", "version": "1.0.0", "main": "index.js", "types": "index.d.ts",
  "peerDependencies": { "react": "*", "react-native": "*" }
}''';
}
