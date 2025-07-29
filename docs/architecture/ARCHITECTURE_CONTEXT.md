# Flutter Minesweeper - Complete Architecture Context

## 🚨 CRITICAL: ALWAYS CHECK THIS FILE BEFORE IMPLEMENTING NEW FEATURES

This file documents the complete architecture to prevent code duplication, ensure proper reuse, and maintain consistency across the codebase.

## 📋 Table of Contents

1. [Core Architecture Patterns](#core-architecture-patterns)
2. [Repository Layer](#repository-layer)
3. [Provider Layer](#provider-layer)
4. [Feature Flags System](#feature-flags-system)
5. [Python Integration](#python-integration)
6. [Game Logic](#game-logic)
7. [UI Components](#ui-components)
8. [Testing Framework](#testing-framework)
9. [Configuration Management](#configuration-management)
10. [Common Patterns & Anti-Patterns](#common-patterns--anti-patterns)

---

## 🏗️ Core Architecture Patterns

### Clean Architecture Layers
```
UI Layer (Widgets) → Provider Layer → Repository Layer → Domain Layer
```

### Key Principles
- **Single Responsibility**: Each class has one clear purpose
- **Dependency Inversion**: Depend on abstractions, not concretions
- **Immutable State**: GameState and Cell objects are immutable
- **Repository Pattern**: All data operations go through repositories
- **Provider Pattern**: State management with ChangeNotifier

---

## 📚 Repository Layer

### GameRepository Interface (`lib/domain/repositories/game_repository.dart`)

**ALWAYS CHECK THIS INTERFACE BEFORE IMPLEMENTING GAME LOGIC**

```dart
abstract class GameRepository {
  // Core game operations
  Future<GameState> initializeGame(String difficulty);
  Future<GameState> revealCell(int row, int col);
  Future<GameState> toggleFlag(int row, int col);
  Future<GameState> chordCell(int row, int col);
  
  // State queries
  GameState getCurrentState();
  bool isGameWon();
  bool isGameLost();
  int getRemainingMines();
  Map<String, dynamic> getGameStatistics();
  
  // Game management
  Future<GameState> resetGame();
  
  // ⚠️ CRITICAL: 50/50 Safe Move Method
  Future<GameState> perform5050SafeMove(int clickedRow, int clickedCol, int otherRow, int otherCol);
}
```

### GameRepositoryImpl (`lib/data/repositories/game_repository_impl.dart`)

**IMPLEMENTATION DETAILS:**
- Uses immutable `GameState` and `Cell` objects
- Creates new board copies for modifications
- Handles bomb count recalculation after mine moves
- Implements first-click guarantee logic
- **ALREADY IMPLEMENTS** `perform5050SafeMove` with proper bomb moving logic

**KEY METHODS:**
- `_copyBoard()` - Creates deep copy of board
- `_updateBombCountsAfterMineMove()` - Recalculates bomb counts
- `_ensureFirstClickCascade()` - First-click guarantee
- `perform5050SafeMove()` - **USE THIS FOR 50/50 SAFE MOVES**

---

## 🎛️ Provider Layer

### GameProvider (`lib/presentation/providers/game_provider.dart`)

**RESPONSIBILITIES:**
- Orchestrates game operations through repository
- Manages loading states and error handling
- Handles 50/50 detection and UI updates
- Manages timer service integration

**KEY METHODS:**
```dart
// Core game operations (delegate to repository)
Future<void> initializeGame(String difficulty)
Future<void> revealCell(int row, int col)
Future<void> toggleFlag(int row, int col)
Future<void> chordCell(int row, int col)

// 50/50 detection
Future<void> updateFiftyFiftyDetection()
Future<void> execute5050SafeMove(int row, int col) // ⚠️ USES REPOSITORY METHOD

// State queries
bool isCellIn5050Situation(int row, int col)
Map<String, dynamic> getCellProbabilityAnalysis(int row, int col)
```

**⚠️ CRITICAL: 50/50 Safe Move Implementation**
```dart
// CORRECT: Use repository method
_gameState = await _repository.perform5050SafeMove(row, col, otherCell[0], otherCell[1]);

// WRONG: Don't implement bomb moving logic here
// Don't create _moveBombFromTo() or similar methods in GameProvider
```

### SettingsProvider (`lib/presentation/providers/settings_provider.dart`)

**RESPONSIBILITIES:**
- Manages user-facing feature toggles
- Updates `FeatureFlags` static properties
- Handles settings persistence

**KEY METHODS:**
```dart
// Feature toggles (all update FeatureFlags)
void toggleFirstClickGuarantee()
void toggle5050Detection()
void toggle5050SafeMove()
void toggleUndoMove()
// ... etc
```

---

## 🚩 Feature Flags System

### FeatureFlags (`lib/core/feature_flags.dart`)

**STATIC CLASS - SINGLE SOURCE OF TRUTH**

```dart
class FeatureFlags {
  // Core game features
  static bool enableFirstClickGuarantee = false;
  static bool enable5050Detection = false;
  static bool enable5050SafeMove = false;
  static bool enableGameStatistics = true;
  
  // Advanced features
  static bool enableUndoMove = false;
  static bool enableHintSystem = false;
  static bool enableAutoFlag = false;
  static bool enableBestTimes = false;
  
  // UI/UX features
  static bool enableDarkMode = false;
  static bool enableAnimations = false;
  static bool enableSoundEffects = false;
  static bool enableHapticFeedback = true;
  
  // Debug/Development
  static bool enableDebugMode = false;
  static bool enableTestMode = false;
}
```

**⚠️ CRITICAL RULES:**
1. **ALWAYS** check `FeatureFlags` before implementing feature logic
2. **NEVER** create duplicate feature flag systems
3. **SettingsProvider** updates `FeatureFlags`, not the other way around
4. **JSON config** sets initial values in `main.dart`

---

## 🐍 Python Integration

### Native5050Solver (`lib/services/native_5050_solver.dart`)

**SINGLE POINT OF PYTHON INTEGRATION**

```dart
class Native5050Solver {
  static const MethodChannel _channel = MethodChannel('python/minimal');
  
  static Future<List<List<int>>> find5050(Map<String, double> probabilityMap) async {
    // Calls Swift method channel
    // Returns 50/50 cell coordinates
  }
}
```

**USAGE PATTERN:**
```dart
// In GameProvider.updateFiftyFiftyDetection()
final probabilityMap = _calculateSimpleProbabilities();
_fiftyFiftyCells = await Native5050Solver.find5050(probabilityMap);
```

**⚠️ CRITICAL:**
- **ONLY** use this service for 50/50 detection
- **NEVER** create additional Python integration points
- **ALWAYS** handle MissingPluginException in tests

---

## 🎮 Game Logic

### GameState (`lib/domain/entities/game_state.dart`)

**IMMUTABLE ENTITY**

```dart
class GameState {
  final List<List<Cell>> board;
  final String gameStatus;
  final int minesCount;
  final int flaggedCount;
  final int revealedCount;
  final int totalCells;
  final DateTime? startTime;
  final DateTime? endTime;
  final String difficulty;
  
  // Computed properties
  bool get isGameOver => gameStatus != GameConstants.gameStatePlaying;
  bool get isWon => gameStatus == GameConstants.gameStateWon;
  bool get isLost => gameStatus == GameConstants.gameStateLost;
  bool get isPlaying => gameStatus == GameConstants.gameStatePlaying;
  int get remainingMines => minesCount - flaggedCount;
  double get progressPercentage => revealedCount / totalCells;
  Duration? get gameDuration => endTime?.difference(startTime ?? DateTime.now());
}
```

### Cell (`lib/domain/entities/cell.dart`)

**IMMUTABLE ENTITY**

```dart
class Cell {
  final bool hasBomb;
  final int bombsAround;
  final CellState state;
  final int row;
  final int col;
  
  // Methods
  void reveal() // Changes internal state
  void flag() // Changes internal state
  void forceReveal() // For exploded bombs
  Cell copyWith({...}) // Creates new instance
}
```

**⚠️ CRITICAL:**
- **NEVER** make `hasBomb` or other properties mutable
- **ALWAYS** use `copyWith()` for modifications
- **ALWAYS** create new `GameState` instances for state changes

---

## 🎨 UI Components

### GamePage (`lib/presentation/pages/game_page.dart`)
- Main game interface
- Uses `GameProvider` and `SettingsProvider`
- Handles game initialization

### GameBoard (`lib/presentation/widgets/game_board.dart`)
- Renders the game grid
- Handles cell taps and 50/50 detection
- **USES** `gameProvider.execute5050SafeMove()` for 50/50 cells

### SettingsPage (`lib/presentation/pages/settings_page.dart`)
- Feature toggle interface
- **USES** `SettingsProvider` methods
- Updates `FeatureFlags` through provider

---

## 🧪 Testing Framework

### Test Structure
```
test/
├── unit/
│   ├── game_provider_test.dart
│   ├── game_repository_impl_test.dart
│   ├── settings_provider_test.dart
│   └── native_5050_solver_test.dart
├── integration/
│   └── python_integration_test.dart
└── widget/
    ├── game_page_test.dart
    └── settings_page_test.dart
```

### Test Patterns
```dart
// Always initialize Flutter binding
TestWidgetsFlutterBinding.ensureInitialized();

// Load GameModeConfig in setUpAll
await GameModeConfig.instance.loadGameModes();

// Mock repositories for provider tests
class MockGameRepository implements GameRepository {
  // Implement all interface methods
}
```

---

## ⚙️ Configuration Management

### GameModeConfig (`lib/core/game_mode_config.dart`)

**SINGLETON - LOADS JSON CONFIGURATION**

```dart
class GameModeConfig {
  static final GameModeConfig instance = GameModeConfig._();
  
  // Game modes
  List<GameMode> get gameModes => _gameModes;
  GameMode? getGameMode(String id) => _gameModes.firstWhere((m) => m.id == id);
  
  // Feature defaults
  Map<String, bool> get defaultFeatureFlags => _defaultFeatureFlags;
  
  // Loading
  Future<void> loadGameModes() async {
    // Loads from assets/config/game_modes.json
  }
}
```

### Configuration Files
- `assets/config/game_modes.json` - Game modes and feature defaults
- `ios/Runner/Resources/` - Python scripts and embedded Python

---

## 🔄 Common Patterns & Anti-Patterns

### ✅ DO: Proper Patterns

1. **Use Repository Methods**
```dart
// ✅ CORRECT
_gameState = await _repository.perform5050SafeMove(row, col, otherRow, otherCol);

// ✅ CORRECT
_gameState = await _repository.revealCell(row, col);
```

2. **Check Feature Flags**
```dart
// ✅ CORRECT
if (!FeatureFlags.enable5050SafeMove) {
  await revealCell(row, col);
  return;
}
```

3. **Immutable State Changes**
```dart
// ✅ CORRECT
final newGameState = _currentState!.copyWith(
  board: newBoard,
  gameStatus: newStatus,
);
```

4. **Proper Error Handling**
```dart
// ✅ CORRECT
try {
  _gameState = await _repository.revealCell(row, col);
} catch (e) {
  _setError('Failed to reveal cell: $e');
}
```

### ❌ DON'T: Anti-Patterns

1. **Don't Bypass Repository**
```dart
// ❌ WRONG - Don't modify game state directly
_gameState!.board[row][col].hasBomb = false;

// ❌ WRONG - Don't create duplicate logic
void _moveBombFromTo(int fromRow, int fromCol, int toRow, int toCol) {
  // This should use repository.perform5050SafeMove()
}
```

2. **Don't Create Duplicate Interfaces**
```dart
// ❌ WRONG - Don't create new repository methods
Future<GameState> myCustomMethod() async {
  // Check if this should use existing repository methods
}
```

3. **Don't Make Immutable Properties Mutable**
```dart
// ❌ WRONG - Don't make final properties mutable
class GameState {
  bool hasBomb; // Should be final
}
```

4. **Don't Duplicate Feature Flag Logic**
```dart
// ❌ WRONG - Don't create local feature flags
class MyProvider {
  bool _myFeatureEnabled = false; // Use FeatureFlags instead
}
```

---

## 🚨 CRITICAL CHECKLIST BEFORE IMPLEMENTING

### Before Adding New Features:

1. **✅ Check Repository Interface**
   - Does `GameRepository` already have a method for this?
   - Should this use existing methods?

2. **✅ Check Feature Flags**
   - Is there already a feature flag for this?
   - Should this be controlled by existing flags?

3. **✅ Check Existing Services**
   - Is there already a service for this functionality?
   - Should this use `Native5050Solver` or other existing services?

4. **✅ Check Immutability**
   - Am I trying to modify immutable objects?
   - Should I use `copyWith()` or repository methods?

5. **✅ Check Architecture Layers**
   - Am I putting logic in the right layer?
   - Should this be in Provider, Repository, or Domain?

6. **✅ Check Testing**
   - Are there existing tests for similar functionality?
   - Should I follow existing test patterns?

---

## 📝 Implementation Guidelines

### When Adding New Game Logic:
1. **ALWAYS** add to `GameRepository` interface first
2. **ALWAYS** implement in `GameRepositoryImpl`
3. **ALWAYS** delegate from `GameProvider` to repository
4. **NEVER** implement game logic directly in providers

### When Adding New Features:
1. **ALWAYS** add to `FeatureFlags` first
2. **ALWAYS** add to `SettingsProvider` if user-configurable
3. **ALWAYS** check existing feature flags before creating new ones
4. **NEVER** create duplicate feature systems

### When Adding New UI:
1. **ALWAYS** use existing providers
2. **ALWAYS** follow existing widget patterns
3. **ALWAYS** check existing UI components first
4. **NEVER** create duplicate UI state management

---

## 🔍 Debugging & Troubleshooting

### Common Issues:

1. **"Method not found" errors**
   - Check if method exists in `GameRepository` interface
   - Ensure implementation exists in `GameRepositoryImpl`

2. **Feature not working**
   - Check `FeatureFlags` static properties
   - Verify `SettingsProvider` is updating flags correctly
   - Check JSON configuration

3. **State not updating**
   - Ensure using repository methods, not direct state modification
   - Check if `notifyListeners()` is called
   - Verify immutable state patterns

4. **50/50 detection issues**
   - Check `Native5050Solver` integration
   - Verify `GameProvider.updateFiftyFiftyDetection()` is called
   - Check Python script execution

---

## 📚 Related Files

### Core Architecture:
- `lib/domain/repositories/game_repository.dart` - Repository interface
- `lib/data/repositories/game_repository_impl.dart` - Repository implementation
- `lib/presentation/providers/game_provider.dart` - Game state management
- `lib/presentation/providers/settings_provider.dart` - Settings management

### Feature System:
- `lib/core/feature_flags.dart` - Feature flag definitions
- `lib/core/game_mode_config.dart` - Configuration management
- `assets/config/game_modes.json` - Configuration file

### Python Integration:
- `lib/services/native_5050_solver.dart` - Python integration service
- `ios/Runner/AppDelegate.swift` - Swift method channel setup
- `ios/Runner/Resources/` - Python scripts

### Testing:
- `test/unit/` - Unit tests
- `test/integration/` - Integration tests
- `test/widget/` - Widget tests

---

**⚠️ REMEMBER: ALWAYS CHECK THIS FILE BEFORE IMPLEMENTING NEW FEATURES TO PREVENT DUPLICATION AND ENSURE PROPER ARCHITECTURE!** 