# PythonKit iOS Bundling Guide

This guide shows how to properly bundle Python with your iOS app using PythonKit, making it completely self-contained without relying on system Python installations.

## Overview

The goal is to embed a complete Python runtime within your iOS app bundle, so it works reliably for all users without any external setup or environment variables.

## Current State Analysis

From the FlutterMinesweeper project, I can see:
- ✅ Python-Apple-support framework is available (`Python.xcframework`)
- ✅ Python standard library is bundled (`python3.14` directory)
- ❌ Framework is not properly integrated into the main iOS project
- ❌ Current implementation relies on environment variables and system paths

## Step-by-Step Integration Guide

### 1. Copy Python Framework to iOS Project

```bash
# Copy the Python.xcframework to your iOS project
cp -r /Users/chaos/dev/FlutterMinesweeper/python_minimal_test/Python.xcframework /Users/chaos/dev/FlutterMinesweeper/ios/
```

### 2. Xcode Integration

1. **Open your project in Xcode**
   - Open `ios/Runner.xcworkspace` (not `.xcodeproj`)

2. **Add Python.xcframework to your project**
   - Right-click in the Xcode project navigator
   - Select **Add Files to "Runner"**
   - Navigate to `ios/Python.xcframework`
   - Make sure **Add to target: Runner** is checked
   - Click **Add**

3. **Embed the Python framework**
   - Select the **Runner** target
   - Go to the **General** tab
   - Under **Frameworks, Libraries, and Embedded Content**:
     - Find `Python.xcframework`
     - Set **Embed** to **Embed & Sign**

4. **Add the Python standard library**
   - Right-click your project in the navigator and choose **Add Files to "Runner"**
   - Select the folder `ios/Python.xcframework/ios-arm64/lib/python3.14`
   - Choose **Create folder references** (so it appears as a blue folder)
   - Make sure **Add to targets: Runner** is checked
   - Rename the folder in Xcode to `python-stdlib` for clarity

### 3. Configure Build Settings

1. **User Script Sandboxing**
   - Set **User Script Sandboxing** to **No** (in Build Settings > Build Options)

2. **Framework Search Paths**
   - Add `$(PROJECT_DIR)` to **Framework Search Paths** (if not already present)

### 4. Add Code Signing for Python Modules

1. Go to **Build Phases** for the Runner target
2. Add a new **Run Script Phase** (before "Embed Frameworks")
3. Paste the following script:

```bash
set -e
echo "Signing embedded Python modules..."
find "$CODESIGNING_FOLDER_PATH/python-stdlib/lib-dynload" -name "*.so" -exec /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" --timestamp=none --preserve-metadata=identifier,entitlements,flags {} \;
```

### 5. Update Swift Implementation

Replace the current Python initialization code with this embedded version:

