# Detailed Setup Guide: Embedding Python in Flutter iOS App

## Project Overview
This guide documents the complete process of embedding Python in a Flutter iOS app using Python-Apple-support and PythonKit.

## Current Status: ✅ FRAMEWORK SETUP COMPLETE
- ✅ Flutter project created and working
- ✅ Python-Apple-support extracted (`Python.xcframework` and `python-stdlib`)
- ✅ Python framework and stdlib copied to `ios/` directory
- ✅ Old Python implementation cleaned up
- ✅ Swift code updated to use embedded Python
- ❌ **NEXT**: Add PythonKit dependency and configure Xcode

## Step-by-Step Implementation

### Step 1: Project Setup ✅ COMPLETE
```bash
# Created Flutter project in root directory
flutter create .
flutter run  # Verified default app works
```

### Step 2: Extract Python-Apple-support ✅ COMPLETE
```bash
# Extract the downloaded Python-Apple-support
tar -xzf Python-3.14-iOS-support.b5.tar.gz
# This creates Python.xcframework/ with both device and simulator slices
```

### Step 3: Copy Python Framework and Stdlib ✅ COMPLETE
```bash
# Copy Python.xcframework to iOS project
cp -r Python.xcframework ios/

# Copy Python standard library
cp -r Python.xcframework/ios-arm64/lib/python3.14 ios/python-stdlib
```

### Step 4: Clean Up Old Implementation ✅ COMPLETE
```bash
# Remove old Python implementation
rm -rf ios/Runner/Resources/python
# Keep minimal.py and find_5050.py for future use
```

### Step 5: Update Swift Code ✅ COMPLETE
Updated `ios/Runner/PythonMinimalRunner.swift` to use embedded Python:
- Import PythonKit
- Initialize embedded Python using `PythonLibrary.use()`
- Set up environment variables (`PYTHONHOME`, `PYTHONPATH`)
- Import and call Python functions

## NEXT STEPS: Xcode Configuration

### Step 6: Add PythonKit Dependency (TODO)
**Method**: Swift Package Manager
1. Open `ios/Runner.xcworkspace` in Xcode
2. Go to Project Settings → Package Dependencies
3. Add package: `https://github.com/pvieito/PythonKit.git`
4. Select version: Latest release

### Step 7: Add Python Framework to Xcode (TODO)
1. In Xcode Project Navigator, right-click and "Add Files to Runner"
2. Select `ios/Python.xcframework`
3. Ensure "Add to target: Runner" is checked
4. In General tab → Frameworks, Libraries, and Embedded Content:
   - Set Python.xcframework to "Embed & Sign"

### Step 8: Add Python Stdlib to Xcode (TODO)
1. Right-click and "Add Files to Runner"
2. Select `ios/python-stdlib` folder
3. Choose "Create folder references" (blue folder)
4. Ensure "Add to target: Runner" is checked

### Step 9: Configure Build Settings (TODO)
1. Set "User Script Sandboxing" to "No"
2. Add `$(PROJECT_DIR)` to Framework Search Paths
3. Add code signing script for Python modules

### Step 10: Test Implementation (TODO)
1. Build and run on device
2. Verify Python initialization messages in console
3. Test button press calls Python function
4. Verify result is 2 (1+1)

## File Structure After Setup
```
/Users/chaos/dev/PythonDartSwiftMinimalTest/
├── ios/
│   ├── Python.xcframework/           ← Embedded Python framework
│   ├── python-stdlib/               ← Python standard library
│   ├── Runner/
│   │   ├── PythonMinimalRunner.swift  ← Updated Swift implementation
│   │   ├── AppDelegate.swift          ← MethodChannel setup
│   │   └── Resources/
│   │       └── minimal.py             ← Python script (1+1)
│   └── Runner.xcworkspace
├── lib/
│   └── main.dart                      ← Flutter UI
└── [other Flutter files]
```

## Debug Issues Encountered
See `BUILD_DEBUG_LOG.md` for detailed issues and solutions.

## Key Technical Details

### Python Framework Structure
```
Python.xcframework/
├── ios-arm64/                    ← Device binaries
│   ├── Python.framework/         ← Python interpreter
│   └── lib/python3.14/          ← Standard library
└── ios-arm64_x86_64-simulator/  ← Simulator binaries
```

### Swift Implementation
- Uses `PythonLibrary.use()` to initialize embedded Python
- Sets `PYTHONHOME` and `PYTHONPATH` environment variables
- Imports Python modules using `Python.import()`
- Converts Python results to Swift types

### Flutter Integration
- MethodChannel: `python/minimal`
- Method: `addOneAndOne`
- Returns: `NSNumber` (Int)

## Success Criteria
- [ ] App builds without errors
- [ ] Python initializes successfully (console messages)
- [ ] Button press calls Python function
- [ ] Result displays as "2" in Flutter UI
- [ ] Works on physical iOS device

## Next Actions
1. Add PythonKit via Swift Package Manager
2. Configure Xcode project settings
3. Test on device
4. Document any additional issues

---
*Last Updated: [Current Date]*
*Status: Framework setup complete, ready for Xcode configuration* 