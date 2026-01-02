import Foundation
import Flutter
import React

@objc({{name.pascalCase()}})
class {{name.pascalCase()}}: RCTEventEmitter {

  private var flutterEngine: FlutterEngine?
  private var methodChannel: FlutterMethodChannel?
  private var hasListeners = false

  override static func moduleName() -> String! {
    return "{{name.pascalCase()}}"
  }

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

  override class func requiresMainQueueSetup() -> Bool {
    return true
  }

  override init() {
    super.init()
    DispatchQueue.main.async {
        self.initFlutter()
    }
  }

  private func initFlutter() {
      let engine = FlutterEngine(name: "{{package_name}}.{{name.snakeCase()}}")
      engine.run()
      self.flutterEngine = engine
      
      let binaryMessenger = engine.binaryMessenger
      let channel = FlutterMethodChannel(name: "{{package_name}}.{{name.snakeCase()}}", binaryMessenger: binaryMessenger)
      self.methodChannel = channel
      
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
  @objc
  func {{methodName}}({{#params}}{{#isFirst}}_ {{name}}: {{sType}}{{/isFirst}}{{^isFirst}}{{name}} {{name}}: {{sType}}{{/isFirst}}, {{/params}}resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
      guard let channel = self.methodChannel else {
          reject("INIT_ERROR", "Engine not ready", nil)
          return
      }
      
      let args: [String: Any] = [
          {{#params}}"{{name}}": {{name}},{{/params}}
      ]

      channel.invokeMethod("{{methodName}}", arguments: args) { (result) in
          if let error = result as? FlutterError {
              reject(error.code, error.message, nil)
          } else if result == FlutterMethodNotImplemented {
              reject("NOT_IMPLEMENTED", "Method not found", nil)
          } else {
              resolve(result)
          }
      }
  }
  {{/futures}}
}