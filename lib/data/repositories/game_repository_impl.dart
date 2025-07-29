import 'dart:math';
import '../../domain/repositories/game_repository.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/entities/cell.dart';
import '../../core/constants.dart';
import '../../core/feature_flags.dart';
import '../../core/game_mode_config.dart';

class GameRepositoryImpl implements GameRepository {
  GameState? _currentState;
  final Random _random = Random();
  bool _isFirstClick = true; // Track if this is the first click

  @override
  Future<GameState> initializeGame(String difficulty) async {
    final gameMode = GameModeConfig.instance.getGameMode(difficulty);
    if (gameMode == null) {
      throw ArgumentError('Invalid difficulty: $difficulty');
    }
    
    final rows = gameMode.rows;
    final columns = gameMode.columns;
    final mines = gameMode.mines;
    
    // Create empty board
    final board = List.generate(rows, (row) {
      return List.generate(columns, (col) {
        return Cell(row: row, col: col, hasBomb: false);
      });
    });
    
    // Place mines
    final actualMines = mines > 0 ? mines : _calculateMines(rows, columns);
    _placeMines(board, actualMines);
    
    // Calculate bomb counts
    _calculateBombCounts(board);
    
    _currentState = GameState(
      board: board,
      gameStatus: GameConstants.gameStatePlaying,
      minesCount: actualMines,
      flaggedCount: 0,
      revealedCount: 0,
      totalCells: rows * columns,
      startTime: DateTime.now(),
      difficulty: difficulty,
    );
    
    // Reset first click flag
    _isFirstClick = true;
    
    return _currentState!;
  }

  @override
  Future<GameState> revealCell(int row, int col) async {
    if (_currentState == null) {
      throw StateError('Game not initialized');
    }
    if (_currentState!.isGameOver) {
      return _currentState!; // Prevent revealing after game over
    }
    
    // No action if game is over
    if (_currentState!.isGameOver) {
      return _currentState!;
    }
    
    if (!_currentState!.isValidPosition(row, col)) {
      throw RangeError('Invalid position ($row, $col)');
    }
    
    // print('DEBUG: revealCell - Revealing cell ($row,$col)');
    final originalCell = _currentState!.getCell(row, col);
    // print('DEBUG: revealCell - Original cell state: hasBomb=${originalCell.hasBomb}, bombsAround=${originalCell.bombsAround}, isRevealed=${originalCell.isRevealed}, isFlagged=${originalCell.isFlagged}');
    
    // Cannot reveal flagged cells
    if (originalCell.isFlagged) {
      // print('DEBUG: revealCell - Cell is flagged, cannot reveal');
      return _currentState!;
    }
    
    // Cannot reveal already revealed cells
    if (originalCell.isRevealed) {
      // print('DEBUG: revealCell - Cell is already revealed');
      return _currentState!;
    }
    
    // Create a copy of the board to modify
    final newBoard = _copyBoard(_currentState!.board);
    
    // First Click Guarantee Logic
    if (_isFirstClick && FeatureFlags.enableFirstClickGuarantee) {
      // print('DEBUG: revealCell - First click guarantee enabled, ensuring cascade');
      _ensureFirstClickCascade(newBoard, row, col);
      // Update bomb counts incrementally after mine relocation
      _updateBombCountsAfterMineMove(newBoard);
    }
    
    // Get the updated target cell after potential mine relocation
    final targetCell = newBoard[row][col];
    // print('DEBUG: revealCell - Target cell after first click guarantee: hasBomb=${targetCell.hasBomb}, bombsAround=${targetCell.bombsAround}');
    
    // Check if cell is empty AFTER first click guarantee logic
    final wasEmpty = !targetCell.hasBomb && targetCell.bombsAround == 0;
    // print('DEBUG: revealCell - Cell is empty: $wasEmpty');
    
    // Reveal the cell
    targetCell.reveal();
    
    if (targetCell.isExploded) {
      // print('DEBUG: revealCell - Game over! Hit a bomb');
      // Game over - reveal all mines, marking the hit bomb specially
      _revealAllMines(newBoard, exploded: true, hitBombRow: row, hitBombCol: col);
      _currentState = _currentState!.copyWith(
        board: newBoard,
        gameStatus: GameConstants.gameStateLost,
        endTime: DateTime.now(),
      );
    } else {
      // print('DEBUG: revealCell - Safe reveal, cell is not exploded');
      // Safe reveal - cascade if empty
      if (wasEmpty) {
        // print('DEBUG: revealCell - Cell is empty, calling cascade');
        _cascadeReveal(newBoard, row, col);
      } else {
        // print('DEBUG: revealCell - Cell is not empty, not calling cascade');
      }
      // Count revealed and flagged cells
      final counts = _countCells(newBoard);
      // print('DEBUG: revealCell - Cell counts: revealed=${counts['revealed']}, flagged=${counts['flagged']}');
      // Check for win
      final isWon = counts['revealed'] == (_currentState!.totalCells - _currentState!.minesCount);
      
      // If game is won, flag all unflagged mines
      if (isWon) {
        // print('DEBUG: revealCell - Game won!');
        _flagAllUnflaggedMines(newBoard);
      }
      
      _currentState = _currentState!.copyWith(
        board: newBoard,
        gameStatus: isWon ? GameConstants.gameStateWon : GameConstants.gameStatePlaying,
        revealedCount: counts['revealed'],
        flaggedCount: counts['flagged'],
        endTime: isWon ? DateTime.now() : null,
      );
    }
    
    // Mark that first click has been made
    _isFirstClick = false;
    
    // print('DEBUG: revealCell - Cell reveal completed');
    return _currentState!;
  }

