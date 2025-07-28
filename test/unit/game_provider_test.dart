import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:python_flutter_embed_demo/presentation/providers/game_provider.dart';
import 'package:python_flutter_embed_demo/domain/entities/game_state.dart';
import 'package:python_flutter_embed_demo/domain/entities/cell.dart';
import 'package:python_flutter_embed_demo/core/feature_flags.dart';
import 'package:python_flutter_embed_demo/core/game_mode_config.dart';

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
      });
    });

    group('Timer Functionality', () {
      test('should call timer start when first cell is revealed', () async {
        // Ensure timer is reset before test
        gameProvider.timerService.reset();
        expect(gameProvider.timerService.isRunning, false);
        
        // Initialize game first
        await gameProvider.initializeGame('easy');
        
        // Test that revealCell triggers timer start logic
        await gameProvider.revealCell(0, 0);
        
        // Verify timer was started (logic test, not ticking test)
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
    });
  });
} 