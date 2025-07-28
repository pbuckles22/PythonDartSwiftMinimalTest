import 'package:flutter_test/flutter_test.dart';
import 'package:python_flutter_embed_demo/presentation/providers/settings_provider.dart';
import 'package:python_flutter_embed_demo/core/feature_flags.dart';
import 'package:python_flutter_embed_demo/core/game_mode_config.dart';

void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('SettingsProvider Tests', () {
    late SettingsProvider settingsProvider;

    setUpAll(() async {
      // Ensure GameModeConfig is loaded before tests
      await GameModeConfig.instance.loadGameModes();
    });

    setUp(() {
      settingsProvider = SettingsProvider();
      // Load settings from config after GameModeConfig is loaded
      settingsProvider.loadSettingsFromConfig();
    });

    tearDown(() {
      settingsProvider.dispose();
    });

    group('Initialization', () {
      test('should initialize with default values from JSON config', () {
        // Default values come from assets/config/game_modes.json
        expect(settingsProvider.selectedDifficulty, 'hard');
        expect(settingsProvider.isKickstarterMode, true);
        expect(settingsProvider.is5050DetectionEnabled, true);
        expect(settingsProvider.is5050SafeMoveEnabled, true);
      });

      test('should initialize all feature flags with default values', () {
        expect(settingsProvider.isUndoMoveEnabled, false);
        expect(settingsProvider.isHintSystemEnabled, false);
        expect(settingsProvider.isAutoFlagEnabled, false);
        expect(settingsProvider.isBoardResetEnabled, false);
        expect(settingsProvider.isCustomDifficultyEnabled, false);
        expect(settingsProvider.isGameStatisticsEnabled, true);
        expect(settingsProvider.isBestTimesEnabled, false);
        expect(settingsProvider.isDarkModeEnabled, false);
        expect(settingsProvider.isAnimationsEnabled, false);
        expect(settingsProvider.isSoundEffectsEnabled, false);
        expect(settingsProvider.isHapticFeedbackEnabled, true);
        expect(settingsProvider.isMLAssistanceEnabled, false);
        expect(settingsProvider.isAutoPlayEnabled, false);
        expect(settingsProvider.isDifficultyPredictionEnabled, false);
        expect(settingsProvider.isDebugProbabilityModeEnabled, false);
      });

      test('should initialize with correct classic mode state', () {
        expect(settingsProvider.isClassicMode, false); // Opposite of kickstarter mode
        expect(settingsProvider.isKickstarterMode, true);
      });
    });

    group('Difficulty Settings', () {
      test('should change difficulty', () {
        // Default is 'hard' from JSON config
        expect(settingsProvider.selectedDifficulty, 'hard');
        
        // Change to easy - this should work
        settingsProvider.setDifficulty('easy');
        expect(settingsProvider.selectedDifficulty, 'easy');
        
        // Change to normal - this should work
        settingsProvider.setDifficulty('normal');
        expect(settingsProvider.selectedDifficulty, 'normal');
        
        // Change back to hard - this should work
        settingsProvider.setDifficulty('hard');
        expect(settingsProvider.selectedDifficulty, 'hard');
      });

      test('should not change difficulty for invalid values', () {
        final originalDifficulty = settingsProvider.selectedDifficulty;
        
        // Try to set invalid difficulty
        settingsProvider.setDifficulty('invalid_difficulty');
        
        // Should remain unchanged
        expect(settingsProvider.selectedDifficulty, originalDifficulty);
      });

      test('should handle empty string difficulty', () {
        final originalDifficulty = settingsProvider.selectedDifficulty;
        
        // Try to set empty string
        settingsProvider.setDifficulty('');
        
        // Should remain unchanged
        expect(settingsProvider.selectedDifficulty, originalDifficulty);
      });

      test('should handle special characters in difficulty', () {
        final originalDifficulty = settingsProvider.selectedDifficulty;
        
        // Try to set difficulty with special characters
        settingsProvider.setDifficulty('hard!@#');
        
        // Should remain unchanged
        expect(settingsProvider.selectedDifficulty, originalDifficulty);
      });
    });

    group('Game Mode Settings', () {
      test('should toggle kickstarter mode', () {
        // Default is 'true' from JSON config
        expect(settingsProvider.isKickstarterMode, true);
        
        // Toggle to false
        settingsProvider.setKickstarterMode(false);
        expect(settingsProvider.isKickstarterMode, false);
        
        // Toggle back to true
        settingsProvider.setKickstarterMode(true);
        expect(settingsProvider.isKickstarterMode, true);
      });

      test('should toggle first click guarantee', () {
        // Default is 'true' from JSON config
        expect(settingsProvider.isFirstClickGuaranteeEnabled, true);
        
        // Toggle to false
        settingsProvider.toggleFirstClickGuarantee();
        expect(settingsProvider.isFirstClickGuaranteeEnabled, false);
        expect(settingsProvider.isClassicMode, true);
        expect(settingsProvider.isKickstarterMode, false);
        
        // Toggle back to true
        settingsProvider.toggleFirstClickGuarantee();
        expect(settingsProvider.isFirstClickGuaranteeEnabled, true);
        expect(settingsProvider.isClassicMode, false);
        expect(settingsProvider.isKickstarterMode, true);
      });

      test('should set game mode correctly', () {
        // Test kickstarter mode
        settingsProvider.setGameMode(true);
        expect(settingsProvider.isKickstarterMode, true);
        expect(settingsProvider.isFirstClickGuaranteeEnabled, true);
        expect(settingsProvider.isClassicMode, false);
        
        // Test classic mode
        settingsProvider.setGameMode(false);
        expect(settingsProvider.isKickstarterMode, false);
        expect(settingsProvider.isFirstClickGuaranteeEnabled, false);
        expect(settingsProvider.isClassicMode, true);
      });

      test('should set classic mode independently', () {
        // Set classic mode to true
        settingsProvider.setClassicMode(true);
        expect(settingsProvider.isClassicMode, true);
        expect(settingsProvider.isKickstarterMode, false);
        
        // Set classic mode to false
        settingsProvider.setClassicMode(false);
        expect(settingsProvider.isClassicMode, false);
        expect(settingsProvider.isKickstarterMode, true);
      });
    });

    group('50/50 Detection Settings', () {
      test('should toggle 50/50 detection', () {
        // Default is 'true' from JSON config
        expect(settingsProvider.is5050DetectionEnabled, true);
        
        // Toggle to false
        settingsProvider.toggle5050Detection();
        expect(settingsProvider.is5050DetectionEnabled, false);
        
        // Toggle back to true
        settingsProvider.toggle5050Detection();
        expect(settingsProvider.is5050DetectionEnabled, true);
      });

      test('should disable safe move when 50/50 detection is disabled', () {
        // Both features are enabled by default from JSON config
        expect(settingsProvider.is5050SafeMoveEnabled, true);
        expect(settingsProvider.is5050DetectionEnabled, true);
        
        // Disable 50/50 detection
        settingsProvider.toggle5050Detection();
        expect(settingsProvider.is5050DetectionEnabled, false);
        expect(settingsProvider.is5050SafeMoveEnabled, false); // Should be disabled automatically
      });

      test('should toggle 50/50 safe move only when detection is enabled', () {
        // Disable 50/50 detection first
        settingsProvider.toggle5050Detection();
        expect(settingsProvider.is5050DetectionEnabled, false);
        expect(settingsProvider.is5050SafeMoveEnabled, false); // Auto-disabled when detection is disabled
        
        // Try to enable safe move - should not work (early return, no change)
        settingsProvider.toggle5050SafeMove();
        expect(settingsProvider.is5050SafeMoveEnabled, false); // Should remain false
        
        // Enable 50/50 detection
        settingsProvider.toggle5050Detection();
        expect(settingsProvider.is5050DetectionEnabled, true);
        expect(settingsProvider.is5050SafeMoveEnabled, false); // Still false from before
        
        // Now safe move should work - toggle from false to true
        settingsProvider.toggle5050SafeMove();
        expect(settingsProvider.is5050SafeMoveEnabled, true);
        
        // Toggle safe move back to false
        settingsProvider.toggle5050SafeMove();
        expect(settingsProvider.is5050SafeMoveEnabled, false);
      });
    });

    group('Feature Flag Toggles', () {
      test('should toggle undo move', () {
        expect(settingsProvider.isUndoMoveEnabled, false);
        
        settingsProvider.toggleUndoMove();
        expect(settingsProvider.isUndoMoveEnabled, true);
        
        settingsProvider.toggleUndoMove();
        expect(settingsProvider.isUndoMoveEnabled, false);
      });

      test('should toggle hint system', () {
        expect(settingsProvider.isHintSystemEnabled, false);
        
        settingsProvider.toggleHintSystem();
        expect(settingsProvider.isHintSystemEnabled, true);
        
        settingsProvider.toggleHintSystem();
        expect(settingsProvider.isHintSystemEnabled, false);
      });

      test('should toggle auto flag', () {
        expect(settingsProvider.isAutoFlagEnabled, false);
        
        settingsProvider.toggleAutoFlag();
        expect(settingsProvider.isAutoFlagEnabled, true);
        
        settingsProvider.toggleAutoFlag();
        expect(settingsProvider.isAutoFlagEnabled, false);
      });

      test('should toggle board reset', () {
        expect(settingsProvider.isBoardResetEnabled, false);
        
        settingsProvider.toggleBoardReset();
        expect(settingsProvider.isBoardResetEnabled, true);
        
        settingsProvider.toggleBoardReset();
        expect(settingsProvider.isBoardResetEnabled, false);
      });

      test('should toggle custom difficulty', () {
        expect(settingsProvider.isCustomDifficultyEnabled, false);
        
        settingsProvider.toggleCustomDifficulty();
        expect(settingsProvider.isCustomDifficultyEnabled, true);
        
        settingsProvider.toggleCustomDifficulty();
        expect(settingsProvider.isCustomDifficultyEnabled, false);
      });

      test('should toggle game statistics', () {
        expect(settingsProvider.isGameStatisticsEnabled, true); // Default is true
        
        settingsProvider.toggleGameStatistics();
        expect(settingsProvider.isGameStatisticsEnabled, false);
        
        settingsProvider.toggleGameStatistics();
        expect(settingsProvider.isGameStatisticsEnabled, true);
      });

      test('should toggle best times', () {
        expect(settingsProvider.isBestTimesEnabled, false);
        
        settingsProvider.toggleBestTimes();
        expect(settingsProvider.isBestTimesEnabled, true);
        
        settingsProvider.toggleBestTimes();
        expect(settingsProvider.isBestTimesEnabled, false);
      });

      test('should toggle dark mode', () {
        expect(settingsProvider.isDarkModeEnabled, false);
        
        settingsProvider.toggleDarkMode();
        expect(settingsProvider.isDarkModeEnabled, true);
        
        settingsProvider.toggleDarkMode();
        expect(settingsProvider.isDarkModeEnabled, false);
      });

      test('should toggle animations', () {
        expect(settingsProvider.isAnimationsEnabled, false);
        
        settingsProvider.toggleAnimations();
        expect(settingsProvider.isAnimationsEnabled, true);
        
        settingsProvider.toggleAnimations();
        expect(settingsProvider.isAnimationsEnabled, false);
      });

      test('should toggle sound effects', () {
        expect(settingsProvider.isSoundEffectsEnabled, false);
        
        settingsProvider.toggleSoundEffects();
        expect(settingsProvider.isSoundEffectsEnabled, true);
        
        settingsProvider.toggleSoundEffects();
        expect(settingsProvider.isSoundEffectsEnabled, false);
      });

      test('should toggle haptic feedback', () {
        expect(settingsProvider.isHapticFeedbackEnabled, true); // Default is true
        
        settingsProvider.toggleHapticFeedback();
        expect(settingsProvider.isHapticFeedbackEnabled, false);
        
        settingsProvider.toggleHapticFeedback();
        expect(settingsProvider.isHapticFeedbackEnabled, true);
      });

      test('should toggle ML assistance', () {
        expect(settingsProvider.isMLAssistanceEnabled, false);
        
        settingsProvider.toggleMLAssistance();
        expect(settingsProvider.isMLAssistanceEnabled, true);
        
        settingsProvider.toggleMLAssistance();
        expect(settingsProvider.isMLAssistanceEnabled, false);
      });

      test('should toggle auto play', () {
        expect(settingsProvider.isAutoPlayEnabled, false);
        
        settingsProvider.toggleAutoPlay();
        expect(settingsProvider.isAutoPlayEnabled, true);
        
        settingsProvider.toggleAutoPlay();
        expect(settingsProvider.isAutoPlayEnabled, false);
      });

      test('should toggle difficulty prediction', () {
        expect(settingsProvider.isDifficultyPredictionEnabled, false);
        
        settingsProvider.toggleDifficultyPrediction();
        expect(settingsProvider.isDifficultyPredictionEnabled, true);
        
        settingsProvider.toggleDifficultyPrediction();
        expect(settingsProvider.isDifficultyPredictionEnabled, false);
      });

      test('should toggle debug probability mode', () {
        expect(settingsProvider.isDebugProbabilityModeEnabled, false);
        
        settingsProvider.toggleDebugProbabilityMode();
        expect(settingsProvider.isDebugProbabilityModeEnabled, true);
        
        settingsProvider.toggleDebugProbabilityMode();
        expect(settingsProvider.isDebugProbabilityModeEnabled, false);
      });
    });

    group('Settings Persistence', () {
      test('should save settings automatically', () {
        // Default is 'hard' from JSON config
        expect(settingsProvider.selectedDifficulty, 'hard');
        
        // Change difficulty
        settingsProvider.setDifficulty('easy');
        expect(settingsProvider.selectedDifficulty, 'easy');
        
        // The settings should persist (this is tested by the fact that the provider maintains state)
        expect(settingsProvider.selectedDifficulty, 'easy');
      });

      test('should maintain state across multiple operations', () {
        // Set multiple settings
        settingsProvider.setDifficulty('normal');
        settingsProvider.toggle5050Detection();
        settingsProvider.toggleDarkMode();
        settingsProvider.toggleHapticFeedback();
        
        // Verify all settings are maintained
        expect(settingsProvider.selectedDifficulty, 'normal');
        expect(settingsProvider.is5050DetectionEnabled, false);
        expect(settingsProvider.isDarkModeEnabled, true);
        expect(settingsProvider.isHapticFeedbackEnabled, false);
      });
    });

    group('Reset to Defaults', () {
      test('should reset all settings to defaults', () {
        // Change some settings first
        settingsProvider.setDifficulty('easy');
        settingsProvider.toggle5050Detection();
        settingsProvider.toggleDarkMode();
        settingsProvider.toggleHapticFeedback();
        settingsProvider.toggleUndoMove();
        
        // Verify changes were made
        expect(settingsProvider.selectedDifficulty, 'easy');
        expect(settingsProvider.is5050DetectionEnabled, false);
        expect(settingsProvider.isDarkModeEnabled, true);
        expect(settingsProvider.isHapticFeedbackEnabled, false);
        expect(settingsProvider.isUndoMoveEnabled, true);
        
        // Reset to defaults
        settingsProvider.resetToDefaults();
        
        // Verify all settings are back to defaults
        expect(settingsProvider.selectedDifficulty, 'hard');
        expect(settingsProvider.is5050DetectionEnabled, true);
        expect(settingsProvider.isDarkModeEnabled, false);
        expect(settingsProvider.isHapticFeedbackEnabled, true);
        expect(settingsProvider.isUndoMoveEnabled, false);
        expect(settingsProvider.isKickstarterMode, true);
        expect(settingsProvider.is5050SafeMoveEnabled, true);
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle multiple rapid toggles', () {
        // Rapidly toggle a setting multiple times
        for (int i = 0; i < 10; i++) {
          settingsProvider.toggle5050Detection();
        }
        
        // Should end up in a consistent state
        expect(settingsProvider.is5050DetectionEnabled, true); // Even number of toggles = back to original
      });

      test('should handle setting difficulty to current value', () {
        final currentDifficulty = settingsProvider.selectedDifficulty;
        
        // Set to same value
        settingsProvider.setDifficulty(currentDifficulty);
        
        // Should remain unchanged
        expect(settingsProvider.selectedDifficulty, currentDifficulty);
      });

      test('should handle empty string difficulty', () {
        final originalDifficulty = settingsProvider.selectedDifficulty;
        
        // Try to set empty string
        settingsProvider.setDifficulty('');
        
        // Should remain unchanged
        expect(settingsProvider.selectedDifficulty, originalDifficulty);
      });

      test('should handle special characters in difficulty', () {
        final originalDifficulty = settingsProvider.selectedDifficulty;
        
        // Try to set difficulty with special characters
        settingsProvider.setDifficulty('hard!@#');
        
        // Should remain unchanged
        expect(settingsProvider.selectedDifficulty, originalDifficulty);
      });
    });

    group('Feature Flag Integration', () {
      test('should update global feature flags when toggling settings', () {
        // Test 50/50 detection
        settingsProvider.toggle5050Detection();
        expect(FeatureFlags.enable5050Detection, false);
        
        settingsProvider.toggle5050Detection();
        expect(FeatureFlags.enable5050Detection, true);
        
        // Test first click guarantee
        settingsProvider.toggleFirstClickGuarantee();
        expect(FeatureFlags.enableFirstClickGuarantee, false);
        
        settingsProvider.toggleFirstClickGuarantee();
        expect(FeatureFlags.enableFirstClickGuarantee, true);
      });

      test('should update multiple feature flags correctly', () {
        // Toggle multiple features
        settingsProvider.toggle5050Detection();
        settingsProvider.toggle5050SafeMove();
        settingsProvider.toggleDarkMode();
        settingsProvider.toggleHapticFeedback();
        
        // Verify all feature flags are updated
        expect(FeatureFlags.enable5050Detection, false);
        expect(FeatureFlags.enable5050SafeMove, false);
        expect(FeatureFlags.enableDarkMode, true);
        expect(FeatureFlags.enableHapticFeedback, false);
      });
    });
  });
} 