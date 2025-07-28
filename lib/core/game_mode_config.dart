import 'dart:convert';
import 'package:flutter/services.dart';

class GameMode {
  final String id;
  final String name;
  final String description;
  final int rows;
  final int columns;
  final int mines;
  final bool enabled;
  final String? icon;

  GameMode({
    required this.id,
    required this.name,
    String? description,
    required this.rows,
    required this.columns,
    required this.mines,
    required this.enabled,
    this.icon,
  }) : description = description ?? _generateDescription(rows, columns, mines);

  /// Auto-generate description based on grid dimensions and mine count
  static String _generateDescription(int rows, int columns, int mines) {
    return '${rows}×${columns} grid, ${mines} mines';
  }

  factory GameMode.fromJson(Map<String, dynamic> json) {
    return GameMode(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?, // Now optional
      rows: json['rows'] as int,
      columns: json['columns'] as int,
      mines: json['mines'] as int,
      enabled: json['enabled'] as bool,
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'rows': rows,
      'columns': columns,
      'mines': mines,
      'enabled': enabled,
      if (icon != null) 'icon': icon,
    };
  }
}

class GameModeConfig {
  static final GameModeConfig instance = GameModeConfig._();

  static List<GameMode> _gameModes = [];
  static String _defaultMode = 'easy';
  static bool _isLoaded = false;
  
  // Feature defaults
  static bool _defaultKickstarterMode = true;
  static bool _default5050Detection = false;
  static bool _default5050SafeMove = false;

  // Store all feature flag defaults
  static Map<String, bool> _defaultFeatureFlags = {};

  GameModeConfig._() {
    // Validate configuration immediately when instance is created
    _validateConfiguration();
  }

  /// Validate the game mode configuration at build/load time
  void _validateConfiguration() {
    try {
      // This will be called when the class is first accessed
      // We'll validate during the first load
    } catch (e) {
      // Re-throw validation errors immediately
      rethrow;
    }
  }

  /// Load game modes from JSON file
  Future<void> loadGameModes() async {
    if (_isLoaded) return;

    print('DEBUG: GameModeConfig: Starting loadGameModes()');
    try {
      final String jsonString = await rootBundle.loadString('assets/config/game_modes.json');
      print('DEBUG: GameModeConfig: Successfully loaded JSON string, length: ${jsonString.length}');
      // print('GameModeConfig: Raw JSON string:');
      // print(jsonString);
      final Map<String, dynamic> json = jsonDecode(jsonString);
      // print('GameModeConfig: Parsed JSON object:');
      // print(json);
      
      final List<dynamic> gameModesJson = json['game_modes'] as List;
      
      // Validate for duplicate IDs and names
      final Set<String> ids = <String>{};
      final Set<String> names = <String>{};
      
      for (final modeJson in gameModesJson) {
        final id = modeJson['id'] as String;
        final name = modeJson['name'] as String;
        
        if (ids.contains(id)) {
          final error = ArgumentError('Duplicate game mode ID found: "$id". All game mode IDs must be unique.');
          // print('GameModeConfig: VALIDATION ERROR - $error');
          throw error;
        }
        if (names.contains(name)) {
          final error = ArgumentError('Duplicate game mode name found: "$name". All game mode names must be unique.');
          // print('GameModeConfig: VALIDATION ERROR - $error');
          throw error;
        }
        
        ids.add(id);
        names.add(name);
      }
      
      _gameModes = gameModesJson
          .map((mode) => GameMode.fromJson(mode))
          .toList();
      // print('GameModeConfig: Parsed game_modes:');
      // print(_gameModes);
      
      // Read defaults from new structure
      if (json.containsKey('defaults')) {
        final defaults = json['defaults'] as Map<String, dynamic>;
        _defaultMode = defaults['game_mode'] as String;
        print('DEBUG: GameModeConfig: Found defaults section, game_mode = $_defaultMode');
        
        if (defaults.containsKey('features')) {
          final features = defaults['features'] as Map<String, dynamic>;
          print('DEBUG: GameModeConfig: Found features section: $features');
          _defaultKickstarterMode = features['kickstarter_mode'] as bool? ?? false;
          _default5050Detection = features['5050_detection'] as bool? ?? false;
          _default5050SafeMove = features['5050_safe_move'] as bool? ?? false;
          // Store all feature flags
          _defaultFeatureFlags = features.map((k, v) => MapEntry(k, v as bool? ?? false));
          print('DEBUG: GameModeConfig: _defaultFeatureFlags = $_defaultFeatureFlags');
        } else {
          print('DEBUG: GameModeConfig: No features section found in defaults');
        }
      } else {
        // Fallback to old structure
        _defaultMode = json['default_mode'] as String? ?? 'easy';
        print('DEBUG: GameModeConfig: No defaults section, using fallback game_mode = $_defaultMode');
      }
      
      _isLoaded = true;
      // print('GameModeConfig: Loaded ${_gameModes.length} game modes from JSON');
    } catch (e) {
      print('DEBUG: GameModeConfig: Failed to load JSON. Error: $e');
      if (e is ArgumentError) {
        // Re-throw validation errors so they're visible
        rethrow;
      }
      // Only fall back for other types of errors (file not found, JSON parse errors, etc.)
      print('DEBUG: GameModeConfig: Using fallback modes due to non-validation error');
      _loadDefaultModes();
      _isLoaded = true;
    }
  }

