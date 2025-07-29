import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/game_board.dart';
import '../widgets/game_over_dialog.dart';
import 'settings_page.dart';
import '../../core/constants.dart';
import '../../core/feature_flags.dart';
import '../../services/timer_service.dart';

class GamePage extends StatefulWidget {
  const GamePage({Key? key}) : super(key: key);

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  bool _showGameOverDialog = false;

  // Add GlobalKey and height for bottom bar
  final GlobalKey _bottomBarKey = GlobalKey();
  double _bottomBarHeight = 0.0;

  @override
  void initState() {
    super.initState();
    // Initialize game when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = context.read<SettingsProvider>();
      context.read<GameProvider>().initializeGame(settingsProvider.selectedDifficulty);
    });
    
    // Probability callback will be set when probability mode is enabled
  }

  // Helper method to determine if we're in landscape mode
  bool _isLandscape(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width > size.height;
  }

  // Helper method to determine if we're on a phone (not tablet)
  bool _isPhone(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width < 600; // Standard breakpoint for phones
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = _isLandscape(context);
    final isPhone = _isPhone(context);
    final isPhoneLandscape = isLandscape && isPhone;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minesweeper with ML'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Debug buttons - only show when debug probability mode is enabled
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              if (settingsProvider.isDebugProbabilityModeEnabled) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.code),
                      onPressed: _testPython,
                      tooltip: "Test Python Integration",
                    ),
                    IconButton(
                      icon: const Icon(Icons.psychology),
                      onPressed: _test5050Detection,
                      tooltip: "Test 50/50 Detection",
                    ),
                    IconButton(
                      icon: const Icon(Icons.analytics),
                      onPressed: _enableProbabilityMode,
                      tooltip: "Enable Probability Mode (long-press cells)",
                    ),
                    IconButton(
                      icon: const Icon(Icons.bug_report),
                      onPressed: _saveBoardStateForDebug,
                      tooltip: "Save Board State for Debug",
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _debugSpecificCase,
                      tooltip: "Debug Cell (4,0) Case",
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          // Show game over dialog when game ends
          if (gameProvider.isGameOver && !_showGameOverDialog) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showGameOverDialog = true;
              _showGameOverModal(context, gameProvider);
            });
          }

          if (gameProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (gameProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${gameProvider.error}',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final settingsProvider = context.read<SettingsProvider>();
                      gameProvider.initializeGame(settingsProvider.selectedDifficulty);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Measure bottom bar height after layout
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final barContext = _bottomBarKey.currentContext;
            final barHeight = barContext?.size?.height;
            if (barHeight != null && barHeight != _bottomBarHeight) {
              setState(() {
                _bottomBarHeight = barHeight;
              });
              // print('DEBUG: Measured real bottom bar height: $_bottomBarHeight');
            }
          });

          // Use different layout for phone landscape mode
          if (isPhoneLandscape) {
            return _buildPhoneLandscapeLayout(context, gameProvider);
          } else {
            return _buildPortraitLayout(context, gameProvider);
          }
        },
      ),
    );
  }

  void _testPython() async {
    print("🚨🚨🚨 MANUAL PYTHON TEST BUTTON PRESSED 🚨🚨🚨");
    const pythonChannel = MethodChannel("python/minimal");
    try {
      print("🚨🚨🚨 About to call native addOneAndOne... 🚨🚨🚨");
      final value = await pythonChannel.invokeMethod("addOneAndOne");
      print("🚨🚨🚨 SUCCESS - Native returned: $value 🚨🚨🚨");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Python test: 1+1 = $value")),
      );
    } catch (e) {
      print("🚨🚨🚨 FAILED - Error: $e 🚨🚨🚨");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Python test failed: $e")),
      );
    }
  }

  void _test5050Detection() async {
    print("🔔 Dart: _test5050Detection() called from GamePage");
    
    final gameProvider = context.read<GameProvider>();
    
    // Use the real game state instead of test data
    if (gameProvider.gameState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No game state available")),
      );
      return;
    }
    
    try {
      // Call the real 50/50 detection with actual game state
      await gameProvider.updateFiftyFiftyDetection();
      
      final fiftyFiftyCells = gameProvider.fiftyFiftyCells;
      print("🔔 Dart: Real 50/50 detection found ${fiftyFiftyCells.length} cells: $fiftyFiftyCells");
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("50/50 Detection: Found ${fiftyFiftyCells.length} cells")),
      );
    } catch (e) {
      print("🔔 Dart: 50/50 detection error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("50/50 Error: $e")),
      );
    }
  }

  bool _probabilityModeEnabled = false;

  void _enableProbabilityMode() {
    _probabilityModeEnabled = !_probabilityModeEnabled;
    final message = _probabilityModeEnabled 
        ? "Probability mode ENABLED - long-press cells to see real probability"
        : "Probability mode DISABLED";
    
    // Set or clear the probability callback based on mode
    if (_probabilityModeEnabled) {
      GameProvider.onProbabilityAnalysisRequested = _showCellProbability;
    } else {
      GameProvider.onProbabilityAnalysisRequested = null;
      // Clear any existing highlighting
      context.read<GameProvider>().clearProbabilityHighlight();
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _probabilityModeEnabled ? Colors.green : Colors.grey,
      ),
    );
  }

  void _showCellProbability(int row, int col) {
    // Only show probability analysis if probability mode is enabled
    if (!_probabilityModeEnabled) {
      // Show a hint to enable probability mode
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enable Probability Mode first (analytics button)"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    final gameProvider = context.read<GameProvider>();
    final cell = gameProvider.gameState?.getCell(row, col);
    
    if (cell == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No cell data for ($row, $col)")),
      );
      return;
    }
    
    if (cell.isRevealed) {
      // Show revealed cell info in probability mode
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Cell ($row, $col) is revealed - value: ${cell.bombsAround}"),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }
    
    if (cell.isFlagged) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cell ($row, $col) is flagged")),
      );
      return;
    }
    
    // Calculate real probability for this cell
    final probability = gameProvider.calculateCellProbability(row, col);
    final probabilityPercent = (probability * 100).toStringAsFixed(1);
    
    // Get detailed debug information
    final debugInfo = gameProvider.debugProbabilityCalculation(row, col);
    
    // Log debug info to terminal for easy sharing
    print('🔍🔍🔍 PROBABILITY ANALYSIS FOR CELL ($row, $col) 🔍🔍🔍');
    print('🔍 Probability: $probabilityPercent%');
    print('🔍 Debug info: $debugInfo');
    
    // Set highlighting for all cells that factored into the calculation
    gameProvider.setProbabilityHighlight(row, col);
    
    // Show probability in snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cell ($row, $col): $probabilityPercent% probability'),
        duration: const Duration(seconds: 3),
        backgroundColor: probability > 0.4 && probability < 0.6 ? Colors.orange : Colors.blue,
        action: SnackBarAction(
          label: 'Details',
          onPressed: () {
            // Show detailed dialog with debug information
            showDialog(
              context: context,
              barrierDismissible: true, // Allow tapping outside to close
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Expanded(child: Text('Cell ($row, $col) Analysis')),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Probability: $probabilityPercent%', 
                           style: TextStyle(
                             fontSize: 18, 
                             fontWeight: FontWeight.bold,
                             color: probability > 0.4 && probability < 0.6 ? Colors.orange : Colors.black,
                           )),
                      const SizedBox(height: 16),
                      if (debugInfo.containsKey('targetCell')) ...[
                        Text('Target cell: (${debugInfo['targetCell']['row']}, ${debugInfo['targetCell']['col']})'),
                        Text('Has bomb: ${debugInfo['targetCell']['hasBomb']}'),
                        const SizedBox(height: 8),
                      ],
                      if (debugInfo.containsKey('calculation')) ...[
                        Text('Calculation:'),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• Contributing neighbors: ${debugInfo['calculation']['contributingNeighbors']}'),
                              Text('• Total probability: ${debugInfo['calculation']['totalProbability'].toStringAsFixed(3)}'),
                              Text('• Final probability: ${debugInfo['calculation']['finalProbability'].toStringAsFixed(3)}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (debugInfo.containsKey('revealedNeighbors') && debugInfo['revealedNeighbors'].isNotEmpty) ...[
                        Text('Revealed neighbors:'),
                        Text('(Debug info available in console)'),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    
    // Clear highlighting after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      gameProvider.clearProbabilityHighlight();
    });
  }

  void _saveBoardStateForDebug() {
    final gameProvider = context.read<GameProvider>();
    gameProvider.saveBoardStateForDebug();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Board state saved - check console for details"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _debugSpecificCase() {
    final gameProvider = context.read<GameProvider>();
    gameProvider.debugSpecificCase();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Cell (4,0) case debugged - check console for details"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  void _showGameOverModal(BuildContext context, GameProvider gameProvider) {
    final gameState = gameProvider.gameState!;
    final isWin = gameProvider.isGameWon;
    final gameDuration = gameProvider.timerService.elapsed;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameOverDialog(
        isWin: isWin,
        gameDuration: gameDuration,
        onNewGame: () {
          Navigator.of(context).pop();
          _showGameOverDialog = false;
          final settingsProvider = context.read<SettingsProvider>();
          gameProvider.initializeGame(settingsProvider.selectedDifficulty);
        },
        onClose: () {
          Navigator.of(context).pop();
          _showGameOverDialog = false;
          // The board should already be in the correct state from the repository
          // No need to force a UI update
        },
      ),
    );
  }

  Widget _buildGameControls(BuildContext context, GameProvider gameProvider) {
    return Container(
      key: _bottomBarKey,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              final settingsProvider = context.read<SettingsProvider>();
              gameProvider.initializeGame(settingsProvider.selectedDifficulty);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('New Game'),
          ),
          ElevatedButton.icon(
            onPressed: _showSettings,
            icon: const Icon(Icons.settings),
            label: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  // Layout for phone landscape mode - side-by-side layout
  Widget _buildPhoneLandscapeLayout(BuildContext context, GameProvider gameProvider) {
    return Row(
      children: [
        // Left side: Game board (takes most space)
        Expanded(
          flex: 3,
          child: GameBoard(),
        ),
        // Right side: Game info and controls (compact)
        Expanded(
          flex: 1,
          child: _buildLandscapeSidebar(context, gameProvider),
        ),
      ],
    );
  }

  // Layout for portrait mode - traditional layout
  Widget _buildPortraitLayout(BuildContext context, GameProvider gameProvider) {
    return Column(
      children: [
        // Game board
        Expanded(
          child: GameBoard(),
        ),
        // Game controls
        _buildGameControls(context, gameProvider),
      ],
    );
  }

  // Sidebar for landscape mode
  Widget _buildLandscapeSidebar(BuildContext context, GameProvider gameProvider) {
    final gameState = gameProvider.gameState!;
    final stats = gameProvider.getGameStatistics();
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Game statistics
          Container(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Mine counter
                _buildLandscapeStatCard(
                  context,
                  'Mines',
                  '${gameProvider.getRemainingMines()}',
                  Icons.warning,
                ),
                const SizedBox(height: 8),
                
                // Timer
                Consumer<GameProvider>(
                  builder: (context, provider, child) {
                    final elapsed = provider.timerService.elapsed;
                    final timeString = '${elapsed.inMinutes.toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
                    return _buildLandscapeStatCard(
                      context,
                      'Time',
                      timeString,
                      Icons.timer,
                    );
                  },
                ),
                const SizedBox(height: 8),
                
                // Progress
                _buildLandscapeStatCard(
                  context,
                  'Progress',
                  _progressString(gameState.progressPercentage),
                  Icons.bar_chart,
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Game controls
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final settingsProvider = context.read<SettingsProvider>();
                        gameProvider.initializeGame(settingsProvider.selectedDifficulty);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('New Game'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showSettings,
                      icon: const Icon(Icons.settings),
                      label: const Text('Settings'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _progressString(double progress) {
    if (progress.isNaN || progress.isInfinite || progress < 0) return '0%';
    final percent = (progress * 100).clamp(0, 100).toInt();
    return '$percent%';
  }

  Widget _buildLandscapeStatCard(BuildContext context, String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        child: Column(
          children: [
            Icon(icon, size: 16),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
} 