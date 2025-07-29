# Quick Context for Next Agent

## 🎯 **CURRENT STATUS**: Working Flutter iOS app with Python subprocess integration

### ✅ **What Works**
- Flutter UI → Swift Method Channel → Python Subprocess → Result back to Flutter
- App builds and runs without crashes on iOS devices
- Python script executes and returns result successfully
- 50/50 detection algorithm integrated and working
- Feature flags system operational
- Comprehensive test framework in place

### 🔧 **Key Files** (All in main project)
- `ios/Runner/PythonMinimalRunner.swift` - Subprocess implementation
- `ios/Runner/AppDelegate.swift` - Method channel setup  
- `ios/Runner/Resources/minimal.py` - Python script
- `ios/Runner/Resources/find_5050.py` - 50/50 detection
- `lib/main.dart` - Flutter UI
- `lib/presentation/providers/game_provider.dart` - Game logic

### 🚀 **Quick Commands**
```bash
flutter run -d C7D05565-7D5F-4C8C-AB95-CDBFAE7BA098  # iOS Simulator
flutter run -d 00008130-00127CD40AF0001C              # iOS Device
flutter test                                          # Run tests
./test_runner.sh                                      # Comprehensive tests
```

### ❌ **What NOT to Do**
- Don't try PythonKit again (crashes on iOS)
- Don't use system Python subprocess (not available on iOS)
- Don't rely on macOS-only solutions

### ✅ **What TO Do**
- Use embedded Python executable approach
- Test on actual iOS device, not just simulator
- Reference specialized context files for detailed work

### 📋 **Current Test Results**
```
flutter: 🔔 Dart: _callPython() called
🔔 Swift: MethodChannel received call: addOneAndOne
🔍 PythonMinimalRunner: Starting subprocess call
🔍 Python output: 2
✅ Successfully got result: 2
flutter: 🔔 Dart: Python result: 2
```

## 📚 **Context File Structure** (Use for Detailed Work)

### 🚀 **Always Read First**
- `PROJECT_STATUS.md` - Current issues and next steps

### 📋 **Specialized Context** (Load Based on Task)
- **Python Integration**: `CONTEXT_PYTHON_INTEGRATION.md` - Technical Python details
- **UI/UX Work**: `CONTEXT_UI_UX.md` - Interface and user experience
- **Testing Work**: `CONTEXT_TESTING.md` - Test framework and issues
- **Quick Reference**: `QUICK_REFERENCE.md` - Task-specific file loading guide

### 📖 **Full Context** (Load When Needed)
- **Complete Technical**: `CONTEXT.md` - Full implementation details
- **Historical Context**: `CONVERSATION_SUMMARY.md` - Past decisions/attempts
- **Setup Instructions**: `README.md` - Project documentation

### 🎯 **Quick Reference**
- **Python Work**: Load `CONTEXT_PYTHON_INTEGRATION.md` (~350 lines total)
- **UI Work**: Load `CONTEXT_UI_UX.md` (~380 lines total)
- **Testing Work**: Load `CONTEXT_TESTING.md` (~400 lines total)
- **Quick Questions**: Just `PROJECT_STATUS.md` (~200 lines total)

The subprocess approach is working perfectly and is the right solution for this use case. 