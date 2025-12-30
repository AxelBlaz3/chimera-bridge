package {{package_name}}

import android.os.Handler
import android.os.Looper
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.util.HashMap

class {{name.pascalCase()}}Module(private val reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {

    private lateinit var flutterEngine: FlutterEngine
    private lateinit var methodChannel: MethodChannel
    private val mainHandler = Handler(Looper.getMainLooper())

    init {
        mainHandler.post {
            // 1. Initialize Engine
            flutterEngine = FlutterEngine(reactContext.applicationContext)
            
            // 2. Setup Channel & Listener BEFORE running Dart (Prevents Race Condition)
            methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "{{package_name}}.{{name.snakeCase()}}")

            methodChannel.setMethodCallHandler { call, result ->
                var handled = false
                
                {{#streams}}
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

            // 3. Execute Dart Entrypoint (Now safe to run)
            flutterEngine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        }
    }

    override fun getName(): String = "{{name.pascalCase()}}"

    private fun sendEvent(eventName: String, params: Any?) {
        val jsModule = reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
        when (params) {
            is Map<*, *> -> jsModule.emit(eventName, Arguments.makeNativeMap(params as Map<String, Any>))
            is List<*> -> jsModule.emit(eventName, Arguments.makeNativeArray(params as List<Any>))
            else -> jsModule.emit(eventName, params)
        }
    }

    @ReactMethod
    fun addListener(eventName: String) {}

    @ReactMethod
    fun removeListeners(count: Int) {}

    {{#futures}}
    @ReactMethod
    fun {{methodName}}({{#params}}{{name}}: {{kType}}, {{/params}}promise: Promise) {
        val args = HashMap<String, Any?>()
        {{#params}}args["{{name}}"] = {{#isMap}}{{name}}?.toHashMap(){{/isMap}}{{#isList}}{{name}}?.toArrayList(){{/isList}}{{^isMap}}{{^isList}}{{name}}{{/isList}}{{/isMap}}
        {{/params}}
        
        mainHandler.post {
            if (!::methodChannel.isInitialized) {
                promise.reject("INIT_ERROR", "Flutter Engine is not ready.")
                return@post
            }
            methodChannel.invokeMethod("{{methodName}}", args, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    promise.resolve(convertResult(result))
                }
                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    promise.reject(errorCode, errorMessage)
                }
                override fun notImplemented() {
                    promise.reject("NOT_IMPLEMENTED", "Method {{methodName}} not implemented")
                }
            })
        }
    }
    {{/futures}}

    private fun convertResult(result: Any?): Any? {
        return when (result) {
            null -> null
            is Map<*, *> -> Arguments.makeNativeMap(result as Map<String, Any>)
            is List<*> -> Arguments.makeNativeArray(result as List<Any>)
            else -> result
        }
    }

    override fun onCatalystInstanceDestroy() {
        if (::flutterEngine.isInitialized) {
            mainHandler.post { flutterEngine.destroy() }
        }
        super.onCatalystInstanceDestroy()
    }
}