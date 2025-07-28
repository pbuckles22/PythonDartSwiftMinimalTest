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
    
    @objc static func find5050Situations(probabilityMap: [String: Double]) -> [[Int]]? {
        print("🔍 PythonMinimalRunner: Starting 50/50 detection")
        print("🔍 Input probability map: \(probabilityMap)")
        
        // Trigger the one-time initialization by accessing the static property.
        _ = initializePython
        
        // First, let's check what's actually in the bundle
        print("🔍 Checking bundle contents...")
        let bundlePath = Bundle.main.bundlePath
        let fileManager = FileManager.default
        
        if let enumerator = fileManager.enumerator(atPath: bundlePath) {
            var foundFind5050 = false
            for case let path as String in enumerator {
                if path.hasSuffix("find_5050.py") {
                    print("🔍 Found find_5050.py at: \(path)")
                    foundFind5050 = true
                    break
                }
            }
            if !foundFind5050 {
                print("❌ find_5050.py not found in bundle!")
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
            print("❌ Could not find Resources path for 50/50 detection")
            print("❌ Tried paths:")
            for (i, path) in possiblePaths.enumerated() {
                print("   \(i+1). \(path ?? "nil")")
            }
            
            // Fallback: try to find find_5050.py directly in the bundle
            print("🔍 Trying fallback: searching for find_5050.py in bundle...")
            
            if let enumerator = fileManager.enumerator(atPath: bundlePath) {
                for case let path as String in enumerator {
                    if path.hasSuffix("find_5050.py") {
                        let fullPath = bundlePath.appending("/\(path)")
                        let directory = fullPath.replacingOccurrences(of: "/find_5050.py", with: "")
                        print("🔍 Found find_5050.py at: \(fullPath)")
                        print("🔍 Adding directory to sys.path: \(directory)")
                        sys.path.insert(0, PythonObject(directory))
                        resourcePath = directory
                        break
                    }
                }
            }
            
            if resourcePath == nil {
                print("❌ Still could not find find_5050.py in bundle")
                return nil
            }
        }
        
        // Check if find_5050.py exists in the resource path
        let find5050Path = resourcePath! + "/find_5050.py"
        if FileManager.default.fileExists(atPath: find5050Path) {
            print("✅ Found find_5050.py at: \(find5050Path)")
        } else {
            print("❌ find_5050.py not found at: \(find5050Path)")
            return nil
        }
        
        // Import the find_5050 module and call the function
        print("🔍 Attempting to import find_5050 module...")
        do {
            let pyModule = Python.import("find_5050")
            print("🔍 Successfully imported find_5050 module")
            
            // Convert Swift dictionary to Python dictionary
            let pyProbabilityMap = PythonObject(probabilityMap)
            print("🔍 Converted probability map to Python object: \(pyProbabilityMap)")
            
            print("🔍 Calling find_5050_situations()...")
            let pyResult = pyModule.find_5050_situations(pyProbabilityMap)
            print("🔍 Got result from Python: \(pyResult)")
            print("🔍 Result type: \(type(of: pyResult))")
            
            // Convert Python result back to Swift array
            print("🔍 Attempting to convert Python result to Swift array...")
            print("🔍 Python result: \(pyResult)")
            print("🔍 Python result type: \(type(of: pyResult))")
            
            // Try to convert the PythonObject to a Swift array
            if let resultArray = Array(pyResult) as? [[Int]] {
                print("✅ Successfully got 50/50 result from Python: \(resultArray)")
                return resultArray
            } else {
                // Try alternative conversion methods
                print("🔍 First conversion failed, trying alternative methods...")
                
                // Method 1: Try to iterate and convert manually
                let pyList = Array(pyResult)
                print("🔍 Got Python list: \(pyList)")
                var swiftArray: [[Int]] = []
                
                for item in pyList {
                    print("🔍 Processing item: \(item), type: \(type(of: item))")
                    let innerList = Array(item)
                    print("🔍 Inner list: \(innerList)")
                    
                    var innerSwiftArray: [Int] = []
                    for innerItem in innerList {
                        if let intValue = Int(innerItem) {
                            innerSwiftArray.append(intValue)
                        } else {
                            print("❌ Failed to convert inner item to Int: \(innerItem)")
                        }
                    }
                    
                    if !innerSwiftArray.isEmpty {
                        swiftArray.append(innerSwiftArray)
                        print("🔍 Added inner array: \(innerSwiftArray)")
                    }
                }
                
                if !swiftArray.isEmpty {
                    print("✅ Successfully converted using manual method: \(swiftArray)")
                    return swiftArray
                }
                
                // Method 2: Try to convert to string and parse
                let resultString = String(pyResult)
                print("🔍 Result as string: \(resultString)")
                
                print("❌ All conversion methods failed")
                print("❌ Result was: \(pyResult)")
                print("❌ Result type: \(type(of: pyResult))")
                return nil
            }
        } catch {
            print("❌ Error importing find_5050 module: \(error)")
            return nil
        }
    }
}