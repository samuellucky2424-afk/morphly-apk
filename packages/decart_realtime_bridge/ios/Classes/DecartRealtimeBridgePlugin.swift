import Flutter
import UIKit

public class DecartRealtimeBridgePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var timer: Timer?
  private var elapsedSeconds = 0

  public static func register(with registrar: FlutterPluginRegistrar) {
    let methods = FlutterMethodChannel(
      name: "morphly/decart_realtime/methods",
      binaryMessenger: registrar.messenger()
    )
    let events = FlutterEventChannel(
      name: "morphly/decart_realtime/events",
      binaryMessenger: registrar.messenger()
    )
    let instance = DecartRealtimeBridgePlugin()
    registrar.addMethodCallDelegate(instance, channel: methods)
    events.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startSession":
      guard
        let args = call.arguments as? [String: Any],
        let token = args["clientToken"] as? String,
        let model = args["model"] as? String,
        !token.isEmpty,
        !model.isEmpty
      else {
        emit(state: "failed", message: "Missing Decart token or model.", elapsed: elapsedSeconds)
        result(FlutterError(code: "invalid_args", message: "Missing Decart token or model.", details: nil))
        return
      }

      // Production hook:
      // 1. Add https://github.com/decartai/decart-ios.git in Xcode Swift Package Manager.
      // 2. Initialize DecartClient with this short-lived token.
      // 3. Connect the camera track, reference image, and prompt to Lucy realtime.
      // 4. Render the remote stream through a Flutter PlatformView.
      emit(state: "starting", message: "Connecting to Decart.", elapsed: 0)
      startTicker(message: (args["prompt"] as? String) ?? "Morphly realtime session")
      result(nil)
    case "setPrompt":
      let args = call.arguments as? [String: Any]
      let prompt = args?["prompt"] as? String ?? ""
      emit(state: "connected", message: "Prompt updated: \(prompt)", elapsed: elapsedSeconds)
      result(nil)
    case "stopSession":
      stopTicker(state: "stopped", message: "Session stopped.")
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    emit(state: "idle", message: "Ready.", elapsed: 0)
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func startTicker(message: String) {
    stopTicker(state: "starting", message: message)
    elapsedSeconds = 0
    emit(state: "connected", message: message, elapsed: elapsedSeconds)
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      guard let self else { return }
      self.elapsedSeconds += 1
      self.emit(state: "connected", message: "Live morphing.", elapsed: self.elapsedSeconds)
    }
  }

  private func stopTicker(state: String, message: String) {
    timer?.invalidate()
    timer = nil
    emit(state: state, message: message, elapsed: elapsedSeconds)
  }

  private func emit(state: String, message: String, elapsed: Int) {
    eventSink?([
      "state": state,
      "message": message,
      "elapsedSeconds": elapsed
    ])
  }
}
