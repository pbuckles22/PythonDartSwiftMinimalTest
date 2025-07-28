# TODO List - FlutterMinesweeper with Python

## 🐛 Bugs to Fix

### High Priority
- **Difficulty Setting Bug**: Even though HARD is set as default in GameModeConfig, the app starts with EASY difficulty until "New Game" is pressed
  - **Location**: Settings loading/initialization
  - **Impact**: Users see wrong difficulty on first launch
  - **Status**: 🔴 Pending

### Medium Priority
- **Python 50/50 Detection**: ✅ **FIXED** - Now working correctly!
  - **Location**: `ios/Runner/PythonMinimalRunner.swift` and `ios/Runner/Resources/find_5050.py`
  - **Impact**: 50/50 detection feature now functional
  - **Status**: ✅ Complete
  - **Solution**: Fixed Swift type conversion for nested Python arrays

## 🚀 Features to Implement

### Python Integration
- [x] Debug 50/50 detection Python script execution ✅ **COMPLETE**
- [ ] Integrate 50/50 detection with actual game state
- [ ] Add comprehensive error handling for Python failures
- [ ] Optimize Python performance for real-time detection

### Game Features
- [ ] Implement kickstarter mode logic (first click guarantee)
- [ ] Add undo move functionality
- [ ] Add hint system
- [ ] Add auto-flag functionality
- [ ] Add board reset functionality

## 📝 Technical Debt

- [ ] Add comprehensive unit tests
- [ ] Add integration tests for Python integration
- [ ] Improve error handling throughout the app
- [ ] Add logging system for debugging
- [ ] Optimize app performance

## 🎯 Next Steps

1. **Fix difficulty setting bug** (immediate)
2. **Return to Python 50/50 debugging** (when user is ready)
3. **Implement remaining game features**
4. **Add comprehensive testing**

---

*Last Updated: January 2025* 