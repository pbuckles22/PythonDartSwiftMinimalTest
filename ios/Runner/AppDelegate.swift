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
      } else if call.method == "find5050Situations" {
        print("🔔 Swift: Calling PythonMinimalRunner.find5050Situations()")
        
        guard let args = call.arguments as? [String: Any],
              let probabilityMap = args["probabilityMap"] as? [String: Double] else {
          print("🔔 Swift: Invalid arguments for find5050Situations")
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for find5050Situations", details: nil))
          return
        }
        
        let value = PythonMinimalRunner.find5050Situations(probabilityMap: probabilityMap)
        print("🔔 Swift: PythonMinimalRunner returned: \(String(describing: value))")
        if let value = value {
          print("🔔 Swift: Sending 50/50 result back to Flutter: \(value)")
          result(value)
        } else {
          print("🔔 Swift: PythonMinimalRunner returned nil, sending error")
          result(FlutterError(code: "PYTHON_ERROR", message: "Failed to get 50/50 result from Python", details: nil))
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
