import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/game_board.dart';
import '../widgets/game_over_dialog.dart';
import 'settings_page.dart';
import '../../core/constants.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minesweeper with ML'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: _testPython,
            tooltip: "Test Python Integration",
          ),
          IconButton(
            icon: const Icon(Icons.psychology),
            onPressed: _test5050Detection,
            tooltip: "Test 50/50 Detection",
          ),          IconButton(
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
    const pythonChannel = MethodChannel("python/minimal");
    
    // Create a test probability map with some 50/50 situations
    final testProbabilityMap = {
      "(0, 0)": 0.5,
      "(1, 1)": 0.3,
      "(2, 2)": 0.5,
      "(3, 3)": 0.8,
    };
    
    try {
      final result = await pythonChannel.invokeMethod("find5050Situations", {
        "probabilityMap": testProbabilityMap,
      });
      print("🔔 Dart: 50/50 detection returned: $result");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("50/50 Test: Found ${(result as List).length} cells")),
      );
    } on PlatformException catch (e) {
      print("🔔 Dart: PlatformException: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("50/50 Error: ${e.message}")),
      );
    } catch (e) {
      print("🔔 Dart: Unexpected error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unexpected Error: $e")),
      );
    }
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

  @override
  void dispose() {
    super.dispose();
  }
} 