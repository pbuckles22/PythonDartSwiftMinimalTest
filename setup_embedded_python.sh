#!/bin/bash

# Setup Embedded Python for FlutterMinesweeper iOS Project
# This script automates the process of integrating Python-Apple-support into your iOS app

set -e  # Exit on any error

echo "🔧 Setting up Embedded Python for FlutterMinesweeper iOS Project"
echo "================================================================"

# Define paths
FLUTTER_PROJECT="/Users/chaos/dev/FlutterMinesweeper"
PYTHON_FRAMEWORK_SOURCE="$FLUTTER_PROJECT/python_minimal_test/Python.xcframework"
PYTHON_FRAMEWORK_DEST="$FLUTTER_PROJECT/ios/Python.xcframework"
IOS_PROJECT="$FLUTTER_PROJECT/ios"

echo "📁 Checking project structure..."

# Check if source Python framework exists
if [ ! -d "$PYTHON_FRAMEWORK_SOURCE" ]; then
    echo "❌ Error: Python.xcframework not found at $PYTHON_FRAMEWORK_SOURCE"
    echo "   Please ensure you have the Python-Apple-support framework downloaded"
    exit 1
fi

# Check if iOS project exists
if [ ! -d "$IOS_PROJECT" ]; then
    echo "❌ Error: iOS project not found at $IOS_PROJECT"
    exit 1
fi

echo "✅ Project structure verified"

# Step 1: Copy Python framework to iOS project
echo ""
echo "📦 Step 1: Copying Python.xcframework to iOS project..."

if [ -d "$PYTHON_FRAMEWORK_DEST" ]; then
    echo "   Removing existing Python.xcframework..."
    rm -rf "$PYTHON_FRAMEWORK_DEST"
fi

echo "   Copying Python.xcframework..."
cp -r "$PYTHON_FRAMEWORK_SOURCE" "$PYTHON_FRAMEWORK_DEST"
echo "✅ Python.xcframework copied successfully"

# Step 2: Create updated Swift files
echo ""
echo "📝 Step 2: Creating updated Swift implementation files..."

# Create the updated Python5050Solver.swift
cat > "$FLUTTER_PROJECT/ios/Runner/Python5050Solver_Embedded.swift" << 'EOF'
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
EOF

# Create the updated AppDelegate.swift
cat > "$FLUTTER_PROJECT/ios/Runner/AppDelegate_Embedded.swift" << 'EOF'
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
        let solverResult = Python5050Solver.find5050(withProbabilityMap: probabilityMap)
        result(solverResult)
      } else {
        result(FlutterError(code: "NOT_IMPLEMENTED", message: "Method not implemented", details: nil))
      }
    })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
EOF

echo "✅ Updated Swift files created"

# Step 3: Create Xcode build script for code signing
echo ""
echo "🔐 Step 3: Creating code signing script..."

cat > "$FLUTTER_PROJECT/ios/sign_python_modules.sh" << 'EOF'
#!/bin/bash
set -e
echo "Signing embedded Python modules..."
find "$CODESIGNING_FOLDER_PATH/python-stdlib/lib-dynload" -name "*.so" -exec /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" --timestamp=none --preserve-metadata=identifier,entitlements,flags {} \;
echo "✅ Python modules signed successfully"
EOF

chmod +x "$FLUTTER_PROJECT/ios/sign_python_modules.sh"
echo "✅ Code signing script created"

# Step 4: Create Xcode project configuration guide
echo ""
echo "📋 Step 4: Creating Xcode configuration guide..."

cat > "$FLUTTER_PROJECT/ios/XCODE_SETUP_GUIDE.md" << 'EOF'
# Xcode Setup Guide for Embedded Python

Follow these steps in Xcode to complete the embedded Python integration:

## 1. Open Project
- Open `ios/Runner.xcworkspace` in Xcode (not `.xcodeproj`)

## 2. Add Python.xcframework
- Right-click in the Xcode project navigator
- Select **Add Files to "Runner"**
- Navigate to `ios/Python.xcframework`
- Make sure **Add to target: Runner** is checked
- Click **Add**

## 3. Embed Python Framework
- Select the **Runner** target
- Go to the **General** tab
- Under **Frameworks, Libraries, and Embedded Content**:
  - Find `Python.xcframework`
  - Set **Embed** to **Embed & Sign**

## 4. Add Python Standard Library
- Right-click your project in the navigator and choose **Add Files to "Runner"**
- Select the folder `ios/Python.xcframework/ios-arm64/lib/python3.14`
- Choose **Create folder references** (so it appears as a blue folder)
- Make sure **Add to targets: Runner** is checked
- Rename the folder in Xcode to `python-stdlib` for clarity

## 5. Configure Build Settings
- Set **User Script Sandboxing** to **No** (in Build Settings > Build Options)
- Add `$(PROJECT_DIR)` to **Framework Search Paths** (if not already present)

## 6. Add Code Signing Script
- Go to **Build Phases** for the Runner target
- Add a new **Run Script Phase** (before "Embed Frameworks")
- Set the script to: `"${PROJECT_DIR}/sign_python_modules.sh"`

## 7. Update Swift Files
- Replace the contents of `AppDelegate.swift` with `AppDelegate_Embedded.swift`
- Replace the contents of `Python5050Solver.swift` with `Python5050Solver_Embedded.swift`

## 8. Clean and Build
- In Xcode, select **Product > Clean Build Folder**
- Build and run your app

## Verification
- Check that Python.xcframework and python-stdlib are in the app bundle
- Verify Python initialization messages appear in the console
- Test your Python functionality works without environment setup
EOF

echo "✅ Xcode setup guide created"

# Step 5: Create verification script
echo ""
echo "🔍 Step 5: Creating verification script..."

cat > "$FLUTTER_PROJECT/ios/verify_setup.sh" << 'EOF'
#!/bin/bash

echo "🔍 Verifying Embedded Python Setup"
echo "=================================="

# Check if Python.xcframework exists
if [ -d "Python.xcframework" ]; then
    echo "✅ Python.xcframework found"
else
    echo "❌ Python.xcframework not found"
fi

# Check if python-stdlib exists
if [ -d "Python.xcframework/ios-arm64/lib/python3.14" ]; then
    echo "✅ Python standard library found"
else
    echo "❌ Python standard library not found"
fi

# Check if signing script exists
if [ -f "sign_python_modules.sh" ]; then
    echo "✅ Code signing script found"
else
    echo "❌ Code signing script not found"
fi

# Check if updated Swift files exist
if [ -f "Runner/Python5050Solver_Embedded.swift" ]; then
    echo "✅ Updated Python5050Solver found"
else
    echo "❌ Updated Python5050Solver not found"
fi

if [ -f "Runner/AppDelegate_Embedded.swift" ]; then
    echo "✅ Updated AppDelegate found"
else
    echo "❌ Updated AppDelegate not found"
fi

echo ""
echo "📋 Next Steps:"
echo "1. Open ios/Runner.xcworkspace in Xcode"
echo "2. Follow the instructions in XCODE_SETUP_GUIDE.md"
echo "3. Clean and build your project"
echo "4. Test on both simulator and device"
EOF

chmod +x "$FLUTTER_PROJECT/ios/verify_setup.sh"
echo "✅ Verification script created"

echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo ""
echo "✅ Python.xcframework copied to iOS project"
echo "✅ Updated Swift implementation files created"
echo "✅ Code signing script created"
echo "✅ Xcode setup guide created"
echo "✅ Verification script created"
echo ""
echo "📋 Next Steps:"
echo "1. Run: cd $IOS_PROJECT && ./verify_setup.sh"
echo "2. Open ios/Runner.xcworkspace in Xcode"
echo "3. Follow the instructions in XCODE_SETUP_GUIDE.md"
echo "4. Clean and build your project"
echo ""
echo "🔧 The embedded Python setup is now ready for Xcode integration!" 