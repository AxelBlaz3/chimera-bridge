import 'dart:async';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// -----------------------------------------------------------------------------
/// INTERFACE: Implement this class in your Flutter logic
/// -----------------------------------------------------------------------------
abstract class AllTypesImplementation {
  Stream<String> onString();
  Stream<int> onInt();
  Stream<Map<String, dynamic>> onMap();
  Future<String> getString();
  Future<int> getInt();
  Future<double> getDouble();
  Future<bool> getBool();
  Future<void> voidMethod();
  Future<List<String>> getList();
  Future<Map<String, dynamic>> getMap();
}

/// -----------------------------------------------------------------------------
/// BRIDGE: Handles MethodChannel communication
/// -----------------------------------------------------------------------------
class AllTypesBridge {
  static const MethodChannel _channel =
      MethodChannel('com.example.alltypes.all_types');

  static final List<StreamSubscription> _subscriptions = [];

  /// Cleans up active stream subscriptions.
  /// Call this if you need to stop the bridge without destroying the Flutter Engine.
  static void dispose() {
    for (final sub in _subscriptions) sub.cancel();
    _subscriptions.clear();
  }

  static void setup(AllTypesImplementation implementation) {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    // 0. Ensure a clean state (handles Hot Restart or re-initialization)
    dispose();

    // 1. Setup Stream Listeners (Push from Dart -> Native)

    _subscriptions.add(implementation.onString().listen(
      (event) {
        _channel.invokeMethod('onString', event);
      },
      onError: (error) {
        _channel.invokeMethod('onString', {'_error': error.toString()});
      },
    ));

    _subscriptions.add(implementation.onInt().listen(
      (event) {
        _channel.invokeMethod('onInt', event);
      },
      onError: (error) {
        _channel.invokeMethod('onInt', {'_error': error.toString()});
      },
    ));

    _subscriptions.add(implementation.onMap().listen(
      (event) {
        _channel.invokeMethod('onMap', event);
      },
      onError: (error) {
        _channel.invokeMethod('onMap', {'_error': error.toString()});
      },
    ));

    // 2. Handle Incoming Calls (Pull from Native -> Dart)
    _channel.setMethodCallHandler((call) async {
      try {
        switch (call.method) {
          case 'getString':
            final result = await implementation.getString();
            return result;

          case 'getInt':
            final result = await implementation.getInt();
            return result;

          case 'getDouble':
            final result = await implementation.getDouble();
            return result;

          case 'getBool':
            final result = await implementation.getBool();
            return result;

          case 'voidMethod':
            await implementation.voidMethod();
            return null;

          case 'getList':
            final result = await implementation.getList();
            return result;

          case 'getMap':
            final result = await implementation.getMap();
            return result;

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
