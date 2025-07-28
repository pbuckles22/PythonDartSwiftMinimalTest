enum CellState {
  unrevealed,
  revealed,
  flagged,
  exploded,
  incorrectlyFlagged,
  hitBomb,
  fiftyFifty,
}

class Cell {
  final bool hasBomb;
  final int bombsAround;
  CellState state;
  final int row;
  final int col;

  Cell({
    required this.hasBomb,
    this.bombsAround = 0,
    this.state = CellState.unrevealed,
    required this.row,
    required this.col,
  });

  bool get isRevealed => state == CellState.revealed;
  bool get isFlagged => state == CellState.flagged;
  bool get isExploded => state == CellState.exploded;
  bool get isUnrevealed => state == CellState.unrevealed;
  bool get isIncorrectlyFlagged => state == CellState.incorrectlyFlagged;
  bool get isHitBomb => state == CellState.hitBomb;
  bool get isFiftyFifty => state == CellState.fiftyFifty;
  bool get isEmpty => !hasBomb && bombsAround == 0;

  void reveal() {
    if (state == CellState.unrevealed || state == CellState.fiftyFifty) {
      state = hasBomb ? CellState.exploded : CellState.revealed;
    }
  }

  void toggleFlag() {
    if (state == CellState.unrevealed || state == CellState.fiftyFifty) {
      state = CellState.flagged;
    } else if (state == CellState.flagged) {
      state = CellState.unrevealed;
    }
  }

  void markAsFiftyFifty() {
    if (state == CellState.unrevealed) {
      state = CellState.fiftyFifty;
    }
  }

  void unmarkFiftyFifty() {
    if (state == CellState.fiftyFifty) {
      state = CellState.unrevealed;
    }
  }

  void forceReveal({bool exploded = true, bool showIncorrectFlag = false, bool isHitBomb = false}) {
    if (isHitBomb && hasBomb) {
      // This is the specific bomb that was clicked and caused the game to end
      state = CellState.hitBomb;
      return;
    }
    
    if (state == CellState.flagged) {
      if (showIncorrectFlag && !hasBomb) {
        // Show black X for incorrectly flagged non-mines
        state = CellState.incorrectlyFlagged;
      } else if (hasBomb && !exploded) {
        // For flagged bombs when not exploded, keep them flagged
        // This preserves the flag for correctly flagged mines during gameplay
        return;
      } else if (hasBomb && exploded) {
        // For flagged bombs when game is over, reveal them to show the X
        state = CellState.exploded;
      } else {
        // Remove flag from non-mines and reveal
        state = CellState.revealed;
      }
    } else if (state == CellState.unrevealed || state == CellState.fiftyFifty) {
      if (hasBomb) {
        state = exploded ? CellState.exploded : CellState.revealed;
      } else {
        state = CellState.revealed;
      }
    }
  }

  Cell copyWith({
    bool? hasBomb,
    int? bombsAround,
    CellState? state,
    int? row,
    int? col,
  }) {
    return Cell(
      hasBomb: hasBomb ?? this.hasBomb,
      bombsAround: bombsAround ?? this.bombsAround,
      state: state ?? this.state,
      row: row ?? this.row,
      col: col ?? this.col,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cell &&
        other.hasBomb == hasBomb &&
        other.bombsAround == bombsAround &&
        other.state == state &&
        other.row == row &&
        other.col == col;
  }

  @override
  int get hashCode {
    return Object.hash(hasBomb, bombsAround, state, row, col);
  }

  @override
  String toString() {
    return 'Cell(row: $row, col: $col, hasBomb: $hasBomb, bombsAround: $bombsAround, state: $state)';
  }
} 