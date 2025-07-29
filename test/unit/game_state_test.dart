import 'package:flutter_test/flutter_test.dart';
import 'package:python_flutter_embed_demo/domain/entities/game_state.dart';
import 'package:python_flutter_embed_demo/domain/entities/cell.dart';
import 'package:python_flutter_embed_demo/core/constants.dart';

void main() {
  group('GameState Tests', () {
    late List<List<Cell>> testBoard;
    late GameState gameState;

    setUp(() {
      // Create a 3x3 test board
      testBoard = [
        [
          Cell(row: 0, col: 0, hasBomb: false, bombsAround: 1, state: CellState.revealed),
          Cell(row: 0, col: 1, hasBomb: true, bombsAround: 0, state: CellState.unrevealed),
          Cell(row: 0, col: 2, hasBomb: false, bombsAround: 1, state: CellState.flagged),
        ],
        [
          Cell(row: 1, col: 0, hasBomb: false, bombsAround: 1, state: CellState.revealed),
          Cell(row: 1, col: 1, hasBomb: false, bombsAround: 1, state: CellState.unrevealed),
          Cell(row: 1, col: 2, hasBomb: false, bombsAround: 1, state: CellState.unrevealed),
        ],
        [
          Cell(row: 2, col: 0, hasBomb: false, bombsAround: 0, state: CellState.unrevealed),
          Cell(row: 2, col: 1, hasBomb: false, bombsAround: 0, state: CellState.unrevealed),
          Cell(row: 2, col: 2, hasBomb: false, bombsAround: 0, state: CellState.unrevealed),
        ],
      ];

      gameState = GameState(
        board: testBoard,
        gameStatus: GameConstants.gameStatePlaying,
        minesCount: 1,
        flaggedCount: 1,
        revealedCount: 2,
        totalCells: 9,
        startTime: DateTime(2024, 1, 1, 10, 0, 0),
        endTime: DateTime(2024, 1, 1, 10, 5, 0),
        difficulty: 'easy',
      );
    });

    group('Constructor and Properties', () {
      test('should create GameState with all required properties', () {
        expect(gameState.board, equals(testBoard));
        expect(gameState.gameStatus, equals(GameConstants.gameStatePlaying));
        expect(gameState.minesCount, equals(1));
        expect(gameState.flaggedCount, equals(1));
        expect(gameState.revealedCount, equals(2));
        expect(gameState.totalCells, equals(9));
        expect(gameState.startTime, equals(DateTime(2024, 1, 1, 10, 0, 0)));
        expect(gameState.endTime, equals(DateTime(2024, 1, 1, 10, 5, 0)));
        expect(gameState.difficulty, equals('easy'));
      });

      test('should create GameState with optional properties', () {
        final gameStateWithoutTimes = GameState(
          board: testBoard,
          gameStatus: GameConstants.gameStatePlaying,
          minesCount: 1,
          flaggedCount: 0,
          revealedCount: 0,
          totalCells: 9,
          difficulty: 'easy',
        );

        expect(gameStateWithoutTimes.startTime, isNull);
        expect(gameStateWithoutTimes.endTime, isNull);
        expect(gameStateWithoutTimes.gameDuration, isNull);
      });
    });

    group('Computed Properties', () {
      test('should calculate rows correctly', () {
        expect(gameState.rows, equals(3));
      });

      test('should calculate columns correctly', () {
        expect(gameState.columns, equals(3));
      });

      test('should calculate columns for empty board', () {
        final emptyGameState = GameState(
          board: [],
          gameStatus: GameConstants.gameStatePlaying,
          minesCount: 0,
          flaggedCount: 0,
          revealedCount: 0,
          totalCells: 0,
          difficulty: 'easy',
        );
        expect(emptyGameState.columns, equals(0));
      });

      test('should determine game status correctly', () {
        expect(gameState.isPlaying, isTrue);
        expect(gameState.isWon, isFalse);
        expect(gameState.isLost, isFalse);
        expect(gameState.isGameOver, isFalse);

        final wonGameState = gameState.copyWith(gameStatus: GameConstants.gameStateWon);
        expect(wonGameState.isPlaying, isFalse);
        expect(wonGameState.isWon, isTrue);
        expect(wonGameState.isLost, isFalse);
        expect(wonGameState.isGameOver, isTrue);

        final lostGameState = gameState.copyWith(gameStatus: GameConstants.gameStateLost);
        expect(lostGameState.isPlaying, isFalse);
        expect(lostGameState.isWon, isFalse);
        expect(lostGameState.isLost, isTrue);
        expect(lostGameState.isGameOver, isTrue);
      });

      test('should calculate game duration correctly', () {
        final duration = gameState.gameDuration;
        expect(duration, isNotNull);
        expect(duration!.inMinutes, equals(5));
      });

      test('should return null game duration when startTime is null', () {
        final gameStateWithoutStartTime = GameState(
          board: testBoard,
          gameStatus: GameConstants.gameStatePlaying,
          minesCount: 1,
          flaggedCount: 1,
          revealedCount: 2,
          totalCells: 9,
          startTime: null,
          endTime: DateTime(2024, 1, 1, 10, 5, 0),
          difficulty: 'easy',
        );
        expect(gameStateWithoutStartTime.gameDuration, isNull);
      });

      test('should calculate remaining mines correctly', () {
        expect(gameState.remainingMines, equals(0)); // 1 mine - 1 flagged = 0
      });

      test('should calculate progress percentage correctly', () {
        // 2 revealed / (9 total - 1 mine) = 2/8 = 0.25
        expect(gameState.progressPercentage, equals(0.25));
      });

      test('should handle progress percentage with zero denominator', () {
        final gameStateWithAllMines = gameState.copyWith(
          minesCount: 9,
          totalCells: 9,
          revealedCount: 0,
        );
        expect(gameStateWithAllMines.progressPercentage, equals(0.0));
      });

      test('should handle progress percentage with negative denominator', () {
        final gameStateWithMoreMines = gameState.copyWith(
          minesCount: 10,
          totalCells: 9,
          revealedCount: 0,
        );
        expect(gameStateWithMoreMines.progressPercentage, equals(0.0));
      });
    });

    group('Cell Access Methods', () {
      test('should get cell at valid position', () {
        final cell = gameState.getCell(0, 0);
        expect(cell.row, equals(0));
        expect(cell.col, equals(0));
        expect(cell.hasBomb, isFalse);
        expect(cell.isRevealed, isTrue);
      });

      test('should throw RangeError for invalid row', () {
        expect(() => gameState.getCell(-1, 0), throwsRangeError);
        expect(() => gameState.getCell(3, 0), throwsRangeError);
      });

      test('should throw RangeError for invalid column', () {
        expect(() => gameState.getCell(0, -1), throwsRangeError);
        expect(() => gameState.getCell(0, 3), throwsRangeError);
      });

      test('should validate position correctly', () {
        expect(gameState.isValidPosition(0, 0), isTrue);
        expect(gameState.isValidPosition(2, 2), isTrue);
        expect(gameState.isValidPosition(-1, 0), isFalse);
        expect(gameState.isValidPosition(0, -1), isFalse);
        expect(gameState.isValidPosition(3, 0), isFalse);
        expect(gameState.isValidPosition(0, 3), isFalse);
      });
    });

    group('Neighbor Calculations', () {
      test('should get neighbors for corner cell', () {
        final neighbors = gameState.getNeighbors(0, 0);
        expect(neighbors.length, equals(3));
        
        final neighborPositions = neighbors.map((c) => '${c.row},${c.col}').toSet();
        expect(neighborPositions, containsAll(['0,1', '1,0', '1,1']));
      });

      test('should get neighbors for edge cell', () {
        final neighbors = gameState.getNeighbors(0, 1);
        expect(neighbors.length, equals(5));
        
        final neighborPositions = neighbors.map((c) => '${c.row},${c.col}').toSet();
        expect(neighborPositions, containsAll(['0,0', '0,2', '1,0', '1,1', '1,2']));
      });

      test('should get neighbors for center cell', () {
        final neighbors = gameState.getNeighbors(1, 1);
        expect(neighbors.length, equals(8));
        
        final neighborPositions = neighbors.map((c) => '${c.row},${c.col}').toSet();
        expect(neighborPositions, containsAll([
          '0,0', '0,1', '0,2',
          '1,0', '1,2',
          '2,0', '2,1', '2,2'
        ]));
      });

      test('should handle edge cases for neighbor calculations', () {
        // Test with a 1x1 board
        final singleCellBoard = [
          [Cell(row: 0, col: 0, hasBomb: false, bombsAround: 0, state: CellState.unrevealed)]
        ];
        final singleCellGameState = GameState(
          board: singleCellBoard,
          gameStatus: GameConstants.gameStatePlaying,
          minesCount: 0,
          flaggedCount: 0,
          revealedCount: 0,
          totalCells: 1,
          difficulty: 'easy',
        );

        final neighbors = singleCellGameState.getNeighbors(0, 0);
        expect(neighbors.length, equals(0));
      });
    });

    group('Copy With Method', () {
      test('should create copy with updated properties', () {
        final updatedGameState = gameState.copyWith(
          gameStatus: GameConstants.gameStateWon,
          flaggedCount: 2,
          revealedCount: 5,
          endTime: DateTime(2024, 1, 1, 10, 10, 0),
        );

        expect(updatedGameState.gameStatus, equals(GameConstants.gameStateWon));
        expect(updatedGameState.flaggedCount, equals(2));
        expect(updatedGameState.revealedCount, equals(5));
        expect(updatedGameState.endTime, equals(DateTime(2024, 1, 1, 10, 10, 0)));

        // Original properties should remain unchanged
        expect(updatedGameState.board, equals(gameState.board));
        expect(updatedGameState.minesCount, equals(gameState.minesCount));
        expect(updatedGameState.totalCells, equals(gameState.totalCells));
        expect(updatedGameState.startTime, equals(gameState.startTime));
        expect(updatedGameState.difficulty, equals(gameState.difficulty));
      });

      test('should create copy with new board', () {
        final newBoard = [
          [
            Cell(row: 0, col: 0, hasBomb: true, bombsAround: 0, state: CellState.unrevealed),
            Cell(row: 0, col: 1, hasBomb: false, bombsAround: 1, state: CellState.revealed),
          ],
          [
            Cell(row: 1, col: 0, hasBomb: false, bombsAround: 1, state: CellState.flagged),
            Cell(row: 1, col: 1, hasBomb: false, bombsAround: 0, state: CellState.unrevealed),
          ],
        ];

        final updatedGameState = gameState.copyWith(board: newBoard);

        expect(updatedGameState.board, equals(newBoard));
        expect(updatedGameState.rows, equals(2));
        expect(updatedGameState.columns, equals(2));
      });
    });

    group('Equality and Hash Code', () {
      test('should be equal to identical instance', () {
        final identicalGameState = GameState(
          board: testBoard,
          gameStatus: GameConstants.gameStatePlaying,
          minesCount: 1,
          flaggedCount: 1,
          revealedCount: 2,
          totalCells: 9,
          startTime: DateTime(2024, 1, 1, 10, 0, 0),
          endTime: DateTime(2024, 1, 1, 10, 5, 0),
          difficulty: 'easy',
        );

        expect(gameState, equals(identicalGameState));
        expect(gameState.hashCode, equals(identicalGameState.hashCode));
      });

      test('should not be equal to different instance', () {
        final differentGameState = gameState.copyWith(minesCount: 2);
        expect(gameState, isNot(equals(differentGameState)));
        expect(gameState.hashCode, isNot(equals(differentGameState.hashCode)));
      });

      test('should not be equal to different type', () {
        expect(gameState, isNot(equals('not a GameState')));
      });
    });

    group('ToString Method', () {
      test('should return meaningful string representation', () {
        final stringRep = gameState.toString();
        expect(stringRep, contains('GameState'));
        expect(stringRep, contains('status: playing'));
        expect(stringRep, contains('mines: 1'));
        expect(stringRep, contains('flagged: 1'));
        expect(stringRep, contains('revealed: 2'));
        expect(stringRep, contains('difficulty: easy'));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle empty board', () {
        final emptyGameState = GameState(
          board: [],
          gameStatus: GameConstants.gameStatePlaying,
          minesCount: 0,
          flaggedCount: 0,
          revealedCount: 0,
          totalCells: 0,
          difficulty: 'easy',
        );

        expect(emptyGameState.rows, equals(0));
        expect(emptyGameState.columns, equals(0));
        expect(emptyGameState.isValidPosition(0, 0), isFalse);
        expect(() => emptyGameState.getCell(0, 0), throwsRangeError);
      });

      test('should handle irregular board (different row lengths)', () {
        final irregularBoard = [
          [Cell(row: 0, col: 0, hasBomb: false, bombsAround: 0, state: CellState.unrevealed)],
          [
            Cell(row: 1, col: 0, hasBomb: false, bombsAround: 0, state: CellState.unrevealed),
            Cell(row: 1, col: 1, hasBomb: false, bombsAround: 0, state: CellState.unrevealed),
          ],
        ];

        final irregularGameState = GameState(
          board: irregularBoard,
          gameStatus: GameConstants.gameStatePlaying,
          minesCount: 0,
          flaggedCount: 0,
          revealedCount: 0,
          totalCells: 3,
          difficulty: 'easy',
        );

        expect(irregularGameState.rows, equals(2));
        expect(irregularGameState.columns, equals(1)); // Uses first row length
      });

      test('should handle game duration with current time', () {
        final gameStateWithCurrentTime = GameState(
          board: testBoard,
          gameStatus: GameConstants.gameStatePlaying,
          minesCount: 1,
          flaggedCount: 1,
          revealedCount: 2,
          totalCells: 9,
          startTime: DateTime.now().subtract(const Duration(minutes: 5)),
          endTime: null,
          difficulty: 'easy',
        );
        final duration = gameStateWithCurrentTime.gameDuration;
        
        expect(duration, isNotNull);
        expect(duration!.inMinutes, greaterThanOrEqualTo(4)); // Should be at least 4 minutes
        expect(duration.inMinutes, lessThanOrEqualTo(6)); // Should be at most 6 minutes
      });
    });
  });
}