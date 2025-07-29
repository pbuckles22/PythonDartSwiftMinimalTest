import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/game_provider.dart';
import '../../core/game_mode_config.dart';
import '../../core/icon_utils.dart';

class SettingsPage extends StatelessWidget {
  final bool closeOnChange;
  
  const SettingsPage({Key? key, this.closeOnChange = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Game Mode Section
              _buildSectionHeader(context, 'General Gameplay'),
              const SizedBox(height: 8),
              _buildGameModeToggle(context, settingsProvider),
              const SizedBox(height: 8),
              _buildKickstarterToggle(context, settingsProvider),
              const SizedBox(height: 8),
              _buildGeneralGameplayToggles(context, settingsProvider),
              const SizedBox(height: 24),
              // Appearance & UX Section
              _buildSectionHeader(context, 'Appearance & UX'),
              const SizedBox(height: 8),
              _buildAppearanceToggles(context, settingsProvider),
              const SizedBox(height: 24),
              // Advanced/Experimental Section
              _buildSectionHeader(context, 'Advanced / Experimental'),
              const SizedBox(height: 8),
              _buildAdvancedToggles(context, settingsProvider),
              const SizedBox(height: 24),
              // Board Size Section
              _buildSectionHeader(context, 'Board Size'),
              const SizedBox(height: 8),
              _buildDifficultySelection(context, settingsProvider),
              const SizedBox(height: 24),
              // Reset to Defaults
              _buildResetButton(context, settingsProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildGameModeToggle(BuildContext context, SettingsProvider settingsProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            settingsProvider.isClassicMode ? 'Classic Mode' : 'Modern Mode',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: settingsProvider.isClassicMode 
                                ? 'Classic Mode: Traditional Minesweeper rules. Your first click could hit a mine, reveal a single numbered cell, or trigger a cascade. Pure random chance.'
                                : 'Modern Mode: Enhanced Minesweeper with additional features and improved gameplay.',
                            child: Icon(
                              Icons.help_outline,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        settingsProvider.isClassicMode 
                            ? 'Classic Minesweeper rules'
                            : 'Enhanced Minesweeper with modern features',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settingsProvider.isClassicMode,
                  onChanged: (value) {
                    _handleGameModeChange(context, settingsProvider, !value);
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKickstarterToggle(BuildContext context, SettingsProvider settingsProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Kickstarter Mode',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Kickstarter Mode: Your first click will always reveal a cascade (blank area), giving you a meaningful starting position. Mines are intelligently moved to ensure this happens.',
                            child: Icon(
                              Icons.help_outline,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'First click always reveals a cascade',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settingsProvider.isKickstarterMode,
                  onChanged: (value) {
                    settingsProvider.setKickstarterMode(value);
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _build5050DetectionToggle(BuildContext context, SettingsProvider settingsProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '50/50 Detection',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Detects classic Minesweeper 50/50 situations where two cells have equal probability of being mines. These cells will be highlighted with an orange border and help icon.',
                            child: Icon(
                              Icons.help_outline,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Highlight unsolvable situations',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settingsProvider.is5050DetectionEnabled,
                  onChanged: (value) {
                    settingsProvider.toggle5050Detection();
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _build5050SafeMoveToggle(BuildContext context, SettingsProvider settingsProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '50/50 Safe Move',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'When enabled, clicking on a 50/50 cell will automatically choose the safer option. This helps avoid frustrating random guesses.',
                            child: Icon(
                              Icons.help_outline,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Auto-resolve 50/50 situations',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settingsProvider.is5050SafeMoveEnabled,
                  onChanged: (value) {
                    settingsProvider.toggle5050SafeMove();
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _build5050Description(BuildContext context, SettingsProvider settingsProvider) {
    if (!settingsProvider.is5050DetectionEnabled) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 1,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '50/50 Detection Active',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Cells in 50/50 situations will be highlighted with an orange border and help icon. This helps you identify when you\'re forced to make a random guess versus when there\'s a logical solution available.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (settingsProvider.is5050SafeMoveEnabled) ...[
              const SizedBox(height: 8),
              Text(
                'Safe Move is enabled: Clicking on 50/50 cells will automatically choose the safer option.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleGameModeChange(
    BuildContext context,
    SettingsProvider settingsProvider,
    bool newValue,
  ) {
    // Check if there's an active game
    final gameProvider = context.read<GameProvider>();
    final hasActiveGame = gameProvider.gameState != null && 
                         gameProvider.gameState!.gameStatus == 'playing';
    
    if (hasActiveGame) {
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Game in Progress'),
          content: const Text(
            'You have a game in progress. Changing the game mode will start a new game. Do you want to continue?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _applyGameModeChange(context, settingsProvider, gameProvider, newValue);
              },
              child: const Text('Start New Game'),
            ),
          ],
        ),
      );
    } else {
      // No active game, just change mode
      _applyGameModeChange(context, settingsProvider, gameProvider, newValue);
    }
  }

  void _applyGameModeChange(
    BuildContext context,
    SettingsProvider settingsProvider,
    GameProvider gameProvider,
    bool newValue,
  ) {
    // Update settings first - only change classic mode, preserve kickstarter
    settingsProvider.setClassicMode(newValue);
    
    // Force reset repository to ensure it picks up new feature flags
    gameProvider.forceResetRepository();
    
    // Reset game with new mode
    if (gameProvider.isGameInitialized) {
      gameProvider.initializeGame(settingsProvider.selectedDifficulty);
    }
    // Close settings page to make behavior consistent with difficulty changes
    if (closeOnChange) Navigator.of(context).pop();
  }

  Widget _buildModeDescription(BuildContext context, SettingsProvider settingsProvider) {
    return Card(
      elevation: 1,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  settingsProvider.isKickstarterMode ? Icons.auto_awesome : Icons.sports_esports,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  settingsProvider.isKickstarterMode ? 'Kickstarter Mode' : 'Classic Mode',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              settingsProvider.isKickstarterMode
                  ? 'The first click will always reveal a cascade (blank area), giving you a meaningful starting position. Mines are intelligently moved to ensure this happens.'
                  : 'Traditional Minesweeper rules. The first click could hit a mine, revealing a single numbered cell, or trigger a cascade. Pure random chance.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultySelection(BuildContext context, SettingsProvider settingsProvider) {
    return Card(
      key: const Key('difficulty-section'),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Difficulty',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Dynamic difficulty options from JSON config
            ...GameModeConfig.instance.enabledGameModes.map((mode) {
              return Column(
                children: [
                  _buildDifficultyOption(
                    context,
                    settingsProvider,
                    mode.name,
                    mode.description,
                    mode.id,
                    IconUtils.getIconFromString(mode.icon) ?? Icons.games,
                  ),
                  const SizedBox(height: 8),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(
    BuildContext context,
    SettingsProvider settingsProvider,
    String title,
    String subtitle,
    String difficulty,
    IconData icon,
  ) {
    final isSelected = settingsProvider.selectedDifficulty == difficulty;
    
    return InkWell(
      onTap: () {
        _handleDifficultyChange(context, settingsProvider, difficulty);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _handleDifficultyChange(
    BuildContext context,
    SettingsProvider settingsProvider,
    String newDifficulty,
  ) {
    // Check if there's an active game
    final gameProvider = context.read<GameProvider>();
    final hasActiveGame = gameProvider.gameState != null && 
                         gameProvider.gameState!.gameStatus == 'playing';
    
    if (hasActiveGame) {
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Game in Progress'),
          content: const Text(
            'You have a game in progress. Changing the difficulty will start a new game. Do you want to continue?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _applyDifficultyChange(context, settingsProvider, gameProvider, newDifficulty);
              },
              child: const Text('Start New Game'),
            ),
          ],
        ),
      );
    } else {
      // No active game, just change difficulty
      _applyDifficultyChange(context, settingsProvider, gameProvider, newDifficulty);
    }
  }

  void _applyDifficultyChange(
    BuildContext context,
    SettingsProvider settingsProvider,
    GameProvider gameProvider,
    String newDifficulty,
  ) {
    settingsProvider.setDifficulty(newDifficulty);
    // Force reset repository to ensure clean state
    gameProvider.forceResetRepository();
    // Start new game with new difficulty
    gameProvider.initializeGame(newDifficulty);
    // Close settings page
    if (closeOnChange) Navigator.of(context).pop();
  }

  Widget _buildResetButton(BuildContext context, SettingsProvider settingsProvider) {
    return Card(
      key: const Key('reset-button'),
      elevation: 1,
      child: ListTile(
        leading: const Icon(Icons.restore),
        title: const Text('Reset to Defaults'),
        subtitle: const Text('Restore all settings to their default values'),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Reset Settings'),
              content: const Text('Are you sure you want to reset all settings to their default values?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    settingsProvider.resetToDefaults();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings reset to defaults'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- New Section: General Gameplay Toggles ---
  Widget _buildGeneralGameplayToggles(BuildContext context, SettingsProvider settingsProvider) {
    return Column(
      children: [
        _buildSimpleToggle(
          context,
          'Undo Move',
          'Enable undoing your last move',
          settingsProvider.isUndoMoveEnabled,
          settingsProvider.toggleUndoMove,
          disabled: true,
        ),
        _buildSimpleToggle(
          context,
          'Hint System',
          'Show hints for possible safe moves',
          settingsProvider.isHintSystemEnabled,
          settingsProvider.toggleHintSystem,
          disabled: true,
        ),
        _buildSimpleToggle(
          context,
          'Auto-Flag',
          'Automatically flag obvious mines',
          settingsProvider.isAutoFlagEnabled,
          settingsProvider.toggleAutoFlag,
          disabled: true,
        ),
        _buildSimpleToggle(
          context,
          'Board Reset',
          'Allow resetting the board mid-game',
          settingsProvider.isBoardResetEnabled,
          settingsProvider.toggleBoardReset,
          disabled: true,
        ),
        _buildSimpleToggle(
          context,
          'Custom Difficulty',
          'Enable custom board size and mine count',
          settingsProvider.isCustomDifficultyEnabled,
          settingsProvider.toggleCustomDifficulty,
          disabled: true,
        ),
        _buildSimpleToggle(
          context,
          'Game Statistics',
          'Show timer and statistics',
          settingsProvider.isGameStatisticsEnabled,
          settingsProvider.toggleGameStatistics,
          disabled: false,
        ),
        _buildSimpleToggle(
          context,
          'Best Times',
          'Track and display best times',
          settingsProvider.isBestTimesEnabled,
          settingsProvider.toggleBestTimes,
          disabled: true,
        ),
      ],
    );
  }

  // --- New Section: Appearance & UX Toggles ---
  Widget _buildAppearanceToggles(BuildContext context, SettingsProvider settingsProvider) {
    return Column(
      children: [
        _buildSimpleToggle(
          context,
          'Dark Mode',
          'Enable dark theme',
          settingsProvider.isDarkModeEnabled,
          settingsProvider.toggleDarkMode,
          disabled: true,
        ),
        _buildSimpleToggle(
          context,
          'Animations',
          'Enable smooth animations',
          settingsProvider.isAnimationsEnabled,
          settingsProvider.toggleAnimations,
          disabled: true,
        ),
        _buildSimpleToggle(
          context,
          'Sound Effects',
          'Enable sound effects',
          settingsProvider.isSoundEffectsEnabled,
          settingsProvider.toggleSoundEffects,
          disabled: true,
        ),
        _buildSimpleToggle(
          context,
          'Haptic Feedback',
          'Enable vibration/haptic feedback',
          settingsProvider.isHapticFeedbackEnabled,
          settingsProvider.toggleHapticFeedback,
          disabled: false,
        ),
      ],
    );
  }

  // --- New Section: Advanced/Experimental Toggles ---
  Widget _buildAdvancedToggles(BuildContext context, SettingsProvider settingsProvider) {
    return Column(
      children: [
        _build5050DetectionToggle(context, settingsProvider),
        _build5050SafeMoveToggle(context, settingsProvider),
        _buildSimpleToggle(
          context,
          'Debug Probability Mode',
          'Enable debug buttons and probability analysis features',
          settingsProvider.isDebugProbabilityModeEnabled,
          settingsProvider.toggleDebugProbabilityMode,
          disabled: false,
        ),
        _buildSimpleToggle(
          context,
          'ML Assistance',
          'Enable machine learning assistance',
          settingsProvider.isMLAssistanceEnabled,
          settingsProvider.toggleMLAssistance,
          disabled: true,
        ),
        _buildSimpleToggle(
          context,
          'Auto-Play',
          'Automatically play the game',
          settingsProvider.isAutoPlayEnabled,
          settingsProvider.toggleAutoPlay,
          disabled: true,
        ),
        _buildSimpleToggle(
          context,
          'Difficulty Prediction',
          'Predict difficulty using AI',
          settingsProvider.isDifficultyPredictionEnabled,
          settingsProvider.toggleDifficultyPrediction,
          disabled: true,
        ),
      ],
    );
  }

  // --- Helper for simple toggles ---
  Widget _buildSimpleToggle(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    void Function() onToggle,
    {bool disabled = false}
  ) {
    return Tooltip(
      message: disabled ? 'This feature is not yet implemented.' : '',
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: disabled ? Theme.of(context).disabledColor : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: disabled ? null : (_) => onToggle(),
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveThumbColor: disabled ? Theme.of(context).disabledColor : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 