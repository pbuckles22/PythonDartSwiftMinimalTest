/// Feature flags for controlling which features are enabled in the app
/// These are initialized from JSON configuration and can be updated at runtime
class FeatureFlags {
  // Core game features
  static bool enableFirstClickGuarantee = false; // Set from JSON in main.dart
  static bool enableGameStatistics = true; // Game statistics and timer
  static bool enableBoardReset = false; // Board reset functionality
  static bool enableCustomDifficulty = false; // Custom difficulty settings
  
  // Advanced features
  static bool enableUndoMove = false; // Undo functionality
  static bool enableHintSystem = false; // Hint system
  static bool enableAutoFlag = false; // Auto-flagging
  static bool enableBestTimes = false; // Best times tracking
  static bool enable5050Detection = false; // Set from JSON in main.dart
  static bool enable5050SafeMove = false; // Set from JSON in main.dart
  
  // UI/UX features
  static bool enableDarkMode = false; // Dark mode
  static bool enableAnimations = false; // Smooth animations
  static bool enableSoundEffects = false; // Sound effects
  static bool enableHapticFeedback = true; // Haptic feedback
  
  // ML/AI features (for future integration)
  static bool enableMLAssistance = false; // ML-powered assistance
  static bool enableAutoPlay = false; // Auto-play functionality
  static bool enableDifficultyPrediction = false; // Difficulty prediction
  
  // Debug/Development features
  static bool enableDebugMode = false; // Debug mode
  static bool enableDebugProbabilityMode = false; // Debug probability mode with UI controls
  static bool enablePerformanceMetrics = false; // Performance tracking
  static bool enableTestMode = false; // Test mode for development
} 