  /// Fallback default game modes if JSON loading fails
  void _loadDefaultModes() {
    _gameModes = [
      GameMode(
        id: 'easy',
        name: 'Easy',
        description: '9×9 grid, 10 mines',
        rows: 9,
        columns: 9,
        mines: 10,
        enabled: true,
        icon: 'sentiment_satisfied',
      ),
      GameMode(
        id: 'normal',
        name: 'Normal',
        description: '16×16 grid, 40 mines',
        rows: 16,
        columns: 16,
        mines: 40,
        enabled: true,
        icon: 'sentiment_neutral',
      ),
      GameMode(
        id: 'hard',
        name: 'Hard',
        description: '16×30 grid, 99 mines',
        rows: 16,
        columns: 30,
        mines: 99,
        enabled: true,
        icon: 'sentiment_dissatisfied',
      ),
      GameMode(
        id: 'expert',
        name: 'Expert',
        description: '18×24 grid, 115 mines',
        rows: 18,
        columns: 24,
        mines: 115,
        enabled: true,
        icon: 'warning',
      ),
      GameMode(
        id: 'custom',
        name: 'Custom',
        description: 'Custom grid size and mine count',
        rows: 18,
        columns: 10,
        mines: 0,
        enabled: false,
        icon: 'settings',
      ),
    ];
    _defaultMode = 'hard';
    
    // Use safe fallback values for features (false = disabled)
    // This ensures the app doesn't crash if JSON is invalid
    _defaultKickstarterMode = true;
    _default5050Detection = false;
    _default5050SafeMove = false;
  }

  /// Get all enabled game modes
  List<GameMode> get enabledGameModes => _gameModes.where((mode) => mode.enabled).toList();

  /// Get all game modes (including disabled ones)
  List<GameMode> get allGameModes => List.unmodifiable(_gameModes);

  /// Get a specific game mode by ID
  GameMode? getGameMode(String id) {
    try {
      final mode = _gameModes.firstWhere((mode) => mode.id == id);
      return mode;
    } catch (e) {
      // print('GameModeConfig: Could not find game mode with id "$id". Available modes: ${_gameModes.map((m) => m.id).toList()}');
      return null;
    }
  }

  /// Get the default game mode
  GameMode? get defaultGameMode => getGameMode(_defaultMode);

  /// Get feature defaults
  bool get defaultKickstarterMode => _defaultKickstarterMode;
  bool get default5050Detection => _default5050Detection;
  bool get default5050SafeMove => _default5050SafeMove;

  // --- New: Explicit getters for all user-facing feature flags ---
  bool get defaultUndoMove => _defaultFeatureFlags['undo_move'] ?? false;
  bool get defaultHintSystem => _defaultFeatureFlags['hint_system'] ?? false;
  bool get defaultAutoFlag => _defaultFeatureFlags['auto_flag'] ?? false;
  bool get defaultBoardReset => _defaultFeatureFlags['board_reset'] ?? false;
  bool get defaultCustomDifficulty => _defaultFeatureFlags['custom_difficulty'] ?? false;
  bool get defaultGameStatistics => _defaultFeatureFlags['game_statistics'] ?? true;
  bool get defaultBestTimes => _defaultFeatureFlags['best_times'] ?? false;
  bool get defaultDarkMode => _defaultFeatureFlags['dark_mode'] ?? false;
  bool get defaultAnimations => _defaultFeatureFlags['animations'] ?? false;
  bool get defaultSoundEffects => _defaultFeatureFlags['sound_effects'] ?? false;
  bool get defaultHapticFeedback => _defaultFeatureFlags['haptic_feedback'] ?? true;
  bool get defaultMLAssistance => _defaultFeatureFlags['ml_assistance'] ?? false;
  bool get defaultAutoPlay => _defaultFeatureFlags['auto_play'] ?? false;
  bool get defaultDifficultyPrediction => _defaultFeatureFlags['difficulty_prediction'] ?? false;

  /// Get all feature flag defaults as a map
  Map<String, bool> get defaultFeatureFlags => Map.unmodifiable(_defaultFeatureFlags);

  /// Check if a game mode exists
  bool hasGameMode(String id) => getGameMode(id) != null;

  /// Get game mode names for UI display
  List<String> get gameModeNames => _gameModes.map((mode) => mode.name).toList();

  /// Get game mode IDs
  List<String> get gameModeIds => _gameModes.map((mode) => mode.id).toList();

  /// Reload game modes from JSON (useful for hot reload during development)
  Future<void> reload() async {
    _isLoaded = false;
    _gameModes = [];
    _defaultMode = 'easy';
    await loadGameModes();
  }

  /// Get legacy difficulty levels map for backward compatibility
  Map<String, Map<String, int>> get difficultyLevels {
    final Map<String, Map<String, int>> levels = {};
    for (final mode in _gameModes) {
      levels[mode.id] = {
        'rows': mode.rows,
        'columns': mode.columns,
        'mines': mode.mines,
      };
    }
    return levels;
  }
} 