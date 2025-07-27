import 'game_mode_config.dart';

class GameConstants {
  // Board dimensions - now dynamically loaded from GameModeConfig
  // These are kept for backward compatibility but should not be used
  static const int defaultRowCount = 18;
  static const int defaultColumnCount = 10;
  
  // Bomb generation - these are used for custom difficulty calculations
  static const int defaultBombProbability = 3;
  static const int defaultMaxProbability = 15;
  
  // Difficulty levels - now dynamically loaded from GameModeConfig
  static Map<String, Map<String, int>> get difficultyLevels {
    return GameModeConfig.instance.difficultyLevels;
  }
  
  // Game states
  static const String gameStatePlaying = 'playing';
  static const String gameStateWon = 'won';
  static const String gameStateLost = 'lost';
  
  // Animation durations
  static const Duration tileRevealDuration = Duration(milliseconds: 150);
  static const Duration flagPlacementDuration = Duration(milliseconds: 100);
} 