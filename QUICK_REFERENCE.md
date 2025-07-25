# 🐍 PythonKit iOS Bundling - Quick Reference

## The Goal
Bundle Python with your iOS app so it runs without system dependencies or environment variables.

## Current Problem
- Relies on `PYTHON_LIBRARY` environment variable
- Needs user's system Python installation
- Fragile and hard to distribute

## Solution: Embedded Python
Bundle complete Python runtime within your app bundle.

## Key Files Created
- `setup_embedded_python.sh` - Automated setup script
- `README.md` - Complete implementation guide
- `IMPLEMENTATION_SUMMARY.md` - Technical overview
- `QUICK_REFERENCE.md` - This file

## Quick Setup Commands

```bash
# 1. Run the setup script
./setup_embedded_python.sh

# 2. Verify setup
cd /Users/chaos/dev/FlutterMinesweeper/ios && ./verify_setup.sh

# 3. Open in Xcode
open /Users/chaos/dev/FlutterMinesweeper/ios/Runner.xcworkspace
```

## Xcode Steps (After Running Script)
1. Add `Python.xcframework` to project
2. Set Embed to "Embed & Sign"
3. Add `python-stdlib` as blue folder reference
4. Set "User Script Sandboxing" to "No"
5. Add code signing script to Build Phases
6. Replace Swift files with embedded versions

## Key Technical Changes

### Before (System Python)
```swift
setenv("PYTHON_LIBRARY", "/usr/lib/libpython3.14.dylib", 1)
PythonLibrary.use(path: "/usr/lib/libpython3.14.dylib")
```

### After (Embedded Python)
```swift
let stdLibPath = Bundle.main.path(forResource: "python-stdlib", ofType: nil)
let pythonFrameworkPath = Bundle.main.bundlePath + "/Frameworks/Python.framework/Python"
setenv("PYTHONHOME", stdLibPath, 1)
PythonLibrary.use(pathToPythonLibrary: pythonFrameworkPath)
```

## Benefits
- ✅ No system dependencies
- ✅ App Store compatible
- ✅ Works immediately after install
- ✅ Version controlled
- ✅ Properly code-signed

## Troubleshooting
- **"Could not find python-stdlib"** → Check blue folder reference in Xcode
- **"Python dynamic library not found"** → Verify framework embedding
- **Code signing errors** → Ensure signing script runs before "Embed Frameworks"

## File Structure
```
YourApp.app/
├── Frameworks/Python.framework/  ← Embedded Python
├── python-stdlib/               ← Python standard library
├── Python/                      ← Your Python scripts
└── YourApp (binary)
```

## Next Steps
1. Run `./setup_embedded_python.sh`
2. Follow Xcode setup guide
3. Test on simulator and device
4. Deploy self-contained app!

---
*This approach ensures your app is completely self-contained and will work reliably for all users.* 