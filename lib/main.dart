import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'presentation/providers/game_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'core/game_mode_config.dart';
import 'core/feature_flags.dart';
import 'presentation/pages/game_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Validate game configuration before app starts
  try {
    await GameModeConfig.instance.loadGameModes();
    // Set all feature flags from JSON config
    final featureFlagMap = GameModeConfig.instance.defaultFeatureFlags;
    // Map JSON keys to FeatureFlags static fields
    FeatureFlags.enableFirstClickGuarantee = featureFlagMap['kickstarter_mode'] ?? false;
    FeatureFlags.enable5050Detection = featureFlagMap['5050_detection'] ?? false;
    FeatureFlags.enable5050SafeMove = featureFlagMap['5050_safe_move'] ?? false;
    FeatureFlags.enableGameStatistics = featureFlagMap['game_statistics'] ?? false;
    FeatureFlags.enableBoardReset = featureFlagMap['board_reset'] ?? false;
    FeatureFlags.enableCustomDifficulty = featureFlagMap['custom_difficulty'] ?? false;
    FeatureFlags.enableUndoMove = featureFlagMap['undo_move'] ?? false;
    FeatureFlags.enableHintSystem = featureFlagMap['hint_system'] ?? false;
    FeatureFlags.enableAutoFlag = featureFlagMap['auto_flag'] ?? false;
    FeatureFlags.enableBestTimes = featureFlagMap['best_times'] ?? false;
    FeatureFlags.enableDarkMode = featureFlagMap['dark_mode'] ?? false;
    FeatureFlags.enableAnimations = featureFlagMap['animations'] ?? false;
    FeatureFlags.enableSoundEffects = featureFlagMap['sound_effects'] ?? false;
    FeatureFlags.enableHapticFeedback = featureFlagMap['haptic_feedback'] ?? false;
    FeatureFlags.enableMLAssistance = featureFlagMap['ml_assistance'] ?? false;
    FeatureFlags.enableAutoPlay = featureFlagMap['auto_play'] ?? false;
    FeatureFlags.enableDifficultyPrediction = featureFlagMap['difficulty_prediction'] ?? false;
    FeatureFlags.enableDebugMode = featureFlagMap['debug_mode'] ?? false;
    FeatureFlags.enableDebugProbabilityMode = featureFlagMap['debug_probability_mode'] ?? false;
    FeatureFlags.enablePerformanceMetrics = featureFlagMap['performance_metrics'] ?? false;
    FeatureFlags.enableTestMode = featureFlagMap['test_mode'] ?? false;
    
    print('DEBUG: main - FeatureFlags initialized from JSON:');
    print('DEBUG:   Raw featureFlagMap: $featureFlagMap');
    print('DEBUG:   enableFirstClickGuarantee: ${FeatureFlags.enableFirstClickGuarantee}');
    print('DEBUG:   enable5050Detection: ${FeatureFlags.enable5050Detection}');
    print('DEBUG:   enable5050SafeMove: ${FeatureFlags.enable5050SafeMove}');
    
    print('Game configuration validation passed');
  } catch (e) {
    // print('CRITICAL ERROR: Game configuration validation failed: $e');
    // print('App will exit due to configuration error.');
    // Force exit the app immediately
    exit(1);
  }
  
  runApp(const MinesweeperApp());
}

// Hot reload support for development
void hotReload() async {
  await GameModeConfig.instance.reload();
}

class MinesweeperApp extends StatelessWidget {
  const MinesweeperApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            final settingsProvider = SettingsProvider();
            // Load settings from config after GameModeConfig is already loaded
            settingsProvider.loadSettingsFromConfig();
            return settingsProvider;
          },
        ),
        ChangeNotifierProvider(create: (context) => GameProvider()),
      ],
      child: MaterialApp(
        title: 'Minesweeper with ML',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const GamePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}