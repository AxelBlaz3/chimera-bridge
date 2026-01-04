import Foundation
import Flutter
import React

/**
 * A React Native module that bridges communication with a headless Flutter Engine.
 */
@objc({{name.pascalCase()}})
class {{name.pascalCase()}}: RCTEventEmitter {

  private var flutterEngine: FlutterEngine?
  private var methodChannel: FlutterMethodChannel?
  private var hasListeners = false

  override static func moduleName() -> String! {
    return "{{name.pascalCase()}}"
  }

  /**
   * Defines the events that this module can send to JavaScript.
   * Used for Flutter Streams.
   */
  override func supportedEvents() -> [String]! {
    return [
      {{#streams}}"{{methodName}}",{{/streams}}
    ]
  }

  override func startObserving() {
    hasListeners = true
  }

  override func stopObserving() {
    hasListeners = false
  }

  // React Native instantiates this on a background thread by default,
  // but we need the main thread for Flutter Engine initialization.
  override class func requiresMainQueueSetup() -> Bool {
    return true
  }

  override init() {
    super.init()
    // Initialize Flutter on the main thread asynchronously
    DispatchQueue.main.async {
        self.initFlutter()
    }
  }

  /**
   * Spins up the headless Flutter Engine and sets up the MethodChannel.
   */
  private func initFlutter() {
      // 1. Initialize Engine
      let engine = FlutterEngine(name: "{{package_name}}.{{name.snakeCase()}}")
      // Run with default entrypoint (main())
      engine.run()
      self.flutterEngine = engine
      
      // 2. Setup Channel
      let binaryMessenger = engine.binaryMessenger
      let channel = FlutterMethodChannel(name: "{{package_name}}.{{name.snakeCase()}}", binaryMessenger: binaryMessenger)
      self.methodChannel = channel
      
      // 3. Listen for method calls from Flutter (Streams/Events)
      channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
          guard let self = self else { return }

          switch call.method {
          {{#streams}}
          case "{{methodName}}":
              if self.hasListeners {
                  self.sendEvent(withName: "{{methodName}}", body: call.arguments)
              }
              result(nil)
              return
          {{/streams}}
          default:
              result(FlutterMethodNotImplemented)
          }
      }
  }

  {{#futures}}
  /**
   * Exposed React Method: {{methodName}}
   */
  @objc
  func {{methodName}}({{#params}}{{#isFirst}}_ {{name}}: {{sType}}{{/isFirst}}{{^isFirst}}{{name}} {{name}}: {{sType}}{{/isFirst}}, {{/params}}resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
      let args: [String: Any] = [
          {{#params}}"{{name}}": {{name}},{{/params}}
      ]
      
      // Delegate to helper
      self.invokeFlutterMethod("{{methodName}}", args: args, resolve: resolve, reject: reject)
  }
  {{/futures}}

  /**
   * Centralized helper to invoke Flutter methods safely.
   * Handles channel checks and Promise resolution/rejection.
   */
  private func invokeFlutterMethod(_ methodName: String, args: [String: Any], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
      guard let channel = self.methodChannel else {
          reject("INIT_ERROR", "Flutter Engine is not ready.", nil)
          return
      }

      channel.invokeMethod(methodName, arguments: args) { result in
          if let error = result as? FlutterError {
              reject(error.code, error.message, nil)
          } else if (result as? NSObject) == FlutterMethodNotImplemented {
              reject("NOT_IMPLEMENTED", "Method \(methodName) not implemented in Flutter", nil)
          } else {
              resolve(result)
          }
      }
  }
}