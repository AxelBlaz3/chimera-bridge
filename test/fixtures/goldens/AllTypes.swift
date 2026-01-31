import Foundation
import Flutter
import React

/**
 * A React Native module that bridges communication with a headless Flutter Engine.
 */
@objc(AllTypes)
class AllTypes: RCTEventEmitter {

  private var flutterEngine: FlutterEngine?
  private var methodChannel: FlutterMethodChannel?
  private var hasListeners = false

  override static func moduleName() -> String! {
    return "AllTypes"
  }

  /**
   * Defines the events that this module can send to JavaScript.
   * Used for Flutter Streams.
   */
  override func supportedEvents() -> [String]! {
    return [
      "onString","onInt","onMap",
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
      let engine = FlutterEngine(name: "com.example.alltypes.all_types")
      // Run with default entrypoint (main())
      engine.run()
      self.flutterEngine = engine
      
      // 2. Setup Channel
      let binaryMessenger = engine.binaryMessenger
      let channel = FlutterMethodChannel(name: "com.example.alltypes.all_types", binaryMessenger: binaryMessenger)
      self.methodChannel = channel
      
      // 3. Listen for method calls from Flutter (Streams/Events)
      channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
          guard let self = self else { return }

          switch call.method {
          
          case "onString":
              if self.hasListeners {
                  self.sendEvent(withName: "onString", body: call.arguments)
              }
              result(nil)
              return
          
          case "onInt":
              if self.hasListeners {
                  self.sendEvent(withName: "onInt", body: call.arguments)
              }
              result(nil)
              return
          
          case "onMap":
              if self.hasListeners {
                  self.sendEvent(withName: "onMap", body: call.arguments)
              }
              result(nil)
              return
          
          default:
              result(FlutterMethodNotImplemented)
          }
      }
  }

  
  /**
   * Exposed React Method: getString
   */
  @objc
  func getString(resolve resolve: @escaping RCTPromiseResolveBlock, reject reject: @escaping RCTPromiseRejectBlock) {
      let args: [String: Any] = [
          
      ]
      
      // Delegate to helper
      self.invokeFlutterMethod("getString", args: args, resolve: resolve, reject: reject)
  }
  
  /**
   * Exposed React Method: getInt
   */
  @objc
  func getInt(resolve resolve: @escaping RCTPromiseResolveBlock, reject reject: @escaping RCTPromiseRejectBlock) {
      let args: [String: Any] = [
          
      ]
      
      // Delegate to helper
      self.invokeFlutterMethod("getInt", args: args, resolve: resolve, reject: reject)
  }
  
  /**
   * Exposed React Method: getDouble
   */
  @objc
  func getDouble(resolve resolve: @escaping RCTPromiseResolveBlock, reject reject: @escaping RCTPromiseRejectBlock) {
      let args: [String: Any] = [
          
      ]
      
      // Delegate to helper
      self.invokeFlutterMethod("getDouble", args: args, resolve: resolve, reject: reject)
  }
  
  /**
   * Exposed React Method: getBool
   */
  @objc
  func getBool(resolve resolve: @escaping RCTPromiseResolveBlock, reject reject: @escaping RCTPromiseRejectBlock) {
      let args: [String: Any] = [
          
      ]
      
      // Delegate to helper
      self.invokeFlutterMethod("getBool", args: args, resolve: resolve, reject: reject)
  }
  
  /**
   * Exposed React Method: voidMethod
   */
  @objc
  func voidMethod(resolve resolve: @escaping RCTPromiseResolveBlock, reject reject: @escaping RCTPromiseRejectBlock) {
      let args: [String: Any] = [
          
      ]
      
      // Delegate to helper
      self.invokeFlutterMethod("voidMethod", args: args, resolve: resolve, reject: reject)
  }
  
  /**
   * Exposed React Method: getList
   */
  @objc
  func getList(resolve resolve: @escaping RCTPromiseResolveBlock, reject reject: @escaping RCTPromiseRejectBlock) {
      let args: [String: Any] = [
          
      ]
      
      // Delegate to helper
      self.invokeFlutterMethod("getList", args: args, resolve: resolve, reject: reject)
  }
  
  /**
   * Exposed React Method: getMap
   */
  @objc
  func getMap(resolve resolve: @escaping RCTPromiseResolveBlock, reject reject: @escaping RCTPromiseRejectBlock) {
      let args: [String: Any] = [
          
      ]
      
      // Delegate to helper
      self.invokeFlutterMethod("getMap", args: args, resolve: resolve, reject: reject)
  }
  

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