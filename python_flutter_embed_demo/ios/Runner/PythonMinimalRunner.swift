import Foundation

@objc class PythonMinimalRunner: NSObject {
    
    @objc static func addOneAndOne() -> NSNumber? {
        print("🔍 PythonMinimalRunner: Starting subprocess call")
        
        // Path to our Python script in the app bundle
        guard let scriptPath = Bundle.main.path(forResource: "minimal", ofType: "py") else {
            print("❌ Could not find minimal.py in app bundle")
            return nil
        }
        
        print("🔍 Found script at: \(scriptPath)")
        
        // Create a Process to run Python
        let process = Process()
        
        // Use system Python (or we can embed Python executable later)
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        
        // Arguments: python script path
        process.arguments = [scriptPath]
        
        // Set up pipes for communication
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            print("🔍 Starting Python subprocess...")
            try process.run()
            process.waitUntilExit()
            
            // Read the output
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""
            
            // Read any error output
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
            
            print("🔍 Python output: \(output)")
            if !errorOutput.isEmpty {
                print("🔍 Python error: \(errorOutput)")
            }
            
            // Parse the result (assuming Python prints the number)
            if let result = Int(output.trimmingCharacters(in: .whitespacesAndNewlines)) {
                print("✅ Successfully got result: \(result)")
                return NSNumber(value: result)
            } else {
                print("❌ Could not parse result from output: '\(output)'")
                return nil
            }
            
        } catch {
            print("❌ Error running Python subprocess: \(error)")
            return nil
        }
    }
}