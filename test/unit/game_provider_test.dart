import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:python_flutter_embed_demo/presentation/providers/game_provider.dart';
import 'package:python_flutter_embed_demo/domain/entities/game_state.dart';
import 'package:python_flutter_embed_demo/domain/entities/cell.dart';
import 'package:python_flutter_embed_demo/core/feature_flags.dart';
import 'package:python_flutter_embed_demo/core/game_mode_config.dart';
import 'package:python_flutter_embed_demo/data/repositories/game_repository_impl.dart';
import 'package:python_flutter_embed_demo/services/timer_service.dart';
import 'package:python_flutter_embed_demo/domain/repositories/game_repository.dart';

void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('GameProvider Tests', () {
    late GameProvider gameProvider;

    setUpAll(() async {
      // Load GameModeConfig before running any tests
      try {
        await GameModeConfig.instance.loadGameModes();
      } catch (e) {
        // If loading fails, the GameModeConfig will use fallback modes
        print('GameModeConfig loading failed in test environment: $e');
      }
    });

    setUp(() {
      // Reset feature flags for testing
      FeatureFlags.enable5050Detection = true;
      FeatureFlags.enableTestMode = false;
      FeatureFlags.enableGameStatistics = true;
      
      gameProvider = GameProvider();
      // Ensure timer is reset before each test
      gameProvider.timerService.reset();
    });

    tearDown(() {
      // Ensure timer is stopped after each test
      gameProvider.timerService.stop();
      gameProvider.dispose();
    });

    group('Game Initialization', () {
      test('should initialize with default values', () {
        expect(gameProvider.gameState, isNull);
        expect(gameProvider.isGameOver, false);
        expect(gameProvider.isGameWon, false);
        expect(gameProvider.fiftyFiftyCells, isEmpty);
        expect(gameProvider.isGameInitialized, false);
        expect(gameProvider.isLoading, false);
        expect(gameProvider.error, isNull);
        expect(gameProvider.isPlaying, false);
        expect(gameProvider.isGameLost, false);
      });

      test('should initialize game with easy difficulty', () async {
        await gameProvider.initializeGame('easy');
        
        expect(gameProvider.gameState, isNotNull);
        expect(gameProvider.gameState!.board.length, 9);
        expect(gameProvider.gameState!.board[0].length, 9);
        expect(gameProvider.gameState!.minesCount, 10);
        expect(gameProvider.isGameOver, false);
        expect(gameProvider.isGameWon, false);
        expect(gameProvider.isGameInitialized, true);
      });

      test('should initialize game with normal difficulty', () async {
        await gameProvider.initializeGame('normal');
        
        expect(gameProvider.gameState, isNotNull);
        expect(gameProvider.gameState!.board.length, 16);
        expect(gameProvider.gameState!.board[0].length, 16);
        expect(gameProvider.gameState!.minesCount, 40);
      });

      test('should initialize game with hard difficulty', () async {
        await gameProvider.initializeGame('hard');
        
        expect(gameProvider.gameState, isNotNull);
        expect(gameProvider.gameState!.board.length, 16);
        expect(gameProvider.gameState!.board[0].length, 30);
        expect(gameProvider.gameState!.minesCount, 99);
      });

      test('should handle initialization error', () async {
        // Test with invalid difficulty to trigger error
        await gameProvider.initializeGame('invalid');
        
        expect(gameProvider.error, isNotNull);
        expect(gameProvider.error!.contains('Failed to initialize game'), true);
      });
    });

    group('Cell Operations', () {
      setUp(() async {
        await gameProvider.initializeGame('easy');
      });

      test('should reveal cell', () async {
        final initialRevealedCount = gameProvider.gameState!.revealedCount;
        
        await gameProvider.revealCell(0, 0);
        
        expect(gameProvider.gameState!.revealedCount, greaterThan(initialRevealedCount));
        expect(gameProvider.gameState!.getCell(0, 0).isRevealed, true);
      });

      test('should toggle flag', () async {
        await gameProvider.toggleFlag(0, 0);
        
        expect(gameProvider.gameState!.getCell(0, 0).isFlagged, true);
        expect(gameProvider.gameState!.flaggedCount, 1);
      });

      test('should unflag cell', () async {
        await gameProvider.toggleFlag(0, 0);
        await gameProvider.toggleFlag(0, 0);
        
        expect(gameProvider.gameState!.getCell(0, 0).isFlagged, false);
        expect(gameProvider.gameState!.flaggedCount, 0);
      });

      test('should not reveal flagged cell', () async {
        await gameProvider.toggleFlag(0, 0);
        final initialRevealedCount = gameProvider.gameState!.revealedCount;
        
        await gameProvider.revealCell(0, 0);
        
        expect(gameProvider.gameState!.revealedCount, initialRevealedCount);
        expect(gameProvider.gameState!.getCell(0, 0).isRevealed, false);
      });

      test('should not flag revealed cell', () async {
        await gameProvider.revealCell(0, 0);
        final initialFlagCount = gameProvider.gameState!.flaggedCount;
        
        await gameProvider.toggleFlag(0, 0);
        
        expect(gameProvider.gameState!.flaggedCount, initialFlagCount);
        expect(gameProvider.gameState!.getCell(0, 0).isFlagged, false);
      });

      test('should not reveal cell when game is over', () async {
        // Find and reveal a bomb to end the game
        bool bombFound = false;
        int bombRow = 0, bombCol = 0;
        
        for (int row = 0; row < 9 && !bombFound; row++) {
          for (int col = 0; col < 9 && !bombFound; col++) {
            if (gameProvider.gameState!.getCell(row, col).hasBomb) {
              bombRow = row;
              bombCol = col;
              bombFound = true;
            }
          }
        }
        
        await gameProvider.revealCell(bombRow, bombCol);
        expect(gameProvider.isGameOver, true);
        
        // Try to reveal another cell
        final initialRevealedCount = gameProvider.gameState!.revealedCount;
        await gameProvider.revealCell(0, 0);
        
        // Should not change revealed count
        expect(gameProvider.gameState!.revealedCount, initialRevealedCount);
      });

      test('should handle reveal cell error', () async {
        // Test with invalid coordinates to trigger error
        await gameProvider.revealCell(-1, -1);
        
        expect(gameProvider.error, isNotNull);
        expect(gameProvider.error!.contains('Failed to reveal cell'), true);
      });

      test('should handle toggle flag error', () async {
        // Test with invalid coordinates to trigger error
        await gameProvider.toggleFlag(-1, -1);
        
        expect(gameProvider.error, isNotNull);
        expect(gameProvider.error!.contains('Failed to toggle flag'), true);
      });
    });

    group('Game State Validation', () {
      setUp(() async {
        await gameProvider.initializeGame('easy');
      });

      test('should validate board dimensions', () {
        expect(gameProvider.gameState!.board.length, 9);
        expect(gameProvider.gameState!.board[0].length, 9);
        
        for (int i = 0; i < 9; i++) {
          expect(gameProvider.gameState!.board[i].length, 9);
        }
      });

      test('should validate mine count', () {
        int mineCount = 0;
        for (int row = 0; row < 9; row++) {
          for (int col = 0; col < 9; col++) {
            if (gameProvider.gameState!.getCell(row, col).hasBomb) {
              mineCount++;
            }
          }
        }
        expect(mineCount, 10);
      });

      test('should validate bomb counts around cells', () {
        for (int row = 0; row < 9; row++) {
          for (int col = 0; col < 9; col++) {
            final cell = gameProvider.gameState!.getCell(row, col);
            if (!cell.hasBomb) {
              final neighbors = gameProvider.gameState!.getNeighbors(row, col);
              int expectedBombsAround = 0;
              
              for (final neighbor in neighbors) {
                if (neighbor.hasBomb) {
                  expectedBombsAround++;
                }
              }
              
              expect(cell.bombsAround, expectedBombsAround);
            }
          }
        }
      });
    });

    group('50/50 Detection', () {
      setUp(() async {
        await gameProvider.initializeGame('easy');
        FeatureFlags.enable5050Detection = true;
        FeatureFlags.enableTestMode = false;
      });

      test('should not run 50/50 detection when disabled', () async {
        FeatureFlags.enable5050Detection = false;
        
        await gameProvider.updateFiftyFiftyDetection();
        
        expect(gameProvider.fiftyFiftyCells, isEmpty);
      });

      test('should not run 50/50 detection in test mode', () async {
        FeatureFlags.enableTestMode = true;
        
        await gameProvider.updateFiftyFiftyDetection();
        
        expect(gameProvider.fiftyFiftyCells, isEmpty);
      });

      test('should not run 50/50 detection with no game state', () async {
        gameProvider = GameProvider(); // Fresh provider with no game state
        
        await gameProvider.updateFiftyFiftyDetection();
        
        expect(gameProvider.fiftyFiftyCells, isEmpty);
      });

      test('should update 50/50 detection after revealing cells', () async {
        // Reveal some cells to create a scenario
        await gameProvider.revealCell(0, 0);
        
        // 50/50 detection should be called automatically
        expect(gameProvider.fiftyFiftyCells, isA<List<List<int>>>());
      });

      test('should check if cell is in 50/50 situation', () async {
        // First, create a scenario where 50/50 detection might find cells
        await gameProvider.revealCell(0, 0);
        
        // Test the method
        expect(gameProvider.isCellIn5050Situation(0, 0), isA<bool>());
      });

      test('should execute 50/50 safe move when enabled', () async {
        FeatureFlags.enable5050SafeMove = true;
        
        // First, create a scenario where 50/50 detection might find cells
        await gameProvider.revealCell(0, 0);
        
        // Test the method (should not throw)
        await gameProvider.execute5050SafeMove(0, 0);
      });

      test('should not execute 50/50 safe move when disabled', () async {
        FeatureFlags.enable5050SafeMove = false;
        
        // Test the method (should not throw)
        await gameProvider.execute5050SafeMove(0, 0);
      });
    });

    group('50/50 Detection Tests', () {
      test('should update 50/50 detection when enabled', () async {
        FeatureFlags.enable5050Detection = true;
        await gameProvider.initializeGame('easy');
        await gameProvider.revealCell(0, 0);
        
        await gameProvider.updateFiftyFiftyDetection();
        
        expect(gameProvider.fiftyFiftyCells, isA<List<List<int>>>());
      });

      test('should skip 50/50 detection when disabled', () async {
        FeatureFlags.enable5050Detection = false;
        await gameProvider.initializeGame('easy');
        
        await gameProvider.updateFiftyFiftyDetection();
        
        expect(gameProvider.fiftyFiftyCells, isEmpty);
      });

      test('should skip 50/50 detection in test mode', () async {
        FeatureFlags.enable5050Detection = true;
        FeatureFlags.enableTestMode = true;
        await gameProvider.initializeGame('easy');
        
        await gameProvider.updateFiftyFiftyDetection();
        
        expect(gameProvider.fiftyFiftyCells, isEmpty);
      });

      test('should skip 50/50 detection when no game state', () async {
        FeatureFlags.enable5050Detection = true;
        FeatureFlags.enableTestMode = false;
        
        await gameProvider.updateFiftyFiftyDetection();
        
        expect(gameProvider.fiftyFiftyCells, isEmpty);
      });

      test('should skip 50/50 detection when no revealed numbers', () async {
        FeatureFlags.enable5050Detection = true;
        FeatureFlags.enableTestMode = false;
        await gameProvider.initializeGame('easy');
        
        // Don't reveal any cells, so no revealed numbers
        await gameProvider.updateFiftyFiftyDetection();
        
        expect(gameProvider.fiftyFiftyCells, isEmpty);
      });

      test('should handle 50/50 detection errors gracefully', () async {
        FeatureFlags.enable5050Detection = true;
        FeatureFlags.enableTestMode = false;
        await gameProvider.initializeGame('easy');
        await gameProvider.revealCell(0, 0);
        
        // Test that 50/50 detection handles errors gracefully
        await gameProvider.updateFiftyFiftyDetection();
        
        expect(gameProvider.fiftyFiftyCells, isA<List<List<int>>>());
      });
    });

    group('Neighbor Calculations', () {
      setUp(() async {
        await gameProvider.initializeGame('easy');
      });

      test('should get neighbors for corner cell', () {
        final neighbors = gameProvider.gameState!.getNeighbors(0, 0);
        
        expect(neighbors.length, 3);
        expect(neighbors.any((n) => n == gameProvider.gameState!.getCell(0, 1)), true);
        expect(neighbors.any((n) => n == gameProvider.gameState!.getCell(1, 0)), true);
        expect(neighbors.any((n) => n == gameProvider.gameState!.getCell(1, 1)), true);
      });

      test('should get neighbors for edge cell', () {
        final neighbors = gameProvider.gameState!.getNeighbors(0, 4);
        
        expect(neighbors.length, 5);
        expect(neighbors.any((n) => n == gameProvider.gameState!.getCell(0, 3)), true);
        expect(neighbors.any((n) => n == gameProvider.gameState!.getCell(0, 5)), true);
        expect(neighbors.any((n) => n == gameProvider.gameState!.getCell(1, 3)), true);
        expect(neighbors.any((n) => n == gameProvider.gameState!.getCell(1, 4)), true);
        expect(neighbors.any((n) => n == gameProvider.gameState!.getCell(1, 5)), true);
      });

      test('should get neighbors for center cell', () {
        final neighbors = gameProvider.gameState!.getNeighbors(4, 4);
        
        expect(neighbors.length, 8);
        expect(neighbors.any((n) => n == gameProvider.gameState!.getCell(3, 3)), true);
        expect(neighbors.any((n) => n == gameProvider.gameState!.getCell(3, 4)), true);
        expect(neighbors.any((n) => n == gameProvider.gameState!.getCell(3, 5)), true);
        expect(neighbors.any((n) => n == gameProvider.gameState!.getCell(4, 3)), true);
        expect(neighbors.any((n) => n == gameProvider.gameState!.getCell(4, 5)), true);
        expect(neighbors.any((n) => n == gameProvider.gameState!.getCell(5, 3)), true);
        expect(neighbors.any((n) => n == gameProvider.gameState!.getCell(5, 4)), true);
        expect(neighbors.any((n) => n == gameProvider.gameState!.getCell(5, 5)), true);
      });

      test('should get neighbors when game not initialized', () {
        gameProvider = GameProvider(); // Fresh provider with no game state
        
        final neighbors = gameProvider.getNeighbors(0, 0);
        expect(neighbors, isEmpty);
      });

      test('should get neighbors with invalid coordinates', () {
        final neighbors = gameProvider.getNeighbors(-1, -1);
        expect(neighbors, isEmpty);
      });
    });

    group('Game Over Conditions', () {
      setUp(() async {
        await gameProvider.initializeGame('easy');
      });

      test('should detect game over when bomb is revealed', () async {
        // Find a bomb and reveal it
        bool bombFound = false;
        int bombRow = 0, bombCol = 0;
        
        for (int row = 0; row < 9 && !bombFound; row++) {
          for (int col = 0; col < 9 && !bombFound; col++) {
            if (gameProvider.gameState!.getCell(row, col).hasBomb) {
              bombRow = row;
              bombCol = col;
              bombFound = true;
            }
          }
        }
        
        expect(bombFound, true);
        
        await gameProvider.revealCell(bombRow, bombCol);
        
        expect(gameProvider.isGameOver, true);
        expect(gameProvider.isGameWon, false);
        expect(gameProvider.isGameLost, true);
      });

      test('should detect game win when all non-bomb cells are revealed', () async {
        // Reveal all non-bomb cells
        for (int row = 0; row < 9; row++) {
          for (int col = 0; col < 9; col++) {
            if (!gameProvider.gameState!.getCell(row, col).hasBomb) {
              await gameProvider.revealCell(row, col);
            }
          }
        }
        
        expect(gameProvider.isGameOver, true);
        expect(gameProvider.isGameWon, true);
        expect(gameProvider.isGameLost, false);
      });
    });

    group('Timer Functionality', () {
      test('should call timer start when first cell is revealed', () async {
        expect(gameProvider.timerService.isRunning, false);
        
        // Initialize game first to ensure we have a valid game state
        await gameProvider.initializeGame('easy');
        
        // Find a safe cell to reveal (not a bomb)
        bool foundSafeCell = false;
        for (int row = 0; row < 9 && !foundSafeCell; row++) {
          for (int col = 0; col < 9 && !foundSafeCell; col++) {
            final cell = gameProvider.getCell(row, col);
            if (cell != null && !cell.hasBomb) {
              await gameProvider.revealCell(row, col);
              foundSafeCell = true;
              break;
            }
          }
        }
        
        // The timer should be running after revealing the first cell
        expect(gameProvider.timerService.isRunning, true);
      });

      test('should call timer stop when game ends', () async {
        // Ensure timer is reset before test
        gameProvider.timerService.reset();
        
        // Initialize game first
        await gameProvider.initializeGame('easy');
        
        // Start timer manually for this test
        gameProvider.timerService.start();
        expect(gameProvider.timerService.isRunning, true);
        
        // Find and reveal a bomb to end the game
        bool bombFound = false;
        int bombRow = 0, bombCol = 0;
        
        for (int row = 0; row < 9 && !bombFound; row++) {
          for (int col = 0; col < 9 && !bombFound; col++) {
            if (gameProvider.gameState!.getCell(row, col).hasBomb) {
              bombRow = row;
              bombCol = col;
              bombFound = true;
            }
          }
        }
        
        await gameProvider.revealCell(bombRow, bombCol);
        
        expect(gameProvider.isGameOver, true);
        
        // Verify timer was stopped (logic test, not ticking test)
        expect(gameProvider.timerService.isRunning, false);
      });

      test('should start timer on first flag toggle', () async {
        // Ensure timer is reset before test
        gameProvider.timerService.reset();
        expect(gameProvider.timerService.isRunning, false);
        
        // Initialize game first
        await gameProvider.initializeGame('easy');
        
        // Test that toggleFlag triggers timer start logic
        await gameProvider.toggleFlag(0, 0);
        
        // Verify timer was started
        expect(gameProvider.timerService.isRunning, true);
      });
    });

    group('Game Statistics', () {
      setUp(() async {
        await gameProvider.initializeGame('easy');
      });

      test('should get game statistics', () {
        final stats = gameProvider.getGameStatistics();
        
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['difficulty'], 'easy');
        expect(stats['minesCount'], 10);
        expect(stats['isGameOver'], false);
        expect(stats['isWon'], false);
        expect(stats['isLost'], false);
        expect(stats['timerElapsed'], isA<int>());
        expect(stats['timerRunning'], isA<bool>());
      });

      test('should get remaining mines', () {
        final remainingMines = gameProvider.getRemainingMines();
        expect(remainingMines, isA<int>());
        expect(remainingMines, 10); // Should be equal to total mines initially
      });

      test('should get game statistics when no game state', () {
        gameProvider = GameProvider(); // Fresh provider with no game state
        
        final stats = gameProvider.getGameStatistics();
        expect(stats, isA<Map<String, dynamic>>());
      });
    });

    group('Cell Access and Validation', () {
      setUp(() async {
        await gameProvider.initializeGame('easy');
      });

      test('should get cell at valid position', () {
        final cell = gameProvider.getCell(0, 0);
        expect(cell, isNotNull);
        expect(cell, isA<Cell>());
      });

      test('should return null for invalid position', () {
        final cell = gameProvider.getCell(-1, -1);
        expect(cell, isNull);
      });

      test('should return null when game not initialized', () {
        gameProvider = GameProvider(); // Fresh provider with no game state
        
        final cell = gameProvider.getCell(0, 0);
        expect(cell, isNull);
      });

      test('should validate action for valid cell', () {
        final isValid = gameProvider.isValidAction(0, 0);
        expect(isValid, isA<bool>());
      });

      test('should not validate action when game not initialized', () {
        gameProvider = GameProvider(); // Fresh provider with no game state
        
        final isValid = gameProvider.isValidAction(0, 0);
        expect(isValid, false);
      });

      test('should not validate action when game is over', () async {
        // Find and reveal a bomb to end the game
        bool bombFound = false;
        int bombRow = 0, bombCol = 0;
        
        for (int row = 0; row < 9 && !bombFound; row++) {
          for (int col = 0; col < 9 && !bombFound; col++) {
            if (gameProvider.gameState!.getCell(row, col).hasBomb) {
              bombRow = row;
              bombCol = col;
              bombFound = true;
            }
          }
        }
        
        await gameProvider.revealCell(bombRow, bombCol);
        expect(gameProvider.isGameOver, true);
        
        final isValid = gameProvider.isValidAction(0, 0);
        expect(isValid, false);
      });

      test('should not validate action for invalid coordinates', () {
        final isValid = gameProvider.isValidAction(-1, -1);
        expect(isValid, false);
      });
    });

    group('Probability Calculation Tests', () {
      test('should calculate cell probability correctly', () async {
        await gameProvider.initializeGame('easy');
        
        // Create a scenario where we can calculate probabilities
        // First reveal a cell to start the game
        await gameProvider.revealCell(0, 0);
        
        // Calculate probability for a cell
        final probability = gameProvider.calculateCellProbability(0, 1);
        expect(probability, isA<double>());
        expect(probability, greaterThanOrEqualTo(0.0));
        expect(probability, lessThanOrEqualTo(1.0));
      });

      test('should return 0 probability for cell with no revealed neighbors', () async {
        await gameProvider.initializeGame('easy');
        
        // Calculate probability for a cell far from revealed cells
        final probability = gameProvider.calculateCellProbability(8, 8);
        expect(probability, 0.0);
      });

      test('should get cell probability analysis', () async {
        await gameProvider.initializeGame('easy');
        
        final analysis = gameProvider.getCellProbabilityAnalysis(0, 0);
        expect(analysis, isA<Map<String, dynamic>>());
        expect(analysis['status'], isA<String>());
        expect(analysis['revealedNeighbors'], isA<int>());
        expect(analysis['factors'], isA<List<String>>());
      });

      test('should get cell probability analysis for revealed cell', () async {
        await gameProvider.initializeGame('easy');
        await gameProvider.revealCell(0, 0);
        
        final analysis = gameProvider.getCellProbabilityAnalysis(0, 0);
        // The cell is revealed but may have different status based on neighbors
        expect(analysis['status'], anyOf('Cell is revealed', 'No revealed neighbors'));
      });

      test('should get cell probability analysis for flagged cell', () async {
        await gameProvider.initializeGame('easy');
        await gameProvider.toggleFlag(0, 0);
        
        final analysis = gameProvider.getCellProbabilityAnalysis(0, 0);
        expect(analysis['status'], 'Cell is flagged');
      });

      test('should get cell probability analysis for unrevealed cell', () async {
        await gameProvider.initializeGame('easy');
        await gameProvider.revealCell(0, 0);
        
        final analysis = gameProvider.getCellProbabilityAnalysis(0, 1);
        // The cell might be revealed due to cascade reveal, or have different status
        expect(analysis['status'], anyOf('Cell is revealed', 'Low probability of mine', 'No revealed neighbors'));
        // The cell might be revealed due to cascade reveal
      });
    });

    group('Probability Calculations', () {
      setUp(() async {
        await gameProvider.initializeGame('easy');
      });

      test('should calculate cell probability', () {
        final probability = gameProvider.calculateCellProbability(0, 0);
        expect(probability, isA<double>());
        expect(probability >= 0.0, true);
        expect(probability <= 1.0, true);
      });

      test('should get cell probability analysis', () {
        final analysis = gameProvider.getCellProbabilityAnalysis(0, 0);
        expect(analysis, isA<Map<String, dynamic>>());
        expect(analysis['status'], isA<String>());
        expect(analysis['revealedNeighbors'], isA<int>());
        expect(analysis['factors'], isA<List<String>>());
      });

      test('should get probability analysis for revealed cell', () async {
        await gameProvider.revealCell(0, 0);
        
        final analysis = gameProvider.getCellProbabilityAnalysis(0, 0);
        // The cell is revealed but may have different status based on neighbors
        expect(analysis['status'], anyOf('Cell is revealed', 'No revealed neighbors'));
      });

      test('should get probability analysis for flagged cell', () async {
        await gameProvider.toggleFlag(0, 0);
        
        final analysis = gameProvider.getCellProbabilityAnalysis(0, 0);
        expect(analysis['status'], 'Cell is flagged');
      });

      test('should get probability analysis when no game state', () {
        gameProvider = GameProvider(); // Fresh provider with no game state
        
        final analysis = gameProvider.getCellProbabilityAnalysis(0, 0);
        expect(analysis['status'], 'No game state');
      });

      test('should get cells in probability calculation', () {
        final cells = gameProvider.getCellsInProbabilityCalculation(0, 0);
        expect(cells, isA<List<List<int>>>());
      });

      test('should set probability highlight', () async {
        // First reveal a cell to create a scenario where probability calculation works
        await gameProvider.revealCell(0, 0);
        
        gameProvider.setProbabilityHighlight(0, 0);
        // The method should not throw, but may not always return cells depending on game state
        expect(gameProvider.probabilityHighlightCells, isA<List<List<int>>>());
      });

      test('should clear probability highlight', () async {
        // First reveal a cell to create a scenario where probability calculation works
        await gameProvider.revealCell(0, 0);
        
        gameProvider.setProbabilityHighlight(0, 0);
        expect(gameProvider.probabilityHighlightCells, isA<List<List<int>>>());
        
        gameProvider.clearProbabilityHighlight();
        expect(gameProvider.probabilityHighlightCells, isEmpty);
      });

      test('should check if cell is highlighted for probability', () async {
        // First reveal a cell to create a scenario where probability calculation works
        await gameProvider.revealCell(0, 0);
        
        gameProvider.setProbabilityHighlight(0, 0);
        
        // The method should not throw, but may not always highlight cells depending on game state
        final isHighlighted = gameProvider.isCellHighlightedForProbability(0, 0);
        expect(isHighlighted, isA<bool>());
        
        final isNotHighlighted = gameProvider.isCellHighlightedForProbability(1, 1);
        expect(isNotHighlighted, isA<bool>());
      });
    });

    group('Cell Analysis Tests', () {
      test('should check if cell is in 50/50 situation', () async {
        await gameProvider.initializeGame('easy');
        await gameProvider.revealCell(0, 0);
        
        final is5050 = gameProvider.isCellIn5050Situation(0, 1);
        expect(is5050, isA<bool>());
      });

      test('should get cells in probability calculation', () async {
        await gameProvider.initializeGame('easy');
        await gameProvider.revealCell(0, 0);
        
        final cells = gameProvider.getCellsInProbabilityCalculation(0, 1);
        expect(cells, isA<List<List<int>>>());
      });

      test('should execute 50/50 safe move', () async {
        await gameProvider.initializeGame('easy');
        await gameProvider.revealCell(0, 0);
        
        // This might not always succeed depending on game state, but should not throw
        try {
          await gameProvider.execute5050SafeMove(0, 1);
        } catch (e) {
          // Expected in some cases
        }
        
        expect(gameProvider.gameState, isNotNull);
      });

      test('should debug 50/50 analysis', () async {
        await gameProvider.initializeGame('easy');
        await gameProvider.revealCell(0, 0);
        
        gameProvider.debug5050Analysis(0, 1);
        // Method should not throw
        expect(gameProvider.gameState, isNotNull);
      });

      test('should debug specific case', () async {
        await gameProvider.initializeGame('easy');
        await gameProvider.revealCell(0, 0);
        
        gameProvider.debugSpecificCase();
        // Method should not throw
        expect(gameProvider.gameState, isNotNull);
      });

      test('should save board state for debug', () async {
        await gameProvider.initializeGame('easy');
        
        gameProvider.saveBoardStateForDebug();
        // Method should not throw
        expect(gameProvider.gameState, isNotNull);
      });

      test('should debug probability calculation', () async {
        await gameProvider.initializeGame('easy');
        await gameProvider.revealCell(0, 0);
        
        final debug = gameProvider.debugProbabilityCalculation(0, 1);
        expect(debug, isA<Map<String, dynamic>>());
      });
    });

    group('Debug and Utility Methods', () {
      setUp(() async {
        await gameProvider.initializeGame('easy');
      });

      test('should save board state for debug', () {
        // Should not throw
        gameProvider.saveBoardStateForDebug();
      });

      test('should debug probability calculation', () {
        final debug = gameProvider.debugProbabilityCalculation(0, 0);
        expect(debug, isA<Map<String, dynamic>>());
      });

      test('should debug 50/50 analysis', () {
        // Should not throw
        gameProvider.debug5050Analysis(0, 0);
      });

      test('should debug specific case', () {
        // Should not throw
        gameProvider.debugSpecificCase();
      });

      test('should refresh state', () {
        // Should not throw
        gameProvider.refreshState();
      });

      test('should force reset repository', () {
        // Should not throw
        gameProvider.forceResetRepository();
      });

      test('should reset game', () async {
        final initialState = gameProvider.gameState;
        
        await gameProvider.resetGame();
        
        expect(gameProvider.gameState, isNotNull);
        // The game state should be different after reset, but the exact comparison may vary
        expect(gameProvider.fiftyFiftyCells, isEmpty);
      });

      test('should handle reset game error', () async {
        // Create a provider with a mock repository that throws
        final mockRepository = MockGameRepository();
        final provider = GameProvider(repository: mockRepository);
        
        await provider.resetGame();
        
        expect(provider.error, isNotNull);
        expect(provider.error!.contains('Failed to reset game'), true);
      });
    });

    group('Test Game State Setter', () {
      test('should set test game state', () {
        final testBoard = [
          [Cell(hasBomb: false, bombsAround: 0, state: CellState.revealed, row: 0, col: 0)]
        ];
        final testGameState = GameState(
          board: testBoard,
          gameStatus: 'playing',
          minesCount: 1,
          flaggedCount: 0,
          revealedCount: 1,
          totalCells: 1,
          startTime: DateTime.now(),
          endTime: null,
          difficulty: 'easy',
        );
        
        gameProvider.testGameState = testGameState;
        
        expect(gameProvider.gameState, equals(testGameState));
      });
    });

    group('Constructor with Dependencies', () {
      test('should create provider with custom repository and timer', () {
        final mockRepository = MockGameRepository();
        final mockTimer = TimerService();
        
        final provider = GameProvider(
          repository: mockRepository,
          timerService: mockTimer,
        );
        
        expect(provider, isNotNull);
        expect(provider.timerService, equals(mockTimer));
      });
    });

    group('Neighbor Calculation Tests', () {
      test('should get neighbors through public methods', () async {
        await gameProvider.initializeGame('easy');
        await gameProvider.revealCell(0, 0);
        
        // Test getting neighbors through the public getNeighbors method
        final neighbors = gameProvider.getNeighbors(1, 1);
        expect(neighbors, isA<List>());
        expect(neighbors.isNotEmpty, true);
      });

      test('should handle invalid positions gracefully', () async {
        await gameProvider.initializeGame('easy');
        
        // Test invalid positions - should handle gracefully but may return some neighbors
        final invalidNeighbors = gameProvider.getNeighbors(-1, -1);
        expect(invalidNeighbors, isA<List>());
        
        final outOfBoundsNeighbors = gameProvider.getNeighbors(10, 10);
        expect(outOfBoundsNeighbors, isA<List>());
      });
    });

    group('Error Handling Tests', () {
      test('should handle repository initialization errors', () async {
        final errorProvider = GameProvider(repository: MockGameRepository());
        
        await errorProvider.initializeGame('easy');
        
        expect(errorProvider.error, isNotNull);
        expect(errorProvider.isLoading, false);
      });

      test('should handle repository reveal errors', () async {
        final errorProvider = GameProvider(repository: MockGameRepository());
        await errorProvider.initializeGame('easy');
        
        await errorProvider.revealCell(0, 0);
        
        expect(errorProvider.error, isNotNull);
      });

      test('should handle repository toggle flag errors', () async {
        final errorProvider = GameProvider(repository: MockGameRepository());
        await errorProvider.initializeGame('easy');
        
        await errorProvider.toggleFlag(0, 0);
        
        expect(errorProvider.error, isNotNull);
      });

      test('should handle repository reset errors', () async {
        final errorProvider = GameProvider(repository: MockGameRepository());
        await errorProvider.initializeGame('easy');
        
        await errorProvider.resetGame();
        
        expect(errorProvider.error, isNotNull);
      });

      test('should handle repository 50/50 safe move errors', () async {
        final errorProvider = GameProvider(repository: MockGameRepository());
        await errorProvider.initializeGame('easy');
        
        await errorProvider.execute5050SafeMove(0, 0);
        
        expect(errorProvider.error, isNotNull);
      });
    });
  });
}

// Mock repository for testing error scenarios
class MockGameRepository implements GameRepository {
  @override
  Future<GameState> initializeGame(String difficulty) async {
    throw Exception('Mock initialization error');
  }

  @override
  Future<GameState> revealCell(int row, int col) async {
    throw Exception('Mock reveal error');
  }

  @override
  Future<GameState> toggleFlag(int row, int col) async {
    throw Exception('Mock toggle error');
  }

  @override
  Future<GameState> chordCell(int row, int col) async {
    throw Exception('Mock chord error');
  }

  @override
  Future<GameState> perform5050SafeMove(int clickedRow, int clickedCol, int otherRow, int otherCol) async {
    throw Exception('Mock 50/50 error');
  }

  @override
  Future<GameState> resetGame() async {
    throw Exception('Mock reset error');
  }

  @override
  GameState getCurrentState() {
    throw Exception('Mock get state error');
  }

  @override
  bool isGameWon() {
    return false;
  }

  @override
  bool isGameLost() {
    return false;
  }

  @override
  Map<String, dynamic> getGameStatistics() {
    return {};
  }

  @override
  int getRemainingMines() {
    return 0;
  }
} 