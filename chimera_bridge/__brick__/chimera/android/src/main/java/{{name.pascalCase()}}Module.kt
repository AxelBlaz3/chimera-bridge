package {{package_name}}

import android.os.Handler
import android.os.Looper
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.util.HashMap

/**
 * A React Native module that bridges communication with a headless Flutter Engine.
 */
class {{name.pascalCase()}}Module(private val reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {

    private lateinit var flutterEngine: FlutterEngine
    private lateinit var methodChannel: MethodChannel
    
    // Flutter Engine must be accessed on the main thread
    private val mainHandler = Handler(Looper.getMainLooper())

    init {
        mainHandler.post {
            // 1. Initialize the Flutter Engine
            // This starts a headless engine that shares the application context.
            flutterEngine = FlutterEngine(reactContext.applicationContext)
            
            // 2. Setup the MethodChannel
            // This channel matches the one defined in the Flutter Dart code.
            methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "{{package_name}}.{{name.snakeCase()}}")

            // 3. Set up the incoming method handler (Flutter -> React Native)
            // This listens for "events" sent from Dart Streams.
            methodChannel.setMethodCallHandler { call, result ->
                var handled = false
                
                {{#streams}}
                // Check if the incoming method matches one of our defined streams
                if (call.method == "{{methodName}}") {
                    sendEvent("{{methodName}}", call.arguments)
                    result.success(null)
                    handled = true
                }
                {{/streams}}

                if (!handled) {
                    result.notImplemented()
                }
            }

            // 4. Execute Dart Entrypoint
            // This actually starts the Dart VM and runs main().
            // We do this AFTER setting the handler to avoid race conditions.
            flutterEngine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        }
    }

    override fun getName(): String = "{{name.pascalCase()}}"

    /**
     * Sends an event from Native to the React Native JavaScript side.
     * Used for streaming data updates.
     */
    private fun sendEvent(eventName: String, params: Any?) {
        val jsModule = reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
        when (params) {
            is Map<*, *> -> jsModule.emit(eventName, Arguments.makeNativeMap(params as Map<String, Any>))
            is List<*> -> jsModule.emit(eventName, Arguments.makeNativeArray(params as List<Any>))
            else -> jsModule.emit(eventName, params)
        }
    }

    // Required by React Native for built-in event emitter support
    @ReactMethod
    fun addListener(eventName: String) {}

    @ReactMethod
    fun removeListeners(count: Int) {}

    {{#futures}}
    /**
     * Exposed React Method: {{methodName}}
     * Bridge to Flutter's {{methodName}} method.
     */
    @ReactMethod
    fun {{methodName}}({{#params}}{{name}}: {{kType}}, {{/params}}promise: Promise) {
        // Pack arguments into a map to send over the channel
        val args = HashMap<String, Any?>()
        {{#params}}args["{{name}}"] = {{#isMap}}{{name}}?.toHashMap(){{/isMap}}{{#isList}}{{name}}?.toArrayList(){{/isList}}{{^isMap}}{{^isList}}{{name}}{{/isList}}{{/isMap}}
        {{/params}}
        
        // Delegate to the helper to invoke on the main thread
        invokeFlutterMethod("{{methodName}}", args, promise)
    }
    {{/futures}}

    /**
     * Centralized helper to invoke Flutter methods safely.
     * Handles threading, initialization checks, and Promise resolution.
     */
    private fun invokeFlutterMethod(methodName: String, args: Any?, promise: Promise) {
        mainHandler.post {
            // Guard: Ensure engine is ready
            if (!::methodChannel.isInitialized) {
                promise.reject("INIT_ERROR", "Flutter Engine is not ready.")
                return@post
            }

            // Invoke method on Flutter side
            methodChannel.invokeMethod(methodName, args, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    // Success: Convert native types to WritableMap/Array and resolve promise
                    promise.resolve(convertResult(result))
                }

                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    // Failure: Reject promise with error info from Flutter
                    promise.reject(errorCode, errorMessage)
                }

                override fun notImplemented() {
                    promise.reject("NOT_IMPLEMENTED", "Method $methodName not implemented in Flutter")
                }
            })
        }
    }

    /**
     * Converts raw Java/Kotlin types (Map, List) into React Native's WritableMap/WritableArray.
     * Necessary because MethodChannel returns standard Java collections.
     */
    private fun convertResult(result: Any?): Any? {
        return when (result) {
            null -> null
            is Map<*, *> -> Arguments.makeNativeMap(result as Map<String, Any>)
            is List<*> -> Arguments.makeNativeArray(result as List<Any>)
            else -> result
        }
    }

    /**
     * Cleanup: Destroy the engine when the React Native module is destroyed.
     * Prevents memory leaks.
     */
    override fun onCatalystInstanceDestroy() {
        if (::flutterEngine.isInitialized) {
            mainHandler.post { flutterEngine.destroy() }
        }
        super.onCatalystInstanceDestroy()
    }
}