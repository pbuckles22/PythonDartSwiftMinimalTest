import 'package:flutter_test/flutter_test.dart';
import 'package:python_flutter_embed_demo/data/repositories/game_repository_impl.dart';
import 'package:python_flutter_embed_demo/domain/entities/game_state.dart';
import 'package:python_flutter_embed_demo/domain/entities/cell.dart';
import 'package:python_flutter_embed_demo/core/constants.dart';
import 'package:python_flutter_embed_demo/core/feature_flags.dart';
import 'package:python_flutter_embed_demo/core/game_mode_config.dart';

void main() {
  group('GameRepositoryImpl Tests', () {
    late GameRepositoryImpl repository;

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
      repository = GameRepositoryImpl();
    });

    group('Constructor and Initialization', () {
      test('should create repository with null current state', () {
        expect(repository.getCurrentState, throwsStateError);
      });

      test('should have correct initial values', () {
        expect(repository.isGameWon(), false);
        expect(repository.isGameLost(), false);
        expect(repository.getRemainingMines(), 0);
        expect(repository.getGameStatistics(), {});
      });
    });

    group('initializeGame', () {
      test('should initialize game with valid difficulty', () async {
        final gameState = await repository.initializeGame('easy');

        expect(gameState, isNotNull);
        expect(gameState.difficulty, 'easy');
        expect(gameState.gameStatus, GameConstants.gameStatePlaying);
        expect(gameState.startTime, isNotNull);
        expect(gameState.endTime, isNull);
        expect(gameState.board, isNotNull);
        expect(gameState.board.length, greaterThan(0));
        expect(gameState.board[0].length, greaterThan(0));
        expect(gameState.minesCount, greaterThan(0));
        expect(gameState.flaggedCount, 0);
        expect(gameState.revealedCount, 0);
        expect(gameState.totalCells, gameState.board.length * gameState.board[0].length);
      });

      test('should initialize game with normal difficulty', () async {
        final gameState = await repository.initializeGame('normal');

        expect(gameState.difficulty, 'normal');
        expect(gameState.gameStatus, GameConstants.gameStatePlaying);
        expect(gameState.board.length, greaterThan(0));
        expect(gameState.board[0].length, greaterThan(0));
      });

      test('should initialize game with hard difficulty', () async {
        final gameState = await repository.initializeGame('hard');

        expect(gameState.difficulty, 'hard');
        expect(gameState.gameStatus, GameConstants.gameStatePlaying);
        expect(gameState.board.length, greaterThan(0));
        expect(gameState.board[0].length, greaterThan(0));
      });

      test('should throw ArgumentError for invalid difficulty', () {
        expect(
          () => repository.initializeGame('invalid'),
          throwsArgumentError,
        );
      });

      test('should create board with correct dimensions', () async {
        final gameState = await repository.initializeGame('easy');
        final board = gameState.board;

        expect(board.length, greaterThan(0));
        expect(board[0].length, greaterThan(0));
        expect(board.length * board[0].length, gameState.totalCells);
      });

      test('should place correct number of mines', () async {
        final gameState = await repository.initializeGame('easy');
        int mineCount = 0;

        for (final row in gameState.board) {
          for (final cell in row) {
            if (cell.hasBomb) mineCount++;
          }
        }

        expect(mineCount, gameState.minesCount);
      });

      test('should calculate bomb counts correctly', () async {
        final gameState = await repository.initializeGame('easy');
        final board = gameState.board;
        final rows = board.length;
        final cols = board[0].length;

        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            final cell = board[r][c];
            if (!cell.hasBomb) {
              int expectedBombs = 0;
              for (int dr = -1; dr <= 1; dr++) {
                for (int dc = -1; dc <= 1; dc++) {
                  if (dr == 0 && dc == 0) continue;
                  final nr = r + dr;
                  final nc = c + dc;
                  if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
                    if (board[nr][nc].hasBomb) expectedBombs++;
                  }
                }
              }
              expect(cell.bombsAround, expectedBombs);
            }
          }
        }
      });

      test('should reset first click flag on initialization', () async {
        // First initialization
        await repository.initializeGame('easy');
        
        // Reveal a cell to set first click to false
        await repository.revealCell(0, 0);
        
        // Re-initialize should reset first click
        await repository.initializeGame('easy');
        
        // Next reveal should trigger first click logic
        final gameState = await repository.revealCell(0, 0);
        expect(gameState.gameStatus, isNot(GameConstants.gameStateLost));
      });
    });

    group('revealCell', () {
      late GameState initialGameState;

      setUp(() async {
        initialGameState = await repository.initializeGame('easy');
      });

      test('should throw StateError if game not initialized', () {
        final uninitializedRepo = GameRepositoryImpl();
        expect(
          () => uninitializedRepo.revealCell(0, 0),
          throwsStateError,
        );
      });

      test('should throw RangeError for invalid position', () {
        expect(
          () => repository.revealCell(-1, 0),
          throwsRangeError,
        );
        expect(
          () => repository.revealCell(0, -1),
          throwsRangeError,
        );
        expect(
          () => repository.revealCell(100, 0),
          throwsRangeError,
        );
        expect(
          () => repository.revealCell(0, 100),
          throwsRangeError,
        );
      });

      test('should not reveal flagged cells', () async {
        // Flag a cell first
        await repository.toggleFlag(0, 0);
        
        // Try to reveal the flagged cell
        final gameState = await repository.revealCell(0, 0);
        
        // Should return same state without changes
        expect(gameState.flaggedCount, 1);
        expect(gameState.getCell(0, 0).isFlagged, true);
        expect(gameState.getCell(0, 0).isRevealed, false);
      });

      test('should not reveal already revealed cells', () async {
        // Reveal a cell first
        await repository.revealCell(0, 0);
        
        // Try to reveal the same cell again
        final gameState = await repository.revealCell(0, 0);
        
        // Should return same state without changes
        expect(gameState.getCell(0, 0).isRevealed, true);
      });

      test('should not reveal cells when game is over', () async {
        // Create a game state that's already over
        final gameOverState = initialGameState.copyWith(
          gameStatus: GameConstants.gameStateLost,
          endTime: DateTime.now(),
        );
        repository.setTestState(gameOverState);
        
        // Try to reveal a cell
        final gameState = await repository.revealCell(0, 0);
        
        // Should return same state without changes
        expect(gameState.gameStatus, GameConstants.gameStateLost);
      });

      test('should reveal safe cell successfully', () async {
        // Find a safe cell (no bomb)
        int safeRow = -1, safeCol = -1;
        for (int r = 0; r < initialGameState.board.length; r++) {
          for (int c = 0; c < initialGameState.board[0].length; c++) {
            if (!initialGameState.getCell(r, c).hasBomb) {
              safeRow = r;
              safeCol = c;
              break;
            }
          }
          if (safeRow != -1) break;
        }
        
        expect(safeRow, isNot(-1));
        expect(safeCol, isNot(-1));
        
        final gameState = await repository.revealCell(safeRow, safeCol);
        
        expect(gameState.getCell(safeRow, safeCol).isRevealed, true);
        expect(gameState.gameStatus, GameConstants.gameStatePlaying);
        expect(gameState.revealedCount, greaterThan(0));
      });

      test('should end game when bomb is revealed', () async {
        // Find a bomb cell
        int bombRow = -1, bombCol = -1;
        for (int r = 0; r < initialGameState.board.length; r++) {
          for (int c = 0; c < initialGameState.board[0].length; c++) {
            if (initialGameState.getCell(r, c).hasBomb) {
              bombRow = r;
              bombCol = c;
              break;
            }
          }
          if (bombRow != -1) break;
        }
        
        expect(bombRow, isNot(-1));
        expect(bombCol, isNot(-1));
        
        final gameState = await repository.revealCell(bombRow, bombCol);
        
        expect(gameState.gameStatus, GameConstants.gameStateLost);
        expect(gameState.endTime, isNotNull);
        expect(gameState.getCell(bombRow, bombCol).isHitBomb, true);
      });

      test('should cascade reveal empty cells', () async {
        // Find an empty cell (no bomb, no adjacent bombs)
        int emptyRow = -1, emptyCol = -1;
        for (int r = 0; r < initialGameState.board.length; r++) {
          for (int c = 0; c < initialGameState.board[0].length; c++) {
            final cell = initialGameState.getCell(r, c);
            if (!cell.hasBomb && cell.bombsAround == 0) {
              emptyRow = r;
              emptyCol = c;
              break;
            }
          }
          if (emptyRow != -1) break;
        }
        
        if (emptyRow != -1) {
          final gameState = await repository.revealCell(emptyRow, emptyCol);
          
          // Should reveal multiple cells due to cascade
          expect(gameState.revealedCount, greaterThan(1));
        }
      });

      test('should win game when all non-bomb cells are revealed', () async {
        // Create a simple 2x2 board with 1 mine for testing
        final testBoard = [
          [
            Cell(row: 0, col: 0, hasBomb: false, bombsAround: 1),
            Cell(row: 0, col: 1, hasBomb: true, bombsAround: 0),
          ],
          [
            Cell(row: 1, col: 0, hasBomb: false, bombsAround: 1),
            Cell(row: 1, col: 1, hasBomb: false, bombsAround: 1),
          ],
        ];
        
        final testState = GameState(
          board: testBoard,
          gameStatus: GameConstants.gameStatePlaying,
          minesCount: 1,
          flaggedCount: 0,
          revealedCount: 0,
          totalCells: 4,
          startTime: DateTime.now(),
          difficulty: 'easy',
        );
        
        repository.setTestState(testState);
        
        // Reveal all non-bomb cells
        await repository.revealCell(0, 0);
        await repository.revealCell(1, 0);
        final gameState = await repository.revealCell(1, 1);
        
        expect(gameState.gameStatus, GameConstants.gameStateWon);
        expect(gameState.endTime, isNotNull);
      });
    });

    group('toggleFlag', () {
      late GameState initialGameState;

      setUp(() async {
        initialGameState = await repository.initializeGame('easy');
      });

      test('should throw RangeError for invalid position', () {
        expect(
          () => repository.toggleFlag(-1, 0),
          throwsRangeError,
        );
        expect(
          () => repository.toggleFlag(0, -1),
          throwsRangeError,
        );
      });

      test('should not toggle flag when game is over', () async {
        // Create a game state that's already over
        final gameOverState = initialGameState.copyWith(
          gameStatus: GameConstants.gameStateLost,
          endTime: DateTime.now(),
        );
        repository.setTestState(gameOverState);
        
        // Try to toggle flag
        final gameState = await repository.toggleFlag(0, 0);
        
        // Should return same state without changes
        expect(gameState.gameStatus, GameConstants.gameStateLost);
      });

      test('should not toggle flag on revealed cells', () async {
        // Reveal a cell first
        await repository.revealCell(0, 0);
        
        // Try to flag the revealed cell
        final gameState = await repository.toggleFlag(0, 0);
        
        // Should return same state without changes
        expect(gameState.getCell(0, 0).isRevealed, true);
        expect(gameState.getCell(0, 0).isFlagged, false);
      });

      test('should flag unrevealed cell', () async {
        final gameState = await repository.toggleFlag(0, 0);
        
        expect(gameState.getCell(0, 0).isFlagged, true);
        expect(gameState.flaggedCount, 1);
      });

      test('should unflag flagged cell', () async {
        // Flag a cell first
        await repository.toggleFlag(0, 0);
        
        // Unflag the same cell
        final gameState = await repository.toggleFlag(0, 0);
        
        expect(gameState.getCell(0, 0).isFlagged, false);
        expect(gameState.flaggedCount, 0);
      });

      test('should update flagged count correctly', () async {
        // Flag multiple cells
        await repository.toggleFlag(0, 0);
        await repository.toggleFlag(0, 1);
        await repository.toggleFlag(1, 0);
        
        final gameState = await repository.toggleFlag(1, 1);
        
        expect(gameState.flaggedCount, 4);
      });
    });

    group('chordCell', () {
      late GameState initialGameState;

      setUp(() async {
        initialGameState = await repository.initializeGame('easy');
      });

      test('should throw RangeError for invalid position', () {
        expect(
          () => repository.chordCell(-1, 0),
          throwsRangeError,
        );
        expect(
          () => repository.chordCell(0, -1),
          throwsRangeError,
        );
      });

      test('should not chord when game is over', () async {
        // Create a game state that's already over
        final gameOverState = initialGameState.copyWith(
          gameStatus: GameConstants.gameStateLost,
          endTime: DateTime.now(),
        );
        repository.setTestState(gameOverState);
        
        // Try to chord
        final gameState = await repository.chordCell(0, 0);
        
        // Should return same state without changes
        expect(gameState.gameStatus, GameConstants.gameStateLost);
      });

      test('should not chord unrevealed cells', () async {
        final gameState = await repository.chordCell(0, 0);
        
        // Should return same state without changes
        expect(gameState.getCell(0, 0).isRevealed, false);
      });

      test('should not chord bomb cells', () async {
        // Find a bomb cell and reveal it (this will end the game)
        int bombRow = -1, bombCol = -1;
        for (int r = 0; r < initialGameState.board.length; r++) {
          for (int c = 0; c < initialGameState.board[0].length; c++) {
            if (initialGameState.getCell(r, c).hasBomb) {
              bombRow = r;
              bombCol = c;
              break;
            }
          }
          if (bombRow != -1) break;
        }
        
        // Create a test state where the bomb is revealed but game continues
        final testBoard = List.generate(
          initialGameState.board.length,
          (r) => List.generate(
            initialGameState.board[0].length,
            (c) => initialGameState.getCell(r, c).copyWith(
              state: r == bombRow && c == bombCol ? CellState.revealed : CellState.unrevealed,
            ),
          ),
        );
        
        final testState = initialGameState.copyWith(board: testBoard);
        repository.setTestState(testState);
        
        final gameState = await repository.chordCell(bombRow, bombCol);
        
        // Should return same state without changes
        expect(gameState.getCell(bombRow, bombCol).isRevealed, true);
      });

      test('should not chord empty cells', () async {
        // Find an empty cell and reveal it
        int emptyRow = -1, emptyCol = -1;
        for (int r = 0; r < initialGameState.board.length; r++) {
          for (int c = 0; c < initialGameState.board[0].length; c++) {
            final cell = initialGameState.getCell(r, c);
            if (!cell.hasBomb && cell.bombsAround == 0) {
              emptyRow = r;
              emptyCol = c;
              break;
            }
          }
          if (emptyRow != -1) break;
        }
        
        if (emptyRow != -1) {
          await repository.revealCell(emptyRow, emptyCol);
          final gameState = await repository.chordCell(emptyRow, emptyCol);
          
          // Should return same state without changes
          expect(gameState.getCell(emptyRow, emptyCol).isRevealed, true);
        }
      });

      test('should not chord when flag count does not match', () async {
        // Find a numbered cell and reveal it
        int numberedRow = -1, numberedCol = -1;
        for (int r = 0; r < initialGameState.board.length; r++) {
          for (int c = 0; c < initialGameState.board[0].length; c++) {
            final cell = initialGameState.getCell(r, c);
            if (!cell.hasBomb && cell.bombsAround > 0) {
              numberedRow = r;
              numberedCol = c;
              break;
            }
          }
          if (numberedRow != -1) break;
        }
        
        if (numberedRow != -1) {
          await repository.revealCell(numberedRow, numberedCol);
          
          // Don't flag any neighbors, then try to chord
          final gameState = await repository.chordCell(numberedRow, numberedCol);
          
          // Should return same state without changes
          expect(gameState.getCell(numberedRow, numberedCol).isRevealed, true);
        }
      });
    });

    group('getCurrentState', () {
      test('should throw StateError when game not initialized', () {
        expect(
          () => repository.getCurrentState(),
          throwsStateError,
        );
      });

      test('should return current state when initialized', () async {
        final gameState = await repository.initializeGame('easy');
        final currentState = repository.getCurrentState();
        
        expect(currentState, equals(gameState));
      });
    });

    group('Game Status Methods', () {
      test('should return correct game status when not initialized', () {
        expect(repository.isGameWon(), false);
        expect(repository.isGameLost(), false);
        expect(repository.getRemainingMines(), 0);
      });

      test('should return correct game status when playing', () async {
        await repository.initializeGame('easy');
        
        expect(repository.isGameWon(), false);
        expect(repository.isGameLost(), false);
        expect(repository.getRemainingMines(), greaterThan(0));
      });

      test('should return correct game status when won', () async {
        // Create a simple winning state
        final testBoard = [
          [
            Cell(row: 0, col: 0, hasBomb: false, bombsAround: 1, state: CellState.revealed),
            Cell(row: 0, col: 1, hasBomb: true, bombsAround: 0),
          ],
          [
            Cell(row: 1, col: 0, hasBomb: false, bombsAround: 1, state: CellState.revealed),
            Cell(row: 1, col: 1, hasBomb: false, bombsAround: 1, state: CellState.revealed),
          ],
        ];
        
        final testState = GameState(
          board: testBoard,
          gameStatus: GameConstants.gameStateWon,
          minesCount: 1,
          flaggedCount: 1,
          revealedCount: 3,
          totalCells: 4,
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          difficulty: 'easy',
        );
        
        repository.setTestState(testState);
        
        expect(repository.isGameWon(), true);
        expect(repository.isGameLost(), false);
        expect(repository.getRemainingMines(), 0);
      });

      test('should return correct game status when lost', () async {
        // Create a simple losing state
        final testBoard = [
          [
            Cell(row: 0, col: 0, hasBomb: false, bombsAround: 1, state: CellState.revealed),
            Cell(row: 0, col: 1, hasBomb: true, bombsAround: 0, state: CellState.hitBomb),
          ],
          [
            Cell(row: 1, col: 0, hasBomb: false, bombsAround: 1),
            Cell(row: 1, col: 1, hasBomb: false, bombsAround: 1),
          ],
        ];
        
        final testState = GameState(
          board: testBoard,
          gameStatus: GameConstants.gameStateLost,
          minesCount: 1,
          flaggedCount: 0,
          revealedCount: 1,
          totalCells: 4,
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          difficulty: 'easy',
        );
        
        repository.setTestState(testState);
        
        expect(repository.isGameWon(), false);
        expect(repository.isGameLost(), true);
        expect(repository.getRemainingMines(), 1);
      });
    });

    group('getGameStatistics', () {
      test('should return empty map when not initialized', () {
        final stats = repository.getGameStatistics();
        expect(stats, {});
      });

      test('should return correct statistics when initialized', () async {
        await repository.initializeGame('easy');
        final stats = repository.getGameStatistics();
        
        expect(stats['difficulty'], 'easy');
        expect(stats['minesCount'], greaterThan(0));
        expect(stats['flaggedCount'], 0);
        expect(stats['revealedCount'], 0);
        expect(stats['remainingMines'], greaterThan(0));
        expect(stats['progressPercentage'], 0.0);
        expect(stats['gameDuration'], isA<int>()); // Should be 0 for new game
        expect(stats['isGameOver'], false);
        expect(stats['isWon'], false);
        expect(stats['isLost'], false);
      });

      test('should return correct statistics when game is won', () async {
        // Create a winning state
        final testBoard = [
          [
            Cell(row: 0, col: 0, hasBomb: false, bombsAround: 1, state: CellState.revealed),
            Cell(row: 0, col: 1, hasBomb: true, bombsAround: 0, state: CellState.flagged),
          ],
          [
            Cell(row: 1, col: 0, hasBomb: false, bombsAround: 1, state: CellState.revealed),
            Cell(row: 1, col: 1, hasBomb: false, bombsAround: 1, state: CellState.revealed),
          ],
        ];
        
        final startTime = DateTime.now().subtract(const Duration(minutes: 5));
        final endTime = DateTime.now();
        
        final testState = GameState(
          board: testBoard,
          gameStatus: GameConstants.gameStateWon,
          minesCount: 1,
          flaggedCount: 1,
          revealedCount: 3,
          totalCells: 4,
          startTime: startTime,
          endTime: endTime,
          difficulty: 'easy',
        );
        
        repository.setTestState(testState);
        final stats = repository.getGameStatistics();
        
        expect(stats['difficulty'], 'easy');
        expect(stats['minesCount'], 1);
        expect(stats['flaggedCount'], 1);
        expect(stats['revealedCount'], 3);
        expect(stats['remainingMines'], 0);
        expect(stats['progressPercentage'], 1.0); // 3 revealed out of (4-1) = 3 safe cells = 100% = 1.0
        expect(stats['gameDuration'], greaterThan(0));
        expect(stats['isGameOver'], true);
        expect(stats['isWon'], true);
        expect(stats['isLost'], false);
      });
    });

    group('resetGame', () {
      test('should throw StateError when no game to reset', () {
        expect(
          () => repository.resetGame(),
          throwsStateError,
        );
      });

      test('should reset game with same difficulty', () async {
        await repository.initializeGame('easy');
        final originalState = repository.getCurrentState();
        
        final resetState = await repository.resetGame();
        
        expect(resetState.difficulty, originalState.difficulty);
        expect(resetState.gameStatus, GameConstants.gameStatePlaying);
        expect(resetState.flaggedCount, 0);
        expect(resetState.revealedCount, 0);
        expect(resetState.startTime, isNotNull);
        expect(resetState.endTime, isNull);
        expect(resetState, isNot(same(originalState)));
      });
    });

    group('perform5050SafeMove', () {
      late GameState initialGameState;

      setUp(() async {
        initialGameState = await repository.initializeGame('easy');
      });

      test('should throw RangeError for invalid positions', () {
        expect(
          () => repository.perform5050SafeMove(-1, 0, 0, 0),
          throwsRangeError,
        );
        expect(
          () => repository.perform5050SafeMove(0, -1, 0, 0),
          throwsRangeError,
        );
        expect(
          () => repository.perform5050SafeMove(0, 0, -1, 0),
          throwsRangeError,
        );
        expect(
          () => repository.perform5050SafeMove(0, 0, 0, -1),
          throwsRangeError,
        );
      });

      test('should not perform move when game is over', () async {
        // Create a game state that's already over
        final gameOverState = initialGameState.copyWith(
          gameStatus: GameConstants.gameStateLost,
          endTime: DateTime.now(),
        );
        repository.setTestState(gameOverState);
        
        // Try to perform safe move
        final gameState = await repository.perform5050SafeMove(0, 0, 0, 1);
        
        // Should return same state without changes
        expect(gameState.gameStatus, GameConstants.gameStateLost);
      });

      test('should not perform move on already revealed cell', () async {
        // Reveal a cell first
        await repository.revealCell(0, 0);
        final originalState = repository.getCurrentState();
        
        // Try to perform safe move on revealed cell
        final gameState = await repository.perform5050SafeMove(0, 0, 0, 1);
        
        // Should return same state without changes
        expect(gameState.getCell(0, 0).isRevealed, true);
        expect(gameState.revealedCount, originalState.revealedCount);
        expect(gameState.flaggedCount, originalState.flaggedCount);
      });

      test('should not perform move on flagged cell', () async {
        // Flag a cell first
        await repository.toggleFlag(0, 0);
        
        // Try to perform safe move on flagged cell
        final gameState = await repository.perform5050SafeMove(0, 0, 0, 1);
        
        // Should return same state without changes
        expect(gameState.getCell(0, 0).isFlagged, true);
      });

      test('should perform safe move when clicked cell has bomb', () async {
        // Find a bomb cell
        int bombRow = -1, bombCol = -1;
        for (int r = 0; r < initialGameState.board.length; r++) {
          for (int c = 0; c < initialGameState.board[0].length; c++) {
            if (initialGameState.getCell(r, c).hasBomb) {
              bombRow = r;
              bombCol = c;
              break;
            }
          }
          if (bombRow != -1) break;
        }
        
        if (bombRow != -1) {
          // Find a safe cell to move the bomb to
          int safeRow = -1, safeCol = -1;
          for (int r = 0; r < initialGameState.board.length; r++) {
            for (int c = 0; c < initialGameState.board[0].length; c++) {
              if (!initialGameState.getCell(r, c).hasBomb) {
                safeRow = r;
                safeCol = c;
                break;
              }
            }
            if (safeRow != -1) break;
          }
          
          if (safeRow != -1) {
            final gameState = await repository.perform5050SafeMove(bombRow, bombCol, safeRow, safeCol);
            
            // The clicked cell should now be safe and revealed
            expect(gameState.getCell(bombRow, bombCol).hasBomb, false);
            expect(gameState.getCell(bombRow, bombCol).isRevealed, true);
            
            // The other cell should now have the bomb
            expect(gameState.getCell(safeRow, safeCol).hasBomb, true);
          }
        }
      });
    });

    group('Helper Methods', () {
      test('should copy board correctly', () async {
        await repository.initializeGame('easy');
        final originalBoard = repository.getCurrentState().board;
        
        // Use reflection or public method to test _copyBoard
        // For now, test through public methods that use it
        await repository.toggleFlag(0, 0);
        final newState = repository.getCurrentState();
        
        expect(newState.board, isNot(same(originalBoard)));
        expect(newState.getCell(0, 0).isFlagged, true);
      });

      test('should count cells correctly', () async {
        await repository.initializeGame('easy');
        
        // Flag some cells
        await repository.toggleFlag(0, 0);
        await repository.toggleFlag(0, 1);
        
        // Reveal some cells
        await repository.revealCell(1, 0);
        
        final state = repository.getCurrentState();
        expect(state.flaggedCount, 2);
        expect(state.revealedCount, greaterThanOrEqualTo(1)); // At least 1 cell should be revealed
      });

      test('should force reset internal state', () {
        repository.forceReset();
        
        expect(repository.getCurrentState, throwsStateError);
        expect(repository.isGameWon(), false);
        expect(repository.isGameLost(), false);
        expect(repository.getRemainingMines(), 0);
      });

      test('should set test state correctly', () async {
        final testState = await repository.initializeGame('easy');
        repository.setTestState(testState);
        
        final currentState = repository.getCurrentState();
        expect(currentState, equals(testState));
      });
    });

    group('First Click Guarantee', () {
      test('should ensure first click is safe when enabled', () async {
        // Enable first click guarantee
        FeatureFlags.enableFirstClickGuarantee = true;
        
        await repository.initializeGame('easy');
        
        // Find a bomb cell and try to reveal it
        int bombRow = -1, bombCol = -1;
        for (int r = 0; r < repository.getCurrentState().board.length; r++) {
          for (int c = 0; c < repository.getCurrentState().board[0].length; c++) {
            if (repository.getCurrentState().getCell(r, c).hasBomb) {
              bombRow = r;
              bombCol = c;
              break;
            }
          }
          if (bombRow != -1) break;
        }
        
        if (bombRow != -1) {
          final gameState = await repository.revealCell(bombRow, bombCol);
          
          // Should not lose the game on first click
          expect(gameState.gameStatus, isNot(GameConstants.gameStateLost));
          expect(gameState.getCell(bombRow, bombCol).isRevealed, true);
          expect(gameState.getCell(bombRow, bombCol).hasBomb, false);
        }
      });

      test('should not ensure first click safety when disabled', () async {
        // Disable first click guarantee
        FeatureFlags.enableFirstClickGuarantee = false;
        
        await repository.initializeGame('easy');
        
        // Find a bomb cell and try to reveal it
        int bombRow = -1, bombCol = -1;
        for (int r = 0; r < repository.getCurrentState().board.length; r++) {
          for (int c = 0; c < repository.getCurrentState().board[0].length; c++) {
            if (repository.getCurrentState().getCell(r, c).hasBomb) {
              bombRow = r;
              bombCol = c;
              break;
            }
          }
          if (bombRow != -1) break;
        }
        
        if (bombRow != -1) {
          final gameState = await repository.revealCell(bombRow, bombCol);
          
          // Should lose the game when hitting a bomb
          expect(gameState.gameStatus, GameConstants.gameStateLost);
        }
      });
    });
  });
}