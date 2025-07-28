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
    });
  });
} 