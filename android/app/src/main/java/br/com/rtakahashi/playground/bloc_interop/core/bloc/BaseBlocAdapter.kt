package br.com.rtakahashi.playground.bloc_interop.core.bloc

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.JSONMethodCodec
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.util.UUID
import kotlin.properties.Delegates

/**
 * Offers communication to a bloc that exists in Dart code.
 * The blocName parameter must correspond to an InteropBloc that has the same name.
 *
 * The initial state is not very important, because this base class attempts to get the bloc's
 * current state right away during initialization.
 */
abstract class BaseBlocAdapter<S>(blocName: String, engine: FlutterEngine, initialState: S) {
    private val methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, "br.com.rtakahashi.playground.bloc_interop/${blocName}", JSONMethodCodec.INSTANCE)
    private val updateStateCallbackName = "updateState-${UUID.randomUUID()}"
    private val listeners: MutableMap<String, (S) -> Unit> = mutableMapOf();

    // This is to send the most recent state immediately after someone subscribes to this adapter.
    private var _cachedState: S = initialState

    private var initialized = false;

    fun initialize() {
        if (initialized) return;
        // When this method initializes, subscribe to the bloc to receive state updates.
        // The bloc (in Flutter) doesn't send state updates by default, because if it did, it
        // would waste messages when the native side isn't listening.

        // We use an uuid to avoid collisions. The interop bloc (in Flutter) remembers the name
        // we register here. However, in theory, collisions should *never* happen because only
        // zero or one adapters (in native code) should exist for each bloc (in Flutter).
        methodChannel.invokeMethod("registerCallback", updateStateCallbackName);
        methodChannel.setMethodCallHandler{
            call, result ->
                when (call.method) {
                    updateStateCallbackName -> updateState(call.arguments)
                }
        }

        // Attempt to sync the value here with the value from Flutter right away.
        // If this fails, this instance will continue to use the initial state provided
        // by the subclass.
        syncCurrentStateFromFlutter();

        // If kotlin had destructors, we would call "unregisterCallback" in it.
        // Currently, we expect every bloc adapter to live forever.
        // (is there a possible memory leak issue here?)

        initialized = true;
    }

    // Technically, we can send anything as parameters through the method channel, but if we send
    // some Java object it actually just calls its toString(), which is kinda useless.
    // It's easier to require maps instead. Those always get turned into jsons as expected.
    fun send(data: Map<String, Any>) {
        println(data.toString());
        methodChannel.invokeMethod("sendEvent", data);
    }

    private fun syncCurrentStateFromFlutter() {
        methodChannel.invokeMethod("getCurrentState", null, object : MethodChannel.Result {
            override fun success(result: Any?) {
                updateState(result);
            }

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                // ?? Probably fine to ignore. This adapter will continue using the default state
                // provided by the subclass.
            }

            override fun notImplemented() {
                throw NotImplementedError("Could not get current state.")
            }
        });
    }

    /**
     * Get the current state
     */
    fun currentState(): S {
        return _cachedState;
    }

    /**
     * Convert a message received from Flutter into an instance of the bloc's state.
     * The parameter will be a json object whose fields are created in the Flutter bloc's
     * stateToMessage method.
     */
    protected abstract fun messageToState(message: JSONObject): S;

    private fun updateState(data: Any?) {
        val state = messageToState(data as JSONObject);
        _cachedState = state;
        for (listener in listeners) {
            listener.value(state);
        }
    }

    /**
     * Register to listen to the stream of the corresponding bloc.
     * This function will return a handle which must be used to
     * unregister the callback when it's no longer needed.
     */
    fun listen(callback: (value: S) -> Unit): String {
        val handle = UUID.randomUUID().toString();
        listeners[handle] = callback;
        // Additionally, send the state immediately to this callback.
        // This ensures that everyone will have a useful state right away without needing to
        // render an empty screen.
        callback(_cachedState);

        return handle;
    }

    fun clearListener(handle: String) {
        listeners.remove(handle);
    }
}