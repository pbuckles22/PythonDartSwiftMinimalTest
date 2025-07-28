import '../entities/game_state.dart';
import '../entities/cell.dart';

abstract class GameRepository {
  /// Initialize a new game with the specified difficulty
  Future<GameState> initializeGame(String difficulty);
  
  /// Reveal a cell at the specified position
  Future<GameState> revealCell(int row, int col);
  
  /// Toggle flag on a cell at the specified position
  Future<GameState> toggleFlag(int row, int col);
  
  /// Chord a cell (right-click on revealed numbered cell to reveal unflagged neighbors)
  Future<GameState> chordCell(int row, int col);
  
  /// Get the current game state
  GameState getCurrentState();
  
  /// Check if the game is won
  bool isGameWon();
  
  /// Check if the game is lost
  bool isGameLost();
  
  /// Get the number of remaining mines
  int getRemainingMines();
  
  /// Get game statistics
  Map<String, dynamic> getGameStatistics();
  
  /// Reset the game
  Future<GameState> resetGame();
  
  /// Make a safe move in a 50/50 situation, moving mines if necessary
  /// [clickedRow, clickedCol] is the cell the user clicked
  /// [otherRow, otherCol] is the other cell in the50situation
  Future<GameState> perform5050SafeMove(int clickedRow, int clickedCol, int otherRow, int otherCol);
} 