  @override
  Future<GameState> toggleFlag(int row, int col) async {
    if (_currentState == null || _currentState!.isGameOver) {
      return _currentState!; // No action if game is over
    }
    
    if (!_currentState!.isValidPosition(row, col)) {
      throw RangeError('Invalid position ($row, $col)');
    }
    
    final cell = _currentState!.getCell(row, col);
    if (cell.isRevealed) {
      return _currentState!; // Cannot flag revealed cells
    }
    
    // Create a copy of the board to modify
    final newBoard = _copyBoard(_currentState!.board);
    final newCell = newBoard[row][col];
    
    // Toggle flag
    newCell.toggleFlag();
    
    // Count flagged cells
    final counts = _countCells(newBoard);
    
    _currentState = _currentState!.copyWith(
      board: newBoard,
      flaggedCount: counts['flagged'],
    );
    
    return _currentState!;
  }

  @override
  Future<GameState> chordCell(int row, int col) async {
    if (_currentState == null || _currentState!.isGameOver) {
      return _currentState!; // No action if game is over
    }
    
    if (!_currentState!.isValidPosition(row, col)) {
      throw RangeError('Invalid position ($row, $col)');
    }
    
    final cell = _currentState!.getCell(row, col);
    
    // Can only chord on revealed numbered cells (not empty cells)
    if (!cell.isRevealed || cell.hasBomb || cell.bombsAround == 0) {
      return _currentState!; // No action for unrevealed, bomb, or empty cells
    }
    
    // Count flags around this cell
    int flagCount = 0;
    final rows = _currentState!.rows;
    final cols = _currentState!.columns;
    
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue; // Skip self
        
        final nr = row + dr;
        final nc = col + dc;
        
        // Check bounds
        if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
        
        final neighbor = _currentState!.getCell(nr, nc);
        if (neighbor.isFlagged) {
          flagCount++;
        }
      }
    }
    
    // Only chord if flag count matches the number
    if (flagCount != cell.bombsAround) {
      return _currentState!; // Wrong flag count, no action
    }
    
    // Create a copy of the board to modify
    final newBoard = _copyBoard(_currentState!.board);
    bool gameOver = false;
    
    // Reveal all unflagged neighbors
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue; // Skip self
        
        final nr = row + dr;
        final nc = col + dc;
        
        // Check bounds
        if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
        
        final neighbor = newBoard[nr][nc];
        
        // Skip if already revealed or flagged
        if (neighbor.isRevealed || neighbor.isFlagged) continue;
        
        // Reveal the neighbor
        neighbor.reveal();
        
        // Check if we hit a bomb
        if (neighbor.hasBomb) {
          neighbor.forceReveal(); // Mark as exploded
          gameOver = true;
        }
      }
    }
    
    // If we hit a bomb, reveal all mines
    if (gameOver) {
      _revealAllMines(newBoard, exploded: true);
    }
    
    // Count cells
    final counts = _countCells(newBoard);
    
    _currentState = _currentState!.copyWith(
      board: newBoard,
      revealedCount: counts['revealed'],
      flaggedCount: counts['flagged'],
      gameStatus: gameOver ? GameConstants.gameStateLost : _currentState!.gameStatus,
      endTime: gameOver ? DateTime.now() : _currentState!.endTime,
    );
    
    return _currentState!;
  }

  @override
  GameState getCurrentState() {
    if (_currentState == null) {
      throw StateError('Game not initialized');
    }
    return _currentState!;
  }

  @override
  bool isGameWon() {
    return _currentState?.isWon ?? false;
  }

  @override
  bool isGameLost() {
    return _currentState?.isLost ?? false;
  }

  @override
  int getRemainingMines() {
    return _currentState?.remainingMines ?? 0;
  }

  @override
  Map<String, dynamic> getGameStatistics() {
    if (_currentState == null) {
      return {};
    }
    
    return {
      'difficulty': _currentState!.difficulty,
      'minesCount': _currentState!.minesCount,
      'flaggedCount': _currentState!.flaggedCount,
      'revealedCount': _currentState!.revealedCount,
      'remainingMines': _currentState!.remainingMines,
      'progressPercentage': _currentState!.progressPercentage,
      'gameDuration': _currentState!.gameDuration?.inSeconds,
      'isGameOver': _currentState!.isGameOver,
      'isWon': _currentState!.isWon,
      'isLost': _currentState!.isLost,
    };
  }

  @override
  Future<GameState> resetGame() async {
    if (_currentState == null) {
      throw StateError('No game to reset');
    }
    
    return await initializeGame(_currentState!.difficulty);
  }

  @override
  Future<GameState> perform5050SafeMove(int clickedRow, int clickedCol, int otherRow, int otherCol) async {
    print('🚨 50/50 SAFE MOVE: Starting safe move from ($clickedRow,$clickedCol) to ($otherRow,$otherCol)');
    
    if (_currentState == null || _currentState!.isGameOver) {
      print('🚨 50/50 SAFE MOVE: Game is over, no action taken');
      return _currentState!; // No action if game is over
    }
    
    if (!_currentState!.isValidPosition(clickedRow, clickedCol) || 
        !_currentState!.isValidPosition(otherRow, otherCol)) {
      print('🚨 50/50 SAFE MOVE: Invalid position: clicked($clickedRow,$clickedCol) other($otherRow,$otherCol)');
      throw RangeError('Invalid position');
    }
    
    final clickedCell = _currentState!.getCell(clickedRow, clickedCol);
    final otherCell = _currentState!.getCell(otherRow, otherCol);
    
    print('🚨 50/50 SAFE MOVE: Clicked cell ($clickedRow,$clickedCol) - hasBomb: ${clickedCell.hasBomb}, isRevealed: ${clickedCell.isRevealed}, isFlagged: ${clickedCell.isFlagged}');
    print('🚨 50/50 SAFE MOVE: Other cell ($otherRow,$otherCol) - hasBomb: ${otherCell.hasBomb}, isRevealed: ${otherCell.isRevealed}, isFlagged: ${otherCell.isFlagged}');
    
    if (clickedCell.isRevealed || clickedCell.isFlagged) {
      print('🚨 50/50 SAFE MOVE: Clicked cell already revealed or flagged, no action needed');
      return _currentState!; // No action needed
    }
    
    // Create a copy of the board to modify
    final newBoard = _copyBoard(_currentState!.board);
    
    // Check if the clicked cell has a mine
    final clickedCellNew = newBoard[clickedRow][clickedCol];
    final otherCellNew = newBoard[otherRow][otherCol];
    
    print('🚨 50/50 SAFE MOVE: Before move - Clicked cell has bomb: ${clickedCellNew.hasBomb}, Other cell has bomb: ${otherCellNew.hasBomb}');
    
    if (clickedCellNew.hasBomb) {
      print('🚨 50/50 SAFE MOVE: MOVING BOMB from ($clickedRow,$clickedCol) to ($otherRow,$otherCol)');
      
      // Capture board state before move for comparison
      final beforeMoveState = _captureBoardNumbers(newBoard);
      print('🚨 50/50 SAFE MOVE: Board numbers BEFORE move: $beforeMoveState');
      
      // Simple 50/50 mine movement: just swap the mine between the two cells
      newBoard[clickedRow][clickedCol] = clickedCellNew.copyWith(hasBomb: false);
      newBoard[otherRow][otherCol] = otherCellNew.copyWith(hasBomb: true);
      
      print('🚨 50/50 SAFE MOVE: Mine moved, updating bomb counts...');
      // Update bomb counts for affected cells
      _updateBombCountsAfterMineMove(newBoard);
      
      // Capture board state after move for comparison
      final afterMoveState = _captureBoardNumbers(newBoard);
      print('🚨 50/50 SAFE MOVE: Board numbers AFTER move: $afterMoveState');
      
      // Check if any numbers changed
      final changedNumbers = _compareBoardStates(beforeMoveState, afterMoveState);
      if (changedNumbers.isNotEmpty) {
        print('🚨 50/50 SAFE MOVE: WARNING - Numbers changed after bomb move: $changedNumbers');
        print('🚨 50/50 SAFE MOVE: This should NOT happen in a true 50/50 situation!');
      } else {
        print('🚨 50/50 SAFE MOVE: ✅ Board numbers unchanged - this is a true 50/50');
      }
    } else {
      print('🚨 50/50 SAFE MOVE: Clicked cell does not have a bomb, no mine movement needed');
    }
    
    // Now reveal the clicked cell (which is guaranteed to be safe)
    final updatedClickedCell = newBoard[clickedRow][clickedCol];
    // print('DEBUG: perform5050SafeMove - Revealing clicked cell: hasBomb=${updatedClickedCell.hasBomb}, bombsAround=${updatedClickedCell.bombsAround}');
    
    // Simply reveal the clicked cell - no cascade needed for 50/50
    updatedClickedCell.reveal();
    
    // print('DEBUG: perform5050SafeMove - 50/50 safe move: NO CASCADE - only revealing the clicked cell');
    
    // print('DEBUG: perform5050SafeMove - Clicked cell final state: hasBomb=${newBoard[clickedRow][clickedCol].hasBomb}, bombsAround=${newBoard[clickedRow][clickedCol].bombsAround}, isRevealed=${newBoard[clickedRow][clickedCol].isRevealed}');
    
    // Count revealed and flagged cells
    final counts = _countCells(newBoard);
    // print('DEBUG: perform5050SafeMove - Final counts: revealed=${counts['revealed']}, flagged=${counts['flagged']}');
    
    // Check for win
    final isWon = counts['revealed'] == (_currentState!.totalCells - _currentState!.minesCount);
    
    // If game is won, flag all unflagged mines
    if (isWon) {
      // print('DEBUG: perform5050SafeMove - Game won!');
      _flagAllUnflaggedMines(newBoard);
    }
    
    _currentState = _currentState!.copyWith(
      board: newBoard,
      gameStatus: isWon ? GameConstants.gameStateWon : GameConstants.gameStatePlaying,
      revealedCount: counts['revealed'],
      flaggedCount: counts['flagged'],
      endTime: isWon ? DateTime.now() : null,
    );
    
    // print('DEBUG: perform5050SafeMove - Safe move completed');
    return _currentState!;
  }

  /// Efficiently updates bomb counts after mine relocation
  /// Only recalculates counts for cells affected by the mine move
  void _updateBombCountsAfterMineMove(List<List<Cell>> board) {
    final rows = board.length;
    final cols = board[0].length;
    
    // print('DEBUG: _updateBombCountsAfterMineMove - Starting bomb count update for ${rows}x${cols} board');
    
    // After mine movement, we need to recalculate ALL bomb counts
    // because the mine positions have changed
    int updatedCount = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (!board[r][c].hasBomb) {
          final oldBombsAround = board[r][c].bombsAround;
          final actualBombsAround = _countBombsAround(board, r, c);
          if (oldBombsAround != actualBombsAround) {
            // print('DEBUG: _updateBombCountsAfterMineMove - Cell ($r,$c): $oldBombsAround -> $actualBombsAround');
            board[r][c] = board[r][c].copyWith(bombsAround: actualBombsAround);
            updatedCount++;
          }
        }
      }
    }
    
    // print('DEBUG: _updateBombCountsAfterMineMove - Updated $updatedCount cells');
  }

  /// Count bombs around a specific cell
  int _countBombsAround(List<List<Cell>> board, int row, int col) {
    int count = 0;
    final rows = board.length;
    final cols = board[0].length;
    
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue; // Skip self
        
        final nr = row + dr;
        final nc = col + dc;
        
        // Check bounds
        if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
        
        if (board[nr][nc].hasBomb) {
          count++;
        }
      }
    }
    
    return count;
  }

  /// Capture board numbers for debugging 50/50 safe moves
  Map<String, int> _captureBoardNumbers(List<List<Cell>> board) {
    final numbers = <String, int>{};
    final rows = board.length;
    final cols = board[0].length;
    
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = board[r][c];
        if (cell.isRevealed && !cell.hasBomb) {
          numbers['($r,$c)'] = cell.bombsAround;
        }
      }
    }
    
    return numbers;
  }

  /// Compare board states to find changed numbers
  List<String> _compareBoardStates(Map<String, int> before, Map<String, int> after) {
    final changes = <String>[];
    
    // Check for changed numbers
    for (final entry in before.entries) {
      final afterValue = after[entry.key];
      if (afterValue != null && afterValue != entry.value) {
        changes.add('${entry.key}: ${entry.value} → $afterValue');
      }
    }
    
    // Check for new numbers
    for (final entry in after.entries) {
      if (!before.containsKey(entry.key)) {
        changes.add('${entry.key}: new ${entry.value}');
      }
    }
    
    return changes;
  }

  // TEST ONLY: Set a custom game state for deterministic tests
  void setTestState(GameState state) {
    _currentState = state;
  }

  // Force reset internal state (useful when settings change)
  void forceReset() {
    _currentState = null;
    _isFirstClick = true;
  }

  // Private helper methods

  int _calculateMines(int rows, int columns) {
    final totalCells = rows * columns;
    final probability = GameConstants.defaultBombProbability / GameConstants.defaultMaxProbability;
    return (totalCells * probability).round();
  }

  void _placeMines(List<List<Cell>> board, int mineCount) {
    final rows = board.length;
    final columns = board[0].length;
    final totalCells = rows * columns;
    
    if (mineCount > totalCells) {
      throw ArgumentError('Too many mines for board size');
    }
    
    // Create list of all positions
    final positions = <int>[];
    for (int i = 0; i < totalCells; i++) {
      positions.add(i);
    }
    
    // Shuffle and place mines
    positions.shuffle(_random);
    for (int i = 0; i < mineCount; i++) {
      final pos = positions[i];
      final row = pos ~/ columns;
      final col = pos % columns;
      board[row][col] = board[row][col].copyWith(hasBomb: true);
    }
  }

  void _calculateBombCounts(List<List<Cell>> board) {
    final rows = board.length;
    final columns = board[0].length;
    
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < columns; col++) {
        if (!board[row][col].hasBomb) {
          int count = 0;
          for (int dr = -1; dr <= 1; dr++) {
            for (int dc = -1; dc <= 1; dc++) {
              if (dr == 0 && dc == 0) continue;
              final nr = row + dr;
              final nc = col + dc;
              if (nr >= 0 && nr < rows && nc >= 0 && nc < columns) {
                if (board[nr][nc].hasBomb) count++;
              }
            }
          }
          board[row][col] = board[row][col].copyWith(bombsAround: count);
        }
      }
    }
  }

  // Public for testing
  void revealCascade(List<List<Cell>> board, int row, int col, {bool gameOver = false}) {
    if (gameOver) return;
    
    final rows = board.length;
    final cols = board[0].length;
    final queue = <List<int>>[];
    final visited = List.generate(rows, (_) => List.generate(cols, (_) => false));
    
    // Mark initial cell as visited since it's already revealed
    visited[row][col] = true;
    
    // Check if initial cell is blank and add its neighbors to queue
    final initialCell = board[row][col];
    if (!initialCell.hasBomb && initialCell.bombsAround == 0) {
      // Check all 8 neighbors of initial cell
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue; // Skip self
          
          final nr = row + dr;
          final nc = col + dc;
          
          // Check bounds
          if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
          
          // Skip if already visited
          if (visited[nr][nc]) continue;
          
          final neighbor = board[nr][nc];
          
          // Add to queue (don't mark as visited yet)
          queue.add([nr, nc]);
        }
      }
    }
    
    // Process queue
    while (queue.isNotEmpty) {
      final pos = queue.removeAt(0);
      final r = pos[0], c = pos[1];
      final cell = board[r][c];
      
      // Skip if already visited, revealed, or flagged
      if (visited[r][c] || cell.isRevealed || cell.isFlagged) continue;
      
      // Mark as visited and reveal the cell
      visited[r][c] = true;
      cell.reveal();
      
      // If cell is blank (no bomb, no adjacent bombs), add its neighbors to queue
      if (!cell.hasBomb && cell.bombsAround == 0) {
        // Check all 8 neighbors
        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            if (dr == 0 && dc == 0) continue; // Skip self
            
            final nr = r + dr;
            final nc = c + dc;
            
            // Check bounds
            if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
            
            // Skip if already visited
            if (visited[nr][nc]) continue;
            
            final neighbor = board[nr][nc];
            
            // Add to queue (don't mark as visited yet)
            queue.add([nr, nc]);
          }
        }
      }
    }
  }

  // Old cascade logic (used in app, will be replaced)
  void _cascadeReveal(List<List<Cell>> board, int row, int col) {
    // print('DEBUG: _cascadeReveal - Starting cascade reveal from ($row,$col)');
    final initialCell = board[row][col];
    // print('DEBUG: _cascadeReveal - Initial cell hasBomb: ${initialCell.hasBomb}, bombsAround: ${initialCell.bombsAround}');
    
    revealCascade(board, row, col);
    
    // Count how many cells were revealed
    int revealedCount = 0;
    for (int r = 0; r < board.length; r++) {
      for (int c = 0; c < board[0].length; c++) {
        if (board[r][c].isRevealed) {
          revealedCount++;
        }
      }
    }
    // print('DEBUG: _cascadeReveal - Cascade reveal completed, total revealed cells: $revealedCount');
  }

  void _revealAllMines(List<List<Cell>> board, {bool exploded = true, int? hitBombRow, int? hitBombCol}) {
    for (int row = 0; row < board.length; row++) {
      for (int col = 0; col < board[0].length; col++) {
        final cell = board[row][col];
        if (cell.hasBomb) {
          // Check if this is the specific bomb that was hit
          if (row == hitBombRow && col == hitBombCol) {
            cell.forceReveal(isHitBomb: true);
          } else if (!cell.isFlagged) {
            // For unflagged mines: reveal as exploded
            cell.forceReveal(exploded: exploded);
          }
          // For flagged mines: keep them flagged (don't call forceReveal)
        } else {
          // For non-mines: show black X if incorrectly flagged
          if (cell.isFlagged) {
            cell.forceReveal(showIncorrectFlag: true);
          }
        }
      }
    }
  }

  List<List<Cell>> _copyBoard(List<List<Cell>> board) {
    return board.map((row) => row.map((cell) => cell.copyWith()).toList()).toList();
  }

  Map<String, int> _countCells(List<List<Cell>> board) {
    int revealed = 0;
    int flagged = 0;
    
    for (final row in board) {
      for (final cell in row) {
        if (cell.isRevealed) revealed++;
        if (cell.isFlagged) flagged++;
      }
    }
    
    return {'revealed': revealed, 'flagged': flagged};
  }

  void _flagAllUnflaggedMines(List<List<Cell>> board) {
    for (int row = 0; row < board.length; row++) {
      for (int col = 0; col < board[0].length; col++) {
        final cell = board[row][col];
        if (cell.hasBomb && !cell.isFlagged && !cell.isRevealed) {
          cell.toggleFlag();
        }
      }
    }
  }

  void _ensureFirstClickCascade(List<List<Cell>> board, int row, int col) {
    final targetCell = board[row][col];
    
    // If the target cell is already a blank cell (no bomb, no adjacent bombs), we're good
    if (!targetCell.hasBomb && targetCell.bombsAround == 0) {
      return; // Already a cascade, no need to move mines
    }
    
    // For First Click Guarantee, we want to ensure the first click reveals a cascade
    // This means the clicked cell should be blank (no bomb, no adjacent bombs)
    
    // If target cell has a bomb, move it away and ensure target becomes blank
    if (targetCell.hasBomb) {
      _moveMineFromTargetToCreateBlank(board, row, col);
      // Update bomb counts after moving the mine
      _updateBombCountsAfterMineMove(board);
    }
    
    // Check the updated target cell after mine movement
    final updatedTargetCell = board[row][col];
    
    // If target cell is still a numbered cell (not blank), move nearby mines to make it blank
    if (updatedTargetCell.bombsAround > 0) {
      _moveNearbyMinesToCreateBlank(board, row, col);
      // Update bomb counts again after moving nearby mines
      _updateBombCountsAfterMineMove(board);
    }
  }

  void _createBlankCellByMovingMine(List<List<Cell>> board, int targetRow, int targetCol) {
    final rows = board.length;
    final cols = board[0].length;
    
    // Find all mines
    final minePositions = <List<int>>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c].hasBomb) {
          minePositions.add([r, c]);
        }
      }
    }
    
    if (minePositions.isEmpty) return;
    
    // For very small boards (1x1, 2x2), just remove the mine from the target
    if (rows * cols <= 4) {
      if (board[targetRow][targetCol].hasBomb) {
        board[targetRow][targetCol] = board[targetRow][targetCol].copyWith(hasBomb: false);
      }
      return;
    }
    
    // Find a mine that's not adjacent to the target cell
    final targetAdjacent = <List<int>>[];
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        final nr = targetRow + dr;
        final nc = targetCol + dc;
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
          targetAdjacent.add([nr, nc]);
        }
      }
    }
    
    // Find a mine that's not adjacent to target
    List<int>? mineToMove;
    for (final minePos in minePositions) {
      bool isAdjacent = false;
      for (final adjacent in targetAdjacent) {
        if (minePos[0] == adjacent[0] && minePos[1] == adjacent[1]) {
          isAdjacent = true;
          break;
        }
      }
      if (!isAdjacent) {
        mineToMove = minePos;
        break;
      }
    }
    
    // If all mines are adjacent, just pick any mine
    if (mineToMove == null && minePositions.isNotEmpty) {
      mineToMove = minePositions[_random.nextInt(minePositions.length)];
    }
    
    if (mineToMove != null) {
      // Find a safe position to move the mine to (far from target)
      List<int>? safePosition;
      int attempts = 0;
      const maxAttempts = 50;
      
      while (safePosition == null && attempts < maxAttempts) {
        final newRow = _random.nextInt(rows);
        final newCol = _random.nextInt(cols);
        
        // Make sure we're not placing it on the target or adjacent to target
        bool isValidPosition = true;
        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            final nr = targetRow + dr;
            final nc = targetCol + dc;
            if (nr == newRow && nc == newCol) {
              isValidPosition = false;
              break;
            }
          }
        }
        
        // Also make sure we're not placing it where there's already a mine
        if (isValidPosition && (newRow != targetRow || newCol != targetCol)) {
          if (!board[newRow][newCol].hasBomb) {
            safePosition = [newRow, newCol];
          }
        }
        attempts++;
      }
      
      if (safePosition != null) {
        board[mineToMove[0]][mineToMove[1]] = board[mineToMove[0]][mineToMove[1]].copyWith(hasBomb: false);
        board[safePosition[0]][safePosition[1]] = board[safePosition[0]][safePosition[1]].copyWith(hasBomb: true);
      } else {
        // As a fallback, just remove the mine from the target cell
        if (board[targetRow][targetCol].hasBomb) {
          board[targetRow][targetCol] = board[targetRow][targetCol].copyWith(hasBomb: false);
        }
      }
    }
  }

  /// Move mine from target cell and ensure target becomes blank
  void _moveMineFromTargetToCreateBlank(List<List<Cell>> board, int targetRow, int targetCol) {
    final rows = board.length;
    final cols = board[0].length;
    
    // Remove bomb from target cell
    board[targetRow][targetCol] = board[targetRow][targetCol].copyWith(hasBomb: false);
    
    // Find a safe position to place the bomb (far from target)
    List<int>? safePosition;
    int attempts = 0;
    const maxAttempts = 50;
    
    while (safePosition == null && attempts < maxAttempts) {
      final newRow = _random.nextInt(rows);
      final newCol = _random.nextInt(cols);
      
      // Make sure we're not placing it on the target or adjacent to target
      bool isValidPosition = true;
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          final nr = targetRow + dr;
          final nc = targetCol + dc;
          if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
            if (nr == newRow && nc == newCol) {
              isValidPosition = false;
              break;
            }
          }
        }
      }
      
      // Also make sure we're not placing it where there's already a mine
      if (isValidPosition && (newRow != targetRow || newCol != targetCol)) {
        if (!board[newRow][newCol].hasBomb) {
          safePosition = [newRow, newCol];
        }
      }
      attempts++;
    }
    
    if (safePosition != null) {
      board[safePosition[0]][safePosition[1]] = board[safePosition[0]][safePosition[1]].copyWith(hasBomb: true);
    }
    // If no safe position found, the bomb is effectively removed (edge case for very small boards)
  }

  /// Move nearby mines to ensure target cell becomes blank
  void _moveNearbyMinesToCreateBlank(List<List<Cell>> board, int targetRow, int targetCol) {
    final rows = board.length;
    final cols = board[0].length;
    
    // Find all mines adjacent to the target cell
    final adjacentMines = <List<int>>[];
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue; // Skip target cell
        
        final nr = targetRow + dr;
        final nc = targetCol + dc;
        
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
          if (board[nr][nc].hasBomb) {
            adjacentMines.add([nr, nc]);
          }
        }
      }
    }
    
    if (adjacentMines.isEmpty) return;
    
    // Move each adjacent mine to a safe position
    for (final minePos in adjacentMines) {
      List<int>? safePosition;
      int attempts = 0;
      const maxAttempts = 30;
      
      while (safePosition == null && attempts < maxAttempts) {
        final newRow = _random.nextInt(rows);
        final newCol = _random.nextInt(cols);
        
        // Make sure we're not placing it adjacent to target
        bool isValidPosition = true;
        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            final nr = targetRow + dr;
            final nc = targetCol + dc;
            if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
              if (nr == newRow && nc == newCol) {
                isValidPosition = false;
                break;
              }
            }
          }
        }
        
        // Also make sure we're not placing it where there's already a mine
        if (isValidPosition && (newRow != targetRow || newCol != targetCol)) {
          if (!board[newRow][newCol].hasBomb) {
            safePosition = [newRow, newCol];
          }
        }
        attempts++;
      }
      
      if (safePosition != null) {
        board[minePos[0]][minePos[1]] = board[minePos[0]][minePos[1]].copyWith(hasBomb: false);
        board[safePosition[0]][safePosition[1]] = board[safePosition[0]][safePosition[1]].copyWith(hasBomb: true);
      }
    }
  }
} 