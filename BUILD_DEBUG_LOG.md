# Build & Debug Log: Embedding Python in Flutter iOS App

## Project Setup Steps

1. Created Flutter project in subdirectory: `python_flutter_embed_demo`
2. Ran `flutter run` to verify default app builds and runs
3. Created `ios/Runner/Python/minimal.py` with a simple function
4. Copied `Python.xcframework` and `python-stdlib` into `ios/`
5. Added both as blue folder references in Xcode (not individual files)

## Debug Issues & Fixes

### 1. Xcode: Could not find included file 'Generated.xcconfig' in search paths
- **Cause:** Flutter build artifacts not generated yet
- **Fix:** Ran `flutter pub get`, `flutter clean`, and `flutter build ios`

### 2. Xcode: Duplicate __init__.py copy errors
- **Cause:** Individual files from `python-stdlib` were added to Copy Bundle Resources
- **Fix:** Removed all individual stdlib files from Copy Bundle Resources, kept only the blue folder reference

### 3. Xcode: Command CompileDTraceScript failed with a nonzero exit code
- **Cause:** Xcode build system bug or cache issue
- **Fix:** Deleted DerivedData, ran `flutter clean`, and rebuilt

### 4. Xcode: 'Python.h' file not found in python-stdlib/test/test_cext/extension.c
- **Cause:** Xcode tried to compile C extension test files from stdlib
- **Fix:** Deleted `ios/python-stdlib/test` and all `__pycache__` folders

### 5. Xcode: Linking in dylib built for 'iOS' when building for 'iOS-simulator'
- **Cause:** Python-Apple-support only provides device (`arm64`) binaries for `lib-dynload`, not simulator
- **Fix:** Switched to building/running on a real device

## Current Status
- Device builds work, simulator builds do not (expected for official Python-Apple-support)
- Ready to proceed with Swift integration 