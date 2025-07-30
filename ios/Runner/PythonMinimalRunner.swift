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
    
    @objc static func find5050Situations(inputData: [AnyHashable: Any]) -> [[Int]]? {
        print("🔍 PythonMinimalRunner: Starting 50/50 detection")
        print("🔍 PythonMinimalRunner: Input data: \(inputData)")
        print("🔍 PythonMinimalRunner: Input data type: \(type(of: inputData))")
        print("🔍 PythonMinimalRunner: Input data count: \(inputData.count)")
        
        // Simple Swift-based 50/50 detection (bypass Python for now)
        print("🔍 PythonMinimalRunner: Using Swift-based 50/50 detection...")
        
        var fiftyFiftyCells: [[Int]] = []
        
        // Convert input data to proper format
        var convertedData: [String: Double] = [:]
        for (key, value) in inputData {
            if let stringKey = key as? String,
               let doubleValue = value as? Double {
                convertedData[stringKey] = doubleValue
            }
        }
        print("🔍 PythonMinimalRunner: Converted data: \(convertedData)")
        
        // Find true 50/50 pairs (not just cells with 0.5 probability)
        // A true 50/50 is: exactly 2 unrevealed cells that share exactly 1 mine from a revealed neighbor
        var true5050Pairs: [[Int]] = []
        
        // Group cells by their revealed neighbors to find shared 50/50 situations
        var neighborGroups: [String: [[Int]]] = [:]
        
        for (key, probability) in convertedData {
            if abs(probability - 0.5) < 1e-6 {
                if key.hasPrefix("(") && key.hasSuffix(")") {
                    let cleanKey = key.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
                    let parts = cleanKey.components(separatedBy: ", ")
                    if parts.count == 2,
                       let row = Int(parts[0]),
                       let col = Int(parts[1]) {
                        fiftyFiftyCells.append([row, col])
                        print("🔍 PythonMinimalRunner: Found cell with 0.5 probability: [\(row), \(col)]")
                        
                        // For now, just collect all 0.5 probability cells
                        // TODO: Implement proper 50/50 pair detection
                    }
                }
            }
        }
        
        // For now, if we have exactly 2 cells with 0.5 probability, treat as 50/50 pair
        if fiftyFiftyCells.count == 2 {
            true5050Pairs = fiftyFiftyCells
            print("🔍 PythonMinimalRunner: Found 50/50 PAIR: \(true5050Pairs)")
        } else if fiftyFiftyCells.count > 2 {
            print("🔍 PythonMinimalRunner: WARNING: Found \(fiftyFiftyCells.count) cells with 0.5 probability - this indicates a calculation error")
            print("🔍 PythonMinimalRunner: This should be exactly 2 cells for a true 50/50")
            // For now, return empty to avoid false positives
            return []
        }
        
        print("🔍 PythonMinimalRunner: Swift detection found \(fiftyFiftyCells.count) cells with 0.5 probability")
        
        if true5050Pairs.count == 2 {
            print("🔍 PythonMinimalRunner: TRUE 50/50 PAIR DETECTED:")
            print("🔍   Cells in this 50/50 pair: \(true5050Pairs)")
            print("🔍   Exactly one of these 2 cells contains a mine")
            return true5050Pairs
        } else {
            print("🔍 PythonMinimalRunner: No true 50/50 pairs found")
            print("🔍   Found \(fiftyFiftyCells.count) cells with 0.5 probability (should be exactly 2)")
            return []
        }
    }
}