```swift
import Foundation
import PythonKit

@objc class Python5050Solver: NSObject {
    private static var isInitialized = false

    private static func initializeEmbeddedPython() {
        guard !isInitialized else { return }

        // 1. Find the path to the bundled python-stdlib
        guard let stdLibPath = Bundle.main.path(forResource: "python-stdlib", ofType: nil) else {
            fatalError("Could not find python-stdlib in app bundle!")
        }
        print("🔍 Found python-stdlib at: \(stdLibPath)")

        // 2. Find the path to the embedded Python framework
        let pythonFrameworkPath = Bundle.main.bundlePath + "/Frameworks/Python.framework/Python"
        guard FileManager.default.fileExists(atPath: pythonFrameworkPath) else {
            fatalError("Python dynamic library not found at expected path: \(pythonFrameworkPath)")
        }
        print("🔍 Found Python.framework at: \(pythonFrameworkPath)")

        // 3. Set environment variables for embedded Python
        setenv("PYTHONHOME", stdLibPath, 1)
        setenv("PYTHONPATH", stdLibPath, 1)
        print("🔍 Set PYTHONHOME and PYTHONPATH to embedded paths")

        // 4. Tell PythonKit to use the embedded Python
        do {
            PythonLibrary.use(pathToPythonLibrary: pythonFrameworkPath)
            print("🔍 Successfully initialized embedded PythonKit")
        } catch {
            fatalError("Failed to initialize PythonKit: \(error.localizedDescription)")
        }

        isInitialized = true
    }

    @objc static func find5050(withProbabilityMap probabilityMap: [String: Double]) -> [[Int]] {
        print("🔍 Python5050Solver: Starting 50/50 detection")
        print("🔍 Input map: \(probabilityMap)")

        // Initialize embedded Python if not already done
        initializeEmbeddedPython()

        // Set up Python path to include the bundled Python files
        let sys = Python.import("sys")
        if let resourcePath = Bundle.main.path(forResource: "Python", ofType: nil) {
            if !Array(sys.path).contains(PythonObject(resourcePath)) {
                sys.path.insert(0, PythonObject(resourcePath))
                print("🔍 Added custom Python scripts to sys.path")
            }
        } else {
            print("❌ Could not find Python resource path")
            return []
        }

        // Import the Python module and call the function
        let pyModule = Python.import("core.probabilistic_guesser")
        let pyResult = pyModule.find_5050_situations_from_dict(probabilityMap)

        // Convert the Python result to a Swift array
        if let swiftCells = Array(pyResult) as? [[Int]] {
            print("✅ Success: \(swiftCells)")
            return swiftCells
        } else {
            print("❌ Failed to parse Python result")
            return []
        }
    }
}
```

### 6. Update AppDelegate.swift

Update your AppDelegate to use the embedded Python:

```swift
import Flutter
import UIKit
import PythonKit
import Foundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let solverChannel = FlutterMethodChannel(name: "minesweeper/solver",
                                             binaryMessenger: controller.binaryMessenger)

    solverChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "find5050" {
        guard let args = call.arguments as? [String: Any],
              let probabilityMap = args["probabilityMap"] as? [String: Double] else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing probabilityMap", details: nil))
          return
        }
        
        // Use the embedded Python solver
        let result = Python5050Solver.find5050(withProbabilityMap: probabilityMap)
        result(result)
      } else {
        result(FlutterError(code: "NOT_IMPLEMENTED", message: "Method not implemented", details: nil))
      }
    })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## Key Differences from Current Implementation

1. **No System Dependencies**: The embedded version doesn't rely on `PYTHON_LIBRARY` environment variables
2. **Self-Contained**: All Python components are bundled within the app
3. **Proper Path Resolution**: Uses `Bundle.main` to locate embedded resources
4. **Code Signing**: Python modules are properly signed for App Store distribution

## Verification Steps

1. **Clean Build**: In Xcode, select **Product > Clean Build Folder**
2. **Build and Run**: Test on both simulator and device
3. **Check Bundle**: Verify Python.xcframework and python-stdlib are in the app bundle
4. **Test Functionality**: Ensure your Python code runs without environment setup

## Troubleshooting

### Common Issues

1. **"Could not find python-stdlib"**
   - Ensure the python-stdlib folder is added as a blue folder reference
   - Check that it's included in "Copy Bundle Resources"

2. **"Python dynamic library not found"**
   - Verify Python.xcframework is properly embedded
   - Check the framework search paths

3. **Code signing errors**
   - Ensure the Python modules signing script runs before "Embed Frameworks"
   - Check that all .so files are properly signed

### Debug Tips

- Add print statements to verify paths are correct
- Check the app bundle contents after building
- Use Xcode's console to see Python initialization messages

## Benefits of This Approach

1. **Reliability**: Works consistently across all devices
2. **Distribution**: No external dependencies for end users
3. **App Store Compatible**: Properly signed and sandboxed
4. **Version Control**: You control exactly which Python version is used
5. **Performance**: No need to search system paths

This approach ensures your app is completely self-contained and will work reliably for all users without any external Python setup requirements. 