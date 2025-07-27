import 'package:flutter/foundation.dart';
import '../../core/feature_flags.dart';
import '../../core/game_mode_config.dart';

class SettingsProvider extends ChangeNotifier {
  // Game mode settings
  bool _isFirstClickGuaranteeEnabled = false;
  bool _isClassicMode = true; // Classic vs Kickstarter mode
  
  // 50/50 detection settings
  bool _is5050DetectionEnabled = false;
  bool _is5050SafeMoveEnabled = false;
  
  // Difficulty settings
  String _selectedDifficulty = 'easy';

  // --- New: User-facing feature flags ---
  bool _isUndoMoveEnabled = false;
  bool _isHintSystemEnabled = false;
  bool _isAutoFlagEnabled = false;
  bool _isBoardResetEnabled = false;
  bool _isCustomDifficultyEnabled = false;
  bool _isGameStatisticsEnabled = true;
  bool _isBestTimesEnabled = false;
  bool _isDarkModeEnabled = false;
  bool _isAnimationsEnabled = false;
  bool _isSoundEffectsEnabled = false;
  bool _isHapticFeedbackEnabled = true;
  bool _isMLAssistanceEnabled = false;
  bool _isAutoPlayEnabled = false;
  bool _isDifficultyPredictionEnabled = false;

  // --- Getters for new flags ---
  bool get isFirstClickGuaranteeEnabled => _isFirstClickGuaranteeEnabled;
  bool get isClassicMode => _isClassicMode;
  bool get isKickstarterMode => !_isClassicMode;
  bool get is5050DetectionEnabled => _is5050DetectionEnabled;
  bool get is5050SafeMoveEnabled => _is5050SafeMoveEnabled;
  String get selectedDifficulty => _selectedDifficulty;
  bool get isUndoMoveEnabled => _isUndoMoveEnabled;
  bool get isHintSystemEnabled => _isHintSystemEnabled;
  bool get isAutoFlagEnabled => _isAutoFlagEnabled;
  bool get isBoardResetEnabled => _isBoardResetEnabled;
  bool get isCustomDifficultyEnabled => _isCustomDifficultyEnabled;
  bool get isGameStatisticsEnabled => _isGameStatisticsEnabled;
  bool get isBestTimesEnabled => _isBestTimesEnabled;
  bool get isDarkModeEnabled => _isDarkModeEnabled;
  bool get isAnimationsEnabled => _isAnimationsEnabled;
  bool get isSoundEffectsEnabled => _isSoundEffectsEnabled;
  bool get isHapticFeedbackEnabled => _isHapticFeedbackEnabled;
  bool get isMLAssistanceEnabled => _isMLAssistanceEnabled;
  bool get isAutoPlayEnabled => _isAutoPlayEnabled;
  bool get isDifficultyPredictionEnabled => _isDifficultyPredictionEnabled;

  // Initialize settings
  SettingsProvider() {
    _loadSettings();
    notifyListeners(); // Ensure listeners are notified after loading settings
  }

  // Toggle first click guarantee (Classic vs Kickstarter mode)
  void toggleFirstClickGuarantee() {
    _isFirstClickGuaranteeEnabled = !_isFirstClickGuaranteeEnabled;
    _isClassicMode = !_isFirstClickGuaranteeEnabled;
    
    // Update feature flags
    FeatureFlags.enableFirstClickGuarantee = _isFirstClickGuaranteeEnabled;
    
    _saveSettings();
    notifyListeners();
  }

  // Toggle 50/50 detection
  void toggle5050Detection() {
    _is5050DetectionEnabled = !_is5050DetectionEnabled;
    
    // Update feature flags
    FeatureFlags.enable5050Detection = _is5050DetectionEnabled;
    
    // If disabling 50/50 detection, also disable safe move
    if (!_is5050DetectionEnabled) {
      _is5050SafeMoveEnabled = false;
      FeatureFlags.enable5050SafeMove = false;
    }
    
    _saveSettings();
    notifyListeners();
  }

  // Toggle 50/50 safe move
  void toggle5050SafeMove() {
    if (!_is5050DetectionEnabled) return; // Can't enable safe move without detection
    
    _is5050SafeMoveEnabled = !_is5050SafeMoveEnabled;
    
    // Update feature flags
    FeatureFlags.enable5050SafeMove = _is5050SafeMoveEnabled;
    
    _saveSettings();
    notifyListeners();
  }

  // --- Toggle methods for new flags ---
  void toggleUndoMove() {
    _isUndoMoveEnabled = !_isUndoMoveEnabled;
    FeatureFlags.enableUndoMove = _isUndoMoveEnabled;
    _saveSettings();
    notifyListeners();
  }
  void toggleHintSystem() {
    _isHintSystemEnabled = !_isHintSystemEnabled;
    FeatureFlags.enableHintSystem = _isHintSystemEnabled;
    _saveSettings();
    notifyListeners();
  }
  void toggleAutoFlag() {
    _isAutoFlagEnabled = !_isAutoFlagEnabled;
    FeatureFlags.enableAutoFlag = _isAutoFlagEnabled;
    _saveSettings();
    notifyListeners();
  }
  void toggleBoardReset() {
    _isBoardResetEnabled = !_isBoardResetEnabled;
    FeatureFlags.enableBoardReset = _isBoardResetEnabled;
    _saveSettings();
    notifyListeners();
  }
  void toggleCustomDifficulty() {
    _isCustomDifficultyEnabled = !_isCustomDifficultyEnabled;
    FeatureFlags.enableCustomDifficulty = _isCustomDifficultyEnabled;
    _saveSettings();
    notifyListeners();
  }
  void toggleGameStatistics() {
    _isGameStatisticsEnabled = !_isGameStatisticsEnabled;
    FeatureFlags.enableGameStatistics = _isGameStatisticsEnabled;
    _saveSettings();
    notifyListeners();
  }
  void toggleBestTimes() {
    _isBestTimesEnabled = !_isBestTimesEnabled;
    FeatureFlags.enableBestTimes = _isBestTimesEnabled;
    _saveSettings();
    notifyListeners();
  }
  void toggleDarkMode() {
    _isDarkModeEnabled = !_isDarkModeEnabled;
    FeatureFlags.enableDarkMode = _isDarkModeEnabled;
    _saveSettings();
    notifyListeners();
  }
  void toggleAnimations() {
    _isAnimationsEnabled = !_isAnimationsEnabled;
    FeatureFlags.enableAnimations = _isAnimationsEnabled;
    _saveSettings();
    notifyListeners();
  }
  void toggleSoundEffects() {
    _isSoundEffectsEnabled = !_isSoundEffectsEnabled;
    FeatureFlags.enableSoundEffects = _isSoundEffectsEnabled;
    _saveSettings();
    notifyListeners();
  }
  void toggleHapticFeedback() {
    _isHapticFeedbackEnabled = !_isHapticFeedbackEnabled;
    FeatureFlags.enableHapticFeedback = _isHapticFeedbackEnabled;
    _saveSettings();
    notifyListeners();
  }
  void toggleMLAssistance() {
    _isMLAssistanceEnabled = !_isMLAssistanceEnabled;
    FeatureFlags.enableMLAssistance = _isMLAssistanceEnabled;
    _saveSettings();
    notifyListeners();
  }
  void toggleAutoPlay() {
    _isAutoPlayEnabled = !_isAutoPlayEnabled;
    FeatureFlags.enableAutoPlay = _isAutoPlayEnabled;
    _saveSettings();
    notifyListeners();
  }
  void toggleDifficultyPrediction() {
    _isDifficultyPredictionEnabled = !_isDifficultyPredictionEnabled;
    FeatureFlags.enableDifficultyPrediction = _isDifficultyPredictionEnabled;
    _saveSettings();
    notifyListeners();
  }

  // Set specific mode
  void setGameMode(bool isKickstarterMode) {
    _isClassicMode = !isKickstarterMode;
    _isFirstClickGuaranteeEnabled = isKickstarterMode;
    
    // Update feature flags
    FeatureFlags.enableFirstClickGuarantee = _isFirstClickGuaranteeEnabled;
    
    _saveSettings();
    notifyListeners();
  }

  // Set difficulty
  void setDifficulty(String difficulty) {
    if (GameModeConfig.instance.hasGameMode(difficulty)) {
      _selectedDifficulty = difficulty;
      _saveSettings();
      notifyListeners();
    }
  }

  // Load settings from storage (placeholder for now)
  void _loadSettings() {
    // TODO: Implement persistent storage
    // For now, read defaults from GameModeConfig (single source of truth)
    _isFirstClickGuaranteeEnabled = GameModeConfig.instance.defaultKickstarterMode;
    _isClassicMode = !GameModeConfig.instance.defaultKickstarterMode;
    _is5050DetectionEnabled = GameModeConfig.instance.default5050Detection;
    _is5050SafeMoveEnabled = GameModeConfig.instance.default5050SafeMove;
    _selectedDifficulty = GameModeConfig.instance.defaultGameMode?.id ?? 'hard';
    // --- New: Initialize user-facing feature flags from GameModeConfig ---
    _isUndoMoveEnabled = GameModeConfig.instance.defaultUndoMove;
    _isHintSystemEnabled = GameModeConfig.instance.defaultHintSystem;
    _isAutoFlagEnabled = GameModeConfig.instance.defaultAutoFlag;
    _isBoardResetEnabled = GameModeConfig.instance.defaultBoardReset;
    _isCustomDifficultyEnabled = GameModeConfig.instance.defaultCustomDifficulty;
    _isGameStatisticsEnabled = GameModeConfig.instance.defaultGameStatistics;
    _isBestTimesEnabled = GameModeConfig.instance.defaultBestTimes;
    _isDarkModeEnabled = GameModeConfig.instance.defaultDarkMode;
    _isAnimationsEnabled = GameModeConfig.instance.defaultAnimations;
    _isSoundEffectsEnabled = GameModeConfig.instance.defaultSoundEffects;
    _isHapticFeedbackEnabled = GameModeConfig.instance.defaultHapticFeedback;
    _isMLAssistanceEnabled = GameModeConfig.instance.defaultMLAssistance;
    _isAutoPlayEnabled = GameModeConfig.instance.defaultAutoPlay;
    _isDifficultyPredictionEnabled = GameModeConfig.instance.defaultDifficultyPrediction;
    
    // Update feature flags to match loaded settings
    FeatureFlags.enableFirstClickGuarantee = _isFirstClickGuaranteeEnabled;
    FeatureFlags.enable5050Detection = _is5050DetectionEnabled;
    FeatureFlags.enable5050SafeMove = _is5050SafeMoveEnabled;
    FeatureFlags.enableUndoMove = _isUndoMoveEnabled;
    FeatureFlags.enableHintSystem = _isHintSystemEnabled;
    FeatureFlags.enableAutoFlag = _isAutoFlagEnabled;
    FeatureFlags.enableBoardReset = _isBoardResetEnabled;
    FeatureFlags.enableCustomDifficulty = _isCustomDifficultyEnabled;
    FeatureFlags.enableGameStatistics = _isGameStatisticsEnabled;
    FeatureFlags.enableBestTimes = _isBestTimesEnabled;
    FeatureFlags.enableDarkMode = _isDarkModeEnabled;
    FeatureFlags.enableAnimations = _isAnimationsEnabled;
    FeatureFlags.enableSoundEffects = _isSoundEffectsEnabled;
    FeatureFlags.enableHapticFeedback = _isHapticFeedbackEnabled;
    FeatureFlags.enableMLAssistance = _isMLAssistanceEnabled;
    FeatureFlags.enableAutoPlay = _isAutoPlayEnabled;
    FeatureFlags.enableDifficultyPrediction = _isDifficultyPredictionEnabled;
  }

  // Save settings to storage (placeholder for now)
  void _saveSettings() {
    // TODO: Implement persistent storage
    // For now, just update feature flags
  }

  // Reset to defaults
  void resetToDefaults() {
    // Read defaults from GameModeConfig (single source of truth)
    _isFirstClickGuaranteeEnabled = GameModeConfig.instance.defaultKickstarterMode;
    _isClassicMode = !GameModeConfig.instance.defaultKickstarterMode;
    _is5050DetectionEnabled = GameModeConfig.instance.default5050Detection;
    _is5050SafeMoveEnabled = GameModeConfig.instance.default5050SafeMove;
    _selectedDifficulty = GameModeConfig.instance.defaultGameMode?.id ?? 'hard';
    // --- New: Reset user-facing feature flags from GameModeConfig ---
    _isUndoMoveEnabled = GameModeConfig.instance.defaultUndoMove;
    _isHintSystemEnabled = GameModeConfig.instance.defaultHintSystem;
    _isAutoFlagEnabled = GameModeConfig.instance.defaultAutoFlag;
    _isBoardResetEnabled = GameModeConfig.instance.defaultBoardReset;
    _isCustomDifficultyEnabled = GameModeConfig.instance.defaultCustomDifficulty;
    _isGameStatisticsEnabled = GameModeConfig.instance.defaultGameStatistics;
    _isBestTimesEnabled = GameModeConfig.instance.defaultBestTimes;
    _isDarkModeEnabled = GameModeConfig.instance.defaultDarkMode;
    _isAnimationsEnabled = GameModeConfig.instance.defaultAnimations;
    _isSoundEffectsEnabled = GameModeConfig.instance.defaultSoundEffects;
    _isHapticFeedbackEnabled = GameModeConfig.instance.defaultHapticFeedback;
    _isMLAssistanceEnabled = GameModeConfig.instance.defaultMLAssistance;
    _isAutoPlayEnabled = GameModeConfig.instance.defaultAutoPlay;
    _isDifficultyPredictionEnabled = GameModeConfig.instance.defaultDifficultyPrediction;
    // Update feature flags (this is needed for reset functionality)
    FeatureFlags.enableFirstClickGuarantee = _isFirstClickGuaranteeEnabled;
    FeatureFlags.enable5050Detection = _is5050DetectionEnabled;
    FeatureFlags.enable5050SafeMove = _is5050SafeMoveEnabled;
    FeatureFlags.enableUndoMove = _isUndoMoveEnabled;
    FeatureFlags.enableHintSystem = _isHintSystemEnabled;
    FeatureFlags.enableAutoFlag = _isAutoFlagEnabled;
    FeatureFlags.enableBoardReset = _isBoardResetEnabled;
    FeatureFlags.enableCustomDifficulty = _isCustomDifficultyEnabled;
    FeatureFlags.enableGameStatistics = _isGameStatisticsEnabled;
    FeatureFlags.enableBestTimes = _isBestTimesEnabled;
    FeatureFlags.enableDarkMode = _isDarkModeEnabled;
    FeatureFlags.enableAnimations = _isAnimationsEnabled;
    FeatureFlags.enableSoundEffects = _isSoundEffectsEnabled;
    FeatureFlags.enableHapticFeedback = _isHapticFeedbackEnabled;
    FeatureFlags.enableMLAssistance = _isMLAssistanceEnabled;
    FeatureFlags.enableAutoPlay = _isAutoPlayEnabled;
    FeatureFlags.enableDifficultyPrediction = _isDifficultyPredictionEnabled;
    _saveSettings();
    notifyListeners();
  }
} 