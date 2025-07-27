import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
               let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
           let pythonChannel = FlutterMethodChannel(name: "python/minimal",
                                                    binaryMessenger: controller.binaryMessenger)

           pythonChannel.setMethodCallHandler({
             (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
             print("🔔 Swift: MethodChannel received call: \(call.method)")
             if call.method == "addOneAndOne" {
               print("🔔 Swift: Calling PythonMinimalRunner.addOneAndOne()")
               
               let value = PythonMinimalRunner.addOneAndOne()
        print("🔔 Swift: PythonMinimalRunner returned: \(String(describing: value))")
        if let value = value {
          print("🔔 Swift: Sending result back to Flutter: \(value)")
          result(value)
        } else {
          print("🔔 Swift: PythonMinimalRunner returned nil, sending error")
          result(FlutterError(code: "PYTHON_ERROR", message: "Failed to get result from Python", details: nil))
        }
      } else {
        print("🔔 Swift: Unknown method: \(call.method)")
        result(FlutterError(code: "UNSUPPORTED_METHOD", message: "Method \(call.method) not implemented", details: nil))
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}