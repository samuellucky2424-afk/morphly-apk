package com.morphly.decart_realtime_bridge

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DecartRealtimeBridgePlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private val handler = Handler(Looper.getMainLooper())
    private var elapsedSeconds = 0
    private var ticking = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, "morphly/decart_realtime/methods")
        eventChannel = EventChannel(binding.binaryMessenger, "morphly/decart_realtime/events")
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        stopTicker("stopped", "Bridge detached.")
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startSession" -> {
                val clientToken = call.argument<String>("clientToken")
                val model = call.argument<String>("model")
                val prompt = call.argument<String>("prompt")
                if (clientToken.isNullOrBlank() || model.isNullOrBlank()) {
                    emit("failed", "Missing Decart token or model.", elapsedSeconds)
                    result.error("invalid_args", "Missing Decart token or model.", null)
                    return
                }

                // Production hook:
                // 1. Initialize ai.decart.sdk.DecartClient with the short-lived token.
                // 2. Attach the camera WebRTC track using the selected quality/model constraints.
                // 3. Send the reference image/prompt and render remote frames into a PlatformView.
                emit("starting", "Connecting to Decart.", 0)
                startTicker(prompt ?: "Morphly realtime session")
                result.success(null)
            }
            "setPrompt" -> {
                val prompt = call.argument<String>("prompt") ?: ""
                // Production hook: client.realtime.setPrompt(prompt, enhance = true)
                emit("connected", "Prompt updated: $prompt", elapsedSeconds)
                result.success(null)
            }
            "stopSession" -> {
                stopTicker("stopped", "Session stopped.")
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        emit("idle", "Ready.", 0)
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun startTicker(message: String) {
        stopTicker("starting", message)
        elapsedSeconds = 0
        ticking = true
        emit("connected", message, elapsedSeconds)
        handler.postDelayed(object : Runnable {
            override fun run() {
                if (!ticking) return
                elapsedSeconds += 1
                emit("connected", "Live morphing.", elapsedSeconds)
                handler.postDelayed(this, 1000)
            }
        }, 1000)
    }

    private fun stopTicker(state: String, message: String) {
        ticking = false
        handler.removeCallbacksAndMessages(null)
        emit(state, message, elapsedSeconds)
    }

    private fun emit(state: String, message: String, elapsed: Int) {
        handler.post {
            eventSink?.success(mapOf(
                "state" to state,
                "message" to message,
                "elapsedSeconds" to elapsed
            ))
        }
    }
}
