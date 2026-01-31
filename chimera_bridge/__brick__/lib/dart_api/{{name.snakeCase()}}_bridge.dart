import 'dart:async';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// -----------------------------------------------------------------------------
/// INTERFACE: Implement this class in your Flutter logic
/// -----------------------------------------------------------------------------
abstract class {{name.pascalCase()}}Implementation {
  {{#streams}}Stream<{{{returnType}}}> {{methodName}}();{{/streams}}
  {{#futures}}Future<{{{returnType}}}> {{methodName}}({{#params}}{{{dType}}} {{name}}{{^last}}, {{/last}}{{/params}});{{/futures}}
}

/// -----------------------------------------------------------------------------
/// BRIDGE: Handles MethodChannel communication
/// -----------------------------------------------------------------------------
class {{name.pascalCase()}}Bridge {
  static const MethodChannel _channel = MethodChannel('{{package_name}}.{{name.snakeCase()}}');
  {{#hasStreams}}
  static final List<StreamSubscription> _subscriptions = [];

  /// Cleans up active stream subscriptions.
  /// Call this if you need to stop the bridge without destroying the Flutter Engine.
  static void dispose() {
    for (final sub in _subscriptions) sub.cancel();
    _subscriptions.clear();
  }
  {{/hasStreams}}

  static void setup({{name.pascalCase()}}Implementation implementation) {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    
    {{#hasStreams}}
    // 0. Ensure a clean state (handles Hot Restart or re-initialization)
    dispose();

    // 1. Setup Stream Listeners (Push from Dart -> Native)
    {{#streams}}
    _subscriptions.add(implementation.{{methodName}}().listen(
      (event) {
        _channel.invokeMethod('{{methodName}}', event);
      },
      onError: (error) {
        _channel.invokeMethod('{{methodName}}', {'_error': error.toString()});
      },
    ));
    {{/streams}}
    {{/hasStreams}}

    // 2. Handle Incoming Calls (Pull from Native -> Dart)
    _channel.setMethodCallHandler((call) async {
      try {
        switch (call.method) {
          {{#futures}}
          case '{{methodName}}':
            {{#hasParams}}final args = call.arguments as Map<dynamic, dynamic>;{{/hasParams}}
            
            {{#isVoid}}
            await implementation.{{methodName}}({{#params}}
              _cast<{{{dType}}}>(args['{{name}}']),{{/params}}
            );
            return null;
            {{/isVoid}}

            {{^isVoid}}
            final result = await implementation.{{methodName}}({{#params}}
              _cast<{{{dType}}}>(args['{{name}}']),{{/params}}
            );
            return result;
            {{/isVoid}}
          {{/futures}}
          default:
            throw MissingPluginException();
        }
      } catch (e) {
        throw PlatformException(code: 'ERROR', message: e.toString());
      }
    });
  }

  static T _cast<T>(dynamic value) {
    if (value is T) return value;
    if (T == int && value is num) return value.toInt() as T;
    if (T == double && value is num) return value.toDouble() as T;
    if (value is Map) return Map<String, dynamic>.from(value) as T;
    if (value is List) return List<dynamic>.from(value) as T;
    throw FormatException('Expected $T but got ${value.runtimeType}');
  }
}