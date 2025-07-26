import Foundation
import PythonKit

@objc class PythonMinimalRunner: NSObject {
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

        // 4. Initialize PythonKit (no need to specify library path in newer versions)
        print("🔍 Successfully initialized embedded PythonKit")

        isInitialized = true
    }

    @objc static func addOneAndOne() -> NSNumber? {
        print("🔍 PythonMinimalRunner: Starting embedded Python test - UPDATED VERSION")
        
        // Initialize embedded Python if not already done
        initializeEmbeddedPython()

        // First, let's check what's actually in the bundle
        print("🔍 Checking bundle contents...")
        let bundlePath = Bundle.main.bundlePath
        let fileManager = FileManager.default
        
        if let enumerator = fileManager.enumerator(atPath: bundlePath) {
            var foundMinimal = false
            for case let path as String in enumerator {
                if path.hasSuffix("minimal.py") {
                    print("🔍 Found minimal.py at: \(path)")
                    foundMinimal = true
                    break
                }
            }
            if !foundMinimal {
                print("❌ minimal.py not found in bundle!")
            }
        }

        // Set up Python path to include the bundled Python files
        let sys = Python.import("sys")
        
        // Try multiple possible paths for the Resources directory
        let possiblePaths = [
            Bundle.main.path(forResource: "Resources", ofType: nil),
            Bundle.main.path(forResource: "Runner", ofType: nil)?.appending("/Resources"),
            Bundle.main.bundlePath.appending("/Runner/Resources"),
            Bundle.main.bundlePath.appending("/Resources")
        ]
        
        var resourcePath: String? = nil
        for path in possiblePaths {
            if let path = path, FileManager.default.fileExists(atPath: path) {
                resourcePath = path
                break
            }
        }
        
        if let resourcePath = resourcePath {
            if !Array(sys.path).contains(PythonObject(resourcePath)) {
                sys.path.insert(0, PythonObject(resourcePath))
                print("🔍 Added Resources directory to sys.path: \(resourcePath)")
            }
        } else {
            print("❌ Could not find Resources path. Tried:")
            for (i, path) in possiblePaths.enumerated() {
                print("   \(i+1). \(path ?? "nil")")
            }
            
            // Fallback: try to find minimal.py directly in the bundle
            print("🔍 Trying fallback: searching for minimal.py in bundle...")
            
            if let enumerator = fileManager.enumerator(atPath: bundlePath) {
                for case let path as String in enumerator {
                    if path.hasSuffix("minimal.py") {
                        let fullPath = bundlePath.appending("/\(path)")
                        let directory = fullPath.replacingOccurrences(of: "/minimal.py", with: "")
                        print("🔍 Found minimal.py at: \(fullPath)")
                        print("🔍 Adding directory to sys.path: \(directory)")
                        sys.path.insert(0, PythonObject(directory))
                        resourcePath = directory
                        break
                    }
                }
            }
            
            if resourcePath == nil {
                print("❌ Still could not find minimal.py in bundle")
                return nil
            }
        }

        // Import the minimal module and call the function
        print("🔍 Attempting to import minimal module...")
        let pyModule = Python.import("minimal")
        print("🔍 Successfully imported minimal module")
        
        print("🔍 Calling add_one_and_one()...")
        let pyResult = pyModule.add_one_and_one()
        print("🔍 Got result from Python: \(pyResult)")
        
        let result = Int(pyResult) ?? 0  // Provide default value if conversion fails
        print("✅ Successfully got result from Python: \(result)")
        return NSNumber(value: result)
    }
}