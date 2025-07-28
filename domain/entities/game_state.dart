import 'cell.dart';
import '../../core/constants.dart';

class GameState {
  final List<List<Cell>> board;
  final String gameStatus;
  final int minesCount;
  final int flaggedCount;
  final int revealedCount;
  final int totalCells;
  final DateTime? startTime;
  final DateTime? endTime;
  final String difficulty;

  const GameState({
    required this.board,
    required this.gameStatus,
    required this.minesCount,
    required this.flaggedCount,
    required this.revealedCount,
    required this.totalCells,
    this.startTime,
    this.endTime,
    required this.difficulty,
  });

  int get rows => board.length;
  int get columns => board.isNotEmpty ? board[0].length : 0;
  bool get isPlaying => gameStatus == GameConstants.gameStatePlaying;
  bool get isWon => gameStatus == GameConstants.gameStateWon;
  bool get isLost => gameStatus == GameConstants.gameStateLost;
  bool get isGameOver => isWon || isLost;
  Duration? get gameDuration {
    if (startTime == null) return null;
    final end = endTime ?? DateTime.now();
    return end.difference(startTime!);
  }

  int get remainingMines => minesCount - flaggedCount;
  double get progressPercentage {
    final denominator = totalCells - minesCount;
    if (denominator <= 0) return 0.0;
    return revealedCount / denominator;
  }

  Cell getCell(int row, int col) {
    if (row < 0 || row >= rows || col < 0 || col >= columns) {
      throw RangeError('Cell position ($row, $col) is out of bounds');
    }
    return board[row][col];
  }

  List<Cell> getNeighbors(int row, int col) {
    final neighbors = <Cell>[];
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = row + dr;
        final nc = col + dc;
        if (nr >= 0 && nr < rows && nc >= 0 && nc < columns) {
          neighbors.add(board[nr][nc]);
        }
      }
    }
    return neighbors;
  }

  bool isValidPosition(int row, int col) {
    return row >= 0 && row < rows && col >= 0 && col < columns;
  }

  GameState copyWith({
    List<List<Cell>>? board,
    String? gameStatus,
    int? minesCount,
    int? flaggedCount,
    int? revealedCount,
    int? totalCells,
    DateTime? startTime,
    DateTime? endTime,
    String? difficulty,
  }) {
    return GameState(
      board: board ?? this.board,
      gameStatus: gameStatus ?? this.gameStatus,
      minesCount: minesCount ?? this.minesCount,
      flaggedCount: flaggedCount ?? this.flaggedCount,
      revealedCount: revealedCount ?? this.revealedCount,
      totalCells: totalCells ?? this.totalCells,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameState &&
        other.gameStatus == gameStatus &&
        other.minesCount == minesCount &&
        other.flaggedCount == flaggedCount &&
        other.revealedCount == revealedCount &&
        other.totalCells == totalCells &&
        other.difficulty == difficulty;
  }

  @override
  int get hashCode {
    return Object.hash(
      gameStatus,
      minesCount,
      flaggedCount,
      revealedCount,
      totalCells,
      difficulty,
    );
  }

  @override
  String toString() {
    return 'GameState(status: $gameStatus, mines: $minesCount, flagged: $flaggedCount, revealed: $revealedCount, difficulty: $difficulty)';
  }
} 