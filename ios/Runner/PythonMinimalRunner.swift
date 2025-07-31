import Foundation
import PythonKit

@objc class PythonMinimalRunner: NSObject {
    // This closure will be executed lazily and thread-safely exactly once.
    private static let initializePython: () = {
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

        // 4. Initialize PythonKit
        print("🔍 Successfully initialized embedded PythonKit")
    }()
    
    // Shared Python environment setup function
    private static func setupPythonEnvironment() -> String? {
        print("🔍 PythonMinimalRunner: Setting up Python environment...")
        
        // First, set up the Python standard library path BEFORE importing sys
        let bundlePath = Bundle.main.bundlePath
        let pythonStdlibPath = bundlePath + "/python-stdlib"
        
        print("🔍 PythonMinimalRunner: Bundle path: \(bundlePath)")
        print("🔍 PythonMinimalRunner: Python stdlib path: \(pythonStdlibPath)")
        
        // Check if python-stdlib exists
        let stdlibExists = FileManager.default.fileExists(atPath: pythonStdlibPath)
        print("🔍 PythonMinimalRunner: Python stdlib exists: \(stdlibExists)")
        
        if stdlibExists {
            // Set the PYTHONPATH environment variable to include the stdlib
            setenv("PYTHONPATH", pythonStdlibPath, 1)
            print("🔍 PythonMinimalRunner: Set PYTHONPATH to: \(pythonStdlibPath)")
        }
        
        // Now try to import sys
        do {
            let sys = Python.import("sys")
            print("🔍 PythonMinimalRunner: Successfully imported sys")
            
            // Add the stdlib path to sys.path if it's not already there
            if stdlibExists && !Array(sys.path).contains(PythonObject(pythonStdlibPath)) {
                sys.path.insert(0, PythonObject(pythonStdlibPath))
                print("🔍 PythonMinimalRunner: Added stdlib to sys.path: \(pythonStdlibPath)")
            }
            
            // Now add the Resources directory for our custom modules
            let possiblePaths = [
                Bundle.main.path(forResource: "Resources", ofType: nil),
                Bundle.main.path(forResource: "Runner", ofType: nil)?.appending("/Resources"),
                Bundle.main.bundlePath.appending("/Runner/Resources"),
                Bundle.main.bundlePath.appending("/Resources"),
                Bundle.main.bundlePath.appending("/Frameworks/Runner.framework/Resources")
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
                    print("🔍 PythonMinimalRunner: Added Resources directory to sys.path: \(resourcePath)")
                }
                return resourcePath
            } else {
                print("❌ PythonMinimalRunner: Could not find Resources path. Tried:")
                for (i, path) in possiblePaths.enumerated() {
                    print("   \(i+1). \(path ?? "nil")")
                }
                
                // Fallback: search for Python files in the bundle
                print("🔍 PythonMinimalRunner: Trying fallback: searching for Python files in bundle...")
                let bundlePath = Bundle.main.bundlePath
                let fileManager = FileManager.default
                
                if let enumerator = fileManager.enumerator(atPath: bundlePath) {
                    for case let path as String in enumerator {
                        if path.hasSuffix("minimal.py") || path.hasSuffix("find_5050.py") {
                            let fullPath = bundlePath.appending("/\(path)")
                            let directory = fullPath.replacingOccurrences(of: "/\(path)", with: "")
                            print("🔍 PythonMinimalRunner: Found Python file at: \(fullPath)")
                            print("🔍 PythonMinimalRunner: Adding directory to sys.path: \(directory)")
                            sys.path.insert(0, PythonObject(directory))
                            return directory
                        }
                    }
                }
                
                print("❌ PythonMinimalRunner: Still could not find Python files in bundle")
                return nil
            }
        } catch {
            print("❌ PythonMinimalRunner: Failed to import sys: \(error)")
            return nil
        }
    }

    @objc static func addOneAndOne() -> NSNumber? {
        print("🔍 PythonMinimalRunner: Starting embedded Python test - UPDATED VERSION")
        
        // Trigger the one-time initialization by accessing the static property.
        // Swift ensures this is safe and only runs the closure once.
        _ = initializePython

        // ... (The rest of your function remains exactly the same)
        
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

        // Use shared Python environment setup
        guard let resourcePath = setupPythonEnvironment() else {
            print("❌ Could not set up Python environment")
            return nil
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
    
    @objc static func find5050Situations(inputData: [AnyHashable: Any], sensitivity: Double = 0.1) -> [[Int]]? {
        print("🔍 PythonMinimalRunner: Starting 50/50 detection")
        print("🔍 PythonMinimalRunner: Input data: \(inputData)")
        print("🔍 PythonMinimalRunner: Input data type: \(type(of: inputData))")
        print("🔍 PythonMinimalRunner: Input data count: \(inputData.count)")
        
        // Convert input data to proper format
        var convertedData: [String: Double] = [:]
        for (key, value) in inputData {
            if let stringKey = key as? String,
               let doubleValue = value as? Double {
                convertedData[stringKey] = doubleValue
            }
        }
        print("🔍 PythonMinimalRunner: Converted data: \(convertedData)")
        
        // Use embedded Python with simple detection (no numpy required)
        print("🔍 PythonMinimalRunner: Using embedded Python with simple detection...")
        
        // Check if we can access the find_5050.py file
        guard let resourcePath = Bundle.main.resourcePath else {
            print("❌ Could not get resource path")
            return nil
        }
        
        let find5050Path = resourcePath + "/find_5050.py"
        let fileExists = FileManager.default.fileExists(atPath: find5050Path)
        print("🔍 find_5050.py exists at \(find5050Path): \(fileExists)")
        
        if !fileExists {
            print("❌ find_5050.py not found")
            return nil
        }
        
        // Use PythonKit to import and run the simple detection
        do {
            // Use shared Python environment setup
            guard let _ = setupPythonEnvironment() else {
                print("❌ PythonMinimalRunner: Could not set up Python environment")
                return nil
            }
            
            // Import the find_5050 module
            print("🔍 PythonMinimalRunner: Importing find_5050 module...")
            let find5050Module = Python.import("find_5050")
            print("🔍 PythonMinimalRunner: Successfully imported find_5050 module")
            
            // Convert Swift dictionary to Python dictionary
            print("🔍 PythonMinimalRunner: Converting data for Python...")
            let pythonDict = PythonObject(convertedData)
            print("🔍 PythonMinimalRunner: Converted data: \(pythonDict)")
            
            // Call the simple detection function with sensitivity parameter
            print("🔍 PythonMinimalRunner: Calling find_5050_situations_simple with sensitivity: \(sensitivity)...")
            let result = find5050Module.find_5050_situations_simple(pythonDict, sensitivity)
            print("🔍 PythonMinimalRunner: Python result: \(result)")
            
            // Convert Python result to Swift with better error handling
            print("🔍 PythonMinimalRunner: Raw Python result type: \(type(of: result))")
            print("🔍 PythonMinimalRunner: Raw Python result: \(result)")
            
            // Try to convert the Python result safely
            do {
                // First try: direct conversion to Array<Array<Int>>
                if let resultArray = Array<Array<Int>>(result) {
                    print("🔍 PythonMinimalRunner: Successfully converted to Array<Array<Int>>: \(resultArray)")
                    return resultArray
                }
                
                // Second try: convert as flat array and then to pairs
                if let flatArray = Array<Int>(result) {
                    print("🔍 PythonMinimalRunner: Got flat array: \(flatArray)")
                    
                    // Convert flat array to pairs: [r1, c1, r2, c2, ...] -> [[r1, c1], [r2, c2], ...]
                    var pairs: [[Int]] = []
                    for i in stride(from: 0, to: flatArray.count, by: 2) {
                        if i + 1 < flatArray.count {
                            pairs.append([flatArray[i], flatArray[i + 1]])
                        }
                    }
                    print("🔍 PythonMinimalRunner: Converted to pairs: \(pairs)")
                    return pairs
                }
                
                // Third try: manual iteration if other methods fail
                print("🔍 PythonMinimalRunner: Trying manual iteration...")
                var manualResult: [[Int]] = []
                let pythonList = PythonObject(result)
                let length = Int(pythonList.__len__()) ?? 0
                print("🔍 PythonMinimalRunner: Manual iteration length: \(length)")
                
                for i in 0..<length {
                    let item = pythonList[i]
                    print("🔍 PythonMinimalRunner: Item \(i): \(item), type: \(type(of: item))")
                    
                    if let itemArray = Array<Int>(item) {
                        manualResult.append(itemArray)
                    }
                }
                
                print("🔍 PythonMinimalRunner: Manual conversion result: \(manualResult)")
                return manualResult
                
            } catch {
                print("❌ PythonMinimalRunner: Error during conversion: \(error)")
                return nil
            }
            
            print("❌ PythonMinimalRunner: All conversion attempts failed")
            return nil
            
        } catch {
            print("❌ PythonMinimalRunner: Error using PythonKit: \(error)")
            return nil
        }
    }
}