import 'package:flutter/foundation.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/entities/cell.dart';
import '../../domain/repositories/game_repository.dart';
import '../../data/repositories/game_repository_impl.dart';
import '../../services/timer_service.dart';
import '../../services/haptic_service.dart';
import '../../core/feature_flags.dart';
import '../../services/native_5050_solver.dart';

class GameProvider extends ChangeNotifier {
  final GameRepository _repository;
  final TimerService _timerService;
  GameState? _gameState;
  bool _isLoading = false;
  String? _error;

  // 50/50 detection state
  List<List<int>> _fiftyFiftyCells = [];
  List<List<int>> get fiftyFiftyCells => _fiftyFiftyCells;

  GameProvider({GameRepository? repository, TimerService? timerService}) 
      : _repository = repository ?? GameRepositoryImpl(),
        _timerService = timerService ?? TimerService() {
    // Listen to timer changes and propagate them to UI
    _timerService.addListener(() {
      notifyListeners();
    });
  }

  // Test-only setter for widget integration tests
  @visibleForTesting
  set testGameState(GameState state) {
    _gameState = state;
    notifyListeners();
  }

  // Getters
  GameState? get gameState => _gameState;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isGameInitialized => _gameState != null;
  bool get isGameOver => _gameState?.isGameOver ?? false;
  bool get isGameWon => _gameState?.isWon ?? false;
  bool get isGameLost => _gameState?.isLost ?? false;
  bool get isPlaying => _gameState?.isPlaying ?? false;
  TimerService get timerService => _timerService;

  // Initialize game
  Future<void> initializeGame(String difficulty) async {
    try {
      _setLoading(true);
      _clearError();
      
      _gameState = await _repository.initializeGame(difficulty);
      _timerService.reset();
      await updateFiftyFiftyDetection();
      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize game: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Reveal cell
  Future<void> revealCell(int row, int col) async {
    if (isGameOver) return; // Prevent revealing after game over
    try {
      _setLoading(true);
      _clearError();
      
      _gameState = await _repository.revealCell(row, col);
      
      // Start timer on first move if not already running
      if (!_timerService.isRunning) {
        _timerService.start();
      }
      
      await updateFiftyFiftyDetection();
      notifyListeners();
      
      if (isGameOver) {
        _timerService.stop();
        _handleGameOver();
      }
    } catch (e) {
      _setError('Failed to reveal cell: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Toggle flag
  Future<void> toggleFlag(int row, int col) async {
    try {
      _setLoading(true);
      _clearError();
      
      _gameState = await _repository.toggleFlag(row, col);
      
      // Start timer on first move if not already running
      if (!_timerService.isRunning) {
        _timerService.start();
      }
      
      await updateFiftyFiftyDetection();
      notifyListeners();
    } catch (e) {
      _setError('Failed to toggle flag: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Refresh state from repository (useful for testing)
  void refreshState() {
    if (_repository is GameRepositoryImpl) {
      final repo = _repository as GameRepositoryImpl;
      _gameState = repo.getCurrentState();
      notifyListeners();
    }
  }

  // Get game statistics
  Map<String, dynamic> getGameStatistics() {
    // Use provider's game state if available, otherwise fall back to repository
    if (_gameState != null) {
      final stats = {
        'difficulty': _gameState!.difficulty,
        'minesCount': _gameState!.minesCount,
        'flaggedCount': _gameState!.flaggedCount,
        'revealedCount': _gameState!.revealedCount,
        'remainingMines': _gameState!.remainingMines,
        'progressPercentage': _gameState!.progressPercentage,
        'gameDuration': _gameState!.gameDuration?.inSeconds,
        'isGameOver': _gameState!.isGameOver,
        'isWon': _gameState!.isWon,
        'isLost': _gameState!.isLost,
      };
      if (FeatureFlags.enableGameStatistics) {
        stats['timerElapsed'] = _timerService.elapsed.inSeconds;
        stats['timerRunning'] = _timerService.isRunning;
      }
      return stats;
    } else {
      final stats = _repository.getGameStatistics();
      if (FeatureFlags.enableGameStatistics) {
        stats['timerElapsed'] = _timerService.elapsed.inSeconds;
        stats['timerRunning'] = _timerService.isRunning;
      }
      return stats;
    }
  }

  // Get remaining mines
  int getRemainingMines() {
    return _repository.getRemainingMines();
  }

  // Check if action is valid
  bool isValidAction(int row, int col) {
    if (!isGameInitialized || isGameOver) return false;
    
    try {
      final cell = _gameState!.getCell(row, col);
      return cell.isUnrevealed || cell.isFlagged;
    } catch (e) {
      return false;
    }
  }

  // Get cell at position
  Cell? getCell(int row, int col) {
    if (!isGameInitialized) return null;
    
    try {
      return _gameState!.getCell(row, col);
    } catch (e) {
      return null;
    }
  }

  // Get neighbors of a cell
  List<Cell> getNeighbors(int row, int col) {
    if (!isGameInitialized) return [];
    
    try {
      return _gameState!.getNeighbors(row, col);
    } catch (e) {
      return [];
    }
  }

  // Loading and error helpers
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _handleGameOver() {
    // Placeholder for game over logic (show dialog, etc.)
  }

  /// Build a probability map and call the native 50/50 solver.
  Future<void> updateFiftyFiftyDetection() async {
    print('🔍 GameProvider: updateFiftyFiftyDetection() called');
    print('🔍 GameProvider: FeatureFlags.enable5050Detection = ${FeatureFlags.enable5050Detection}');
    print('🔍 GameProvider: _gameState is null = ${_gameState == null}');
    print('🔍 GameProvider: FeatureFlags.enableTestMode = ${FeatureFlags.enableTestMode}');
    
    if (!FeatureFlags.enable5050Detection || _gameState == null) {
      print('🔍 GameProvider: Skipping 50/50 detection - disabled or no game state');
      _fiftyFiftyCells = [];
      notifyListeners();
      return;
    }
    
    // Skip native solver calls during tests to prevent timer issues
    if (FeatureFlags.enableTestMode) {
      print('🔍 GameProvider: Skipping 50/50 detection - test mode enabled');
      _fiftyFiftyCells = [];
      notifyListeners();
      return;
    }
    
    // Only run 50/50 detection if there are revealed cells with numbers
    // and unrevealed cells adjacent to them
    bool hasRevealedNumbers = false;
    bool hasUnrevealedAdjacent = false;
    
    for (int row = 0; row < _gameState!.board.length; row++) {
      for (int col = 0; col < _gameState!.board[row].length; col++) {
        final cell = _gameState!.getCell(row, col);
        if (cell.isRevealed && cell.bombsAround > 0) {
          hasRevealedNumbers = true;
          // Check if this revealed cell has unrevealed neighbors
          final neighbors = _getUnrevealedNeighbors(row, col);
          if (neighbors.isNotEmpty) {
            hasUnrevealedAdjacent = true;
            break;
          }
        }
      }
      if (hasUnrevealedAdjacent) break;
    }
    
    if (!hasRevealedNumbers || !hasUnrevealedAdjacent) {
      print('🔍 GameProvider: No revealed numbers with unrevealed neighbors - skipping 50/50 detection');
      _fiftyFiftyCells = [];
      notifyListeners();
      return;
    }
    
    print('🔍 GameProvider: Proceeding with 50/50 detection');
    
    // Calculate simple probabilities based on game state
    final probabilityMap = _calculateSimpleProbabilities();
    
    if (probabilityMap.isEmpty) {
      print('🔍 GameProvider: No cells with probabilities to analyze');
      _fiftyFiftyCells = [];
      notifyListeners();
      return;
    }
    
    try {
      print('🔍 GameProvider: Calling Native5050Solver.find5050()');
      final newFiftyFiftyCells = await Native5050Solver.find5050(probabilityMap);
      print('🔍 GameProvider: Native5050Solver returned: $newFiftyFiftyCells');
      
      // Only notify listeners if the 50/50 cells actually changed
      bool hasChanged = _fiftyFiftyCells.length != newFiftyFiftyCells.length;
      if (!hasChanged) {
        for (int i = 0; i < _fiftyFiftyCells.length; i++) {
          if (_fiftyFiftyCells[i][0] != newFiftyFiftyCells[i][0] || 
              _fiftyFiftyCells[i][1] != newFiftyFiftyCells[i][1]) {
            hasChanged = true;
            break;
          }
        }
      }
      
      if (hasChanged) {
        _fiftyFiftyCells = newFiftyFiftyCells;
        notifyListeners();
      }
    } catch (e) {
      print('DEBUG: 50/50 detection failed: $e');
      _fiftyFiftyCells = [];
      notifyListeners();
    }
  }

  /// Calculate probabilities for ALL unrevealed cells adjacent to revealed numbers
  Map<String, double> _calculateSimpleProbabilities() {
    final probabilityMap = <String, double>{};
    
    if (_gameState == null) return probabilityMap;
    
    print('🔍 GameProvider: Calculating probabilities for ${_gameState!.board.length}x${_gameState!.board[0].length} board');
    
    // Calculate probabilities for ALL unrevealed cells adjacent to revealed numbers
    // Then we'll find pairs that both have 50% probability
    for (int row = 0; row < _gameState!.board.length; row++) {
      for (int col = 0; col < _gameState!.board[row].length; col++) {
        final cell = _gameState!.getCell(row, col);
        
        if (cell.isUnrevealed && !cell.isFlagged) {
          // Calculate probability for this cell based on adjacent revealed numbers
          final probability = _calculateCellProbability(row, col);
          if (probability > 0) {
            probabilityMap['($row, $col)'] = probability;
            if ((probability - 0.5).abs() < 0.01) { // Close to 50%
              print('🔍 GameProvider: Found cell at ($row, $col) with probability ${probability.toStringAsFixed(3)}');
            }
          }
        }
      }
    }
    
    print('🔍 GameProvider: Generated probability map with ${probabilityMap.length} cells');
    
    // Now find true 50/50 pairs (cells that both have 50% probability and are adjacent to the same revealed number)
    final true5050Cells = _findTrue5050Pairs(probabilityMap);
    
    // Return only the true 50/50 cells
    final result = <String, double>{};
    for (final cell in true5050Cells) {
      result['(${cell[0]}, ${cell[1]})'] = 0.5;
    }
    
    print('🔍 GameProvider: Found ${result.length} true 50/50 cells');
    return result;
  }

  /// Calculate probability for a cell based on adjacent revealed numbers
  double _calculateCellProbability(int row, int col) {
    // Get all revealed neighbors of this cell
    final revealedNeighbors = _getRevealedNeighbors(row, col);
    
    if (revealedNeighbors.isEmpty) {
      return 0.0; // No revealed neighbors, can't calculate probability
    }
    
    // For each revealed neighbor, calculate the probability contribution
    double totalProbability = 0.0;
    int contributingNeighbors = 0;
    
    for (final neighbor in revealedNeighbors) {
      final neighborRow = neighbor[0];
      final neighborCol = neighbor[1];
      final neighborCell = _gameState!.getCell(neighborRow, neighborCol);
      
      if (neighborCell.isRevealed && neighborCell.bombsAround > 0) {
        // Get unrevealed neighbors of this revealed cell
        final unrevealedNeighbors = _getUnrevealedNeighbors(neighborRow, neighborCol);
        final flaggedNeighbors = _getFlaggedNeighbors(neighborRow, neighborCol);
        
        // Calculate remaining mines needed
        final remainingMines = neighborCell.bombsAround - flaggedNeighbors.length;
        
        if (unrevealedNeighbors.isNotEmpty && remainingMines >= 0) {
          // Calculate probability contribution from this neighbor
          final probability = remainingMines / unrevealedNeighbors.length;
          totalProbability += probability;
          contributingNeighbors++;
        }
      }
    }
    
    if (contributingNeighbors == 0) {
      return 0.0;
    }
    
    // Return average probability from all contributing neighbors
    return totalProbability / contributingNeighbors;
  }

  /// Find true 50/50 pairs from a probability map
  List<List<int>> _findTrue5050Pairs(Map<String, double> probabilityMap) {
    final true5050Cells = <List<int>>[];
    
    // Find all cells with approximately 50% probability
    final fiftyPercentCells = <List<int>>[];
    for (final entry in probabilityMap.entries) {
      final key = entry.key;
      final probability = entry.value;
      
      if ((probability - 0.5).abs() < 0.01) { // Close to 50%
        // Parse cell coordinates
        final cleanKey = key.replaceAll('(', '').replaceAll(')', '');
        final parts = cleanKey.split(', ');
        final row = int.parse(parts[0]);
        final col = int.parse(parts[1]);
        fiftyPercentCells.add([row, col]);
      }
    }
    
    print('🔍 DEBUG: Found ${fiftyPercentCells.length} cells with ~50% probability');
    
    // For each 50% cell, check if it's part of a true 50/50 pair
    for (final cell in fiftyPercentCells) {
      final row = cell[0];
      final col = cell[1];
      
      // Get revealed neighbors of this cell
      final revealedNeighbors = _getRevealedNeighbors(row, col);
      
      for (final neighbor in revealedNeighbors) {
        final neighborRow = neighbor[0];
        final neighborCol = neighbor[1];
        final neighborCell = _gameState!.getCell(neighborRow, neighborCol);
        
        if (neighborCell.isRevealed && neighborCell.bombsAround > 0) {
          // Get unrevealed neighbors of this revealed cell
          final unrevealedNeighbors = _getUnrevealedNeighbors(neighborRow, neighborCol);
          final flaggedNeighbors = _getFlaggedNeighbors(neighborRow, neighborCol);
          
          // Check if this revealed cell needs exactly 1 more mine and has exactly 2 unrevealed neighbors
          final remainingMines = neighborCell.bombsAround - flaggedNeighbors.length;
          
          if (unrevealedNeighbors.length == 2 && remainingMines == 1) {
            // Check if both unrevealed neighbors are in our 50% list
            bool bothAre5050 = true;
            List<int> otherCell = [-1, -1];
            
            for (final unrevealed in unrevealedNeighbors) {
              if (unrevealed[0] == row && unrevealed[1] == col) {
                // This is our current cell
                continue;
              } else {
                otherCell = unrevealed;
                // Check if the other cell also has ~50% probability
                final otherKey = '(${otherCell[0]}, ${otherCell[1]})';
                final otherProbability = probabilityMap[otherKey];
                if (otherProbability == null || (otherProbability - 0.5).abs() >= 0.01) {
                  bothAre5050 = false;
                  break;
                }
              }
            }
            
            if (bothAre5050 && otherCell[0] != -1) {
              print('🔍 DEBUG: Found true 50/50 pair: ($row, $col) and (${otherCell[0]}, ${otherCell[1]})');
              true5050Cells.add(cell);
              true5050Cells.add(otherCell);
              break; // Found a pair for this cell, move to next
            }
          }
        }
      }
    }
    
    // Remove duplicates
    final uniqueCells = <List<int>>[];
    for (final cell in true5050Cells) {
      bool isDuplicate = false;
      for (final existing in uniqueCells) {
        if (existing[0] == cell[0] && existing[1] == cell[1]) {
          isDuplicate = true;
          break;
        }
      }
      if (!isDuplicate) {
        uniqueCells.add(cell);
      }
    }
    
    return uniqueCells;
  }

  /// Check if a cell is part of a true 50/50 situation (exactly 2 cells with 0.5 probability)
  bool _isTrue5050Cell(int row, int col) {
    // A true 50/50 requires exactly 2 unrevealed cells that are both adjacent to the same revealed number
    // and that revealed number needs exactly 1 more mine
    
    final revealedNeighbors = _getRevealedNeighbors(row, col);
    
    for (final neighbor in revealedNeighbors) {
      final neighborRow = neighbor[0];
      final neighborCol = neighbor[1];
      final neighborCell = _gameState!.getCell(neighborRow, neighborCol);
      
      if (neighborCell.isRevealed && neighborCell.bombsAround > 0) {
        // Get unrevealed neighbors of this revealed cell
        final unrevealedNeighbors = _getUnrevealedNeighbors(neighborRow, neighborCol);
        final flaggedNeighbors = _getFlaggedNeighbors(neighborRow, neighborCol);
        
        // Check if this revealed cell needs exactly 1 more mine and has exactly 2 unrevealed neighbors
        final remainingMines = neighborCell.bombsAround - flaggedNeighbors.length;
        
        print('🔍 DEBUG: Cell ($row, $col) - neighbor ($neighborRow, $neighborCol) has $remainingMines remaining mines and ${unrevealedNeighbors.length} unrevealed neighbors');
        
        if (unrevealedNeighbors.length == 2 && remainingMines == 1) {
          print('🔍 DEBUG: Cell ($row, $col) - potential 50/50 situation found!');
          
          // Check if this cell is one of the two unrevealed neighbors
          bool isThisCellUnrevealed = false;
          List<int> otherUnrevealedCell = [-1, -1];
          
          for (final unrevealed in unrevealedNeighbors) {
            if (unrevealed[0] == row && unrevealed[1] == col) {
              isThisCellUnrevealed = true;
            } else {
              otherUnrevealedCell = unrevealed;
            }
          }
          
          if (isThisCellUnrevealed && otherUnrevealedCell[0] != -1) {
            print('🔍 DEBUG: Cell ($row, $col) - is one of the two unrevealed neighbors, other is (${otherUnrevealedCell[0]}, ${otherUnrevealedCell[1]})');
            
            // For now, let's simplify and just check if both cells are adjacent to the same revealed number
            // and that revealed number needs exactly 1 more mine
            // This is the basic 50/50 situation
            
            // Check if the other unrevealed cell has any additional revealed neighbors
            final otherRevealedNeighbors = _getRevealedNeighbors(otherUnrevealedCell[0], otherUnrevealedCell[1]);
            bool hasAdditionalInfo = false;
            
            for (final otherNeighbor in otherRevealedNeighbors) {
              // Skip the original revealed cell we're already considering
              if (otherNeighbor[0] == neighborRow && otherNeighbor[1] == neighborCol) {
                continue;
              }
              
              final otherNeighborCell = _gameState!.getCell(otherNeighbor[0], otherNeighbor[1]);
              if (otherNeighborCell.isRevealed && otherNeighborCell.bombsAround > 0) {
                // If this other revealed cell has different unrevealed neighbors or different mine count,
                // it might provide additional information that breaks the 50/50
                final otherUnrevealedNeighbors = _getUnrevealedNeighbors(otherNeighbor[0], otherNeighbor[1]);
                final otherFlaggedNeighbors = _getFlaggedNeighbors(otherNeighbor[0], otherNeighbor[1]);
                final otherRemainingMines = otherNeighborCell.bombsAround - otherFlaggedNeighbors.length;
                
                print('🔍 DEBUG: Other cell (${otherUnrevealedCell[0]}, ${otherUnrevealedCell[1]}) has additional neighbor (${otherNeighbor[0]}, ${otherNeighbor[1]}) with $otherRemainingMines remaining mines and ${otherUnrevealedNeighbors.length} unrevealed neighbors');
                
                // If the other revealed cell has a different pattern, it might provide additional info
                if (otherUnrevealedNeighbors.length != 2 || otherRemainingMines != 1) {
                  hasAdditionalInfo = true;
                  print('🔍 DEBUG: Additional info found - breaking 50/50');
                  break;
                }
              }
            }
            
            if (!hasAdditionalInfo) {
              print('🔍 DEBUG: Cell ($row, $col) - CONFIRMED as true 50/50!');
              return true; // This is a true 50/50 situation
            }
          }
        }
      }
    }
    
    return false; // Not a true 50/50 situation
  }

  /// Check if a cell is part of a 50/50 situation
  double _check5050Probability(int row, int col) {
    // A true 50/50 situation is when:
    // 1. This cell is unrevealed and unflagged
    // 2. It's adjacent to a revealed number that needs exactly 1 more mine
    // 3. That revealed number has exactly 2 unrevealed neighbors (including this cell)
    // 4. Both unrevealed neighbors are adjacent to the same revealed number
    // 5. Neither cell has additional information from other revealed numbers
    
    // Get revealed neighbors of this cell
    final revealedNeighbors = _getRevealedNeighbors(row, col);
    
    for (final neighbor in revealedNeighbors) {
      final neighborRow = neighbor[0];
      final neighborCol = neighbor[1];
      final neighborCell = _gameState!.getCell(neighborRow, neighborCol);
      
      if (neighborCell.isRevealed && neighborCell.bombsAround > 0) {
        // Get unrevealed neighbors of this revealed cell
        final unrevealedNeighbors = _getUnrevealedNeighbors(neighborRow, neighborCol);
        final flaggedNeighbors = _getFlaggedNeighbors(neighborRow, neighborCol);
        
        // Check if this revealed cell needs exactly 1 more mine and has exactly 2 unrevealed neighbors
        final remainingMines = neighborCell.bombsAround - flaggedNeighbors.length;
        if (unrevealedNeighbors.length == 2 && remainingMines == 1) {
          // Check if this cell is one of the two unrevealed neighbors
          bool isThisCellUnrevealed = false;
          List<int> otherUnrevealedCell = [-1, -1];
          
          for (final unrevealed in unrevealedNeighbors) {
            if (unrevealed[0] == row && unrevealed[1] == col) {
              isThisCellUnrevealed = true;
            } else {
              otherUnrevealedCell = unrevealed;
            }
          }
          
          if (isThisCellUnrevealed && otherUnrevealedCell[0] != -1) {
            // Additional validation: check if both cells are truly isolated
            // A true 50/50 should have both cells sharing the same revealed neighbor
            // and no other revealed neighbors that could provide additional information
            
            // Check if the other unrevealed cell has any additional revealed neighbors
            final otherRevealedNeighbors = _getRevealedNeighbors(otherUnrevealedCell[0], otherUnrevealedCell[1]);
            bool hasAdditionalInfo = false;
            
            for (final otherNeighbor in otherRevealedNeighbors) {
              // Skip the original revealed cell we're already considering
              if (otherNeighbor[0] == neighborRow && otherNeighbor[1] == neighborCol) {
                continue;
              }
              
              final otherNeighborCell = _gameState!.getCell(otherNeighbor[0], otherNeighbor[1]);
              if (otherNeighborCell.isRevealed && otherNeighborCell.bombsAround > 0) {
                // If this other revealed cell has different unrevealed neighbors or different mine count,
                // it might provide additional information that breaks the 50/50
                final otherUnrevealedNeighbors = _getUnrevealedNeighbors(otherNeighbor[0], otherNeighbor[1]);
                final otherFlaggedNeighbors = _getFlaggedNeighbors(otherNeighbor[0], otherNeighbor[1]);
                final otherRemainingMines = otherNeighborCell.bombsAround - otherFlaggedNeighbors.length;
                
                // If the other revealed cell has a different pattern, it might provide additional info
                if (otherUnrevealedNeighbors.length != 2 || otherRemainingMines != 1) {
                  hasAdditionalInfo = true;
                  break;
                }
              }
            }
            
            // Additional check: ensure both cells share the same revealed neighbor
            // and that this revealed neighbor is the only one providing information
            if (!hasAdditionalInfo) {
              // Check if this cell also has the same revealed neighbor as the only source of information
              bool thisCellIsIsolated = true;
              for (final thisRevealedNeighbor in revealedNeighbors) {
                if (thisRevealedNeighbor[0] != neighborRow || thisRevealedNeighbor[1] != neighborCol) {
                  final thisNeighborCell = _gameState!.getCell(thisRevealedNeighbor[0], thisRevealedNeighbor[1]);
                  if (thisNeighborCell.isRevealed && thisNeighborCell.bombsAround > 0) {
                    // If this cell has other revealed neighbors with different patterns,
                    // it might not be a true 50/50
                    final thisUnrevealedNeighbors = _getUnrevealedNeighbors(thisRevealedNeighbor[0], thisRevealedNeighbor[1]);
                    final thisFlaggedNeighbors = _getFlaggedNeighbors(thisRevealedNeighbor[0], thisRevealedNeighbor[1]);
                    final thisRemainingMines = thisNeighborCell.bombsAround - thisFlaggedNeighbors.length;
                    
                    if (thisUnrevealedNeighbors.length != 2 || thisRemainingMines != 1) {
                      thisCellIsIsolated = false;
                      break;
                    }
                  }
                }
              }
              
              if (thisCellIsIsolated) {
                return 0.5; // This is a true 50/50 situation
              }
            }
          }
        }
      }
    }
    
    return 0.0; // Not a 50/50 situation
  }

  /// Get revealed neighbors of a cell
  List<List<int>> _getRevealedNeighbors(int row, int col) {
    final neighbors = <List<int>>[];
    
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        
        final nr = row + dr;
        final nc = col + dc;
        
        if (_isValidPosition(nr, nc)) {
          final cell = _gameState!.getCell(nr, nc);
          if (cell.isRevealed) {
            neighbors.add([nr, nc]);
          }
        }
      }
    }
    
    return neighbors;
  }

  /// Get unrevealed neighbors of a cell
  List<List<int>> _getUnrevealedNeighbors(int row, int col) {
    final neighbors = <List<int>>[];
    
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        
        final nr = row + dr;
        final nc = col + dc;
        
        if (_isValidPosition(nr, nc)) {
          final cell = _gameState!.getCell(nr, nc);
          if (cell.isUnrevealed && !cell.isFlagged) {
            neighbors.add([nr, nc]);
          }
        }
      }
    }
    
    return neighbors;
  }

  /// Get flagged neighbors of a cell
  List<List<int>> _getFlaggedNeighbors(int row, int col) {
    final neighbors = <List<int>>[];
    
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        
        final nr = row + dr;
        final nc = col + dc;
        
        if (_isValidPosition(nr, nc)) {
          final cell = _gameState!.getCell(nr, nc);
          if (cell.isFlagged) {
            neighbors.add([nr, nc]);
          }
        }
      }
    }
    
    return neighbors;
  }

  /// Check if position is valid
  bool _isValidPosition(int row, int col) {
    if (_gameState == null) return false;
    return row >= 0 && row < _gameState!.board.length &&
           col >= 0 && col < _gameState!.board[0].length;
  }

  // Check if a cell is in a 50/50 situation using python-based detection
  bool isCellIn5050Situation(int row, int col) {
    return _fiftyFiftyCells.any((cell) => cell[0] == row && cell[1] == col);
  }

  // Reveal a cell as a 50/50 safe move if allowed
  Future<void> execute5050SafeMove(int row, int col) async {
    if (!FeatureFlags.enable5050SafeMove) return;
    if (!isCellIn5050Situation(row, col)) return;
    await revealCell(row, col);
  }

  /// Reset the game to initial state
  Future<void> resetGame() async {
    try {
      _setLoading(true);
      _clearError();
      
      _gameState = await _repository.resetGame();
      _timerService.reset();
      _fiftyFiftyCells.clear();
      notifyListeners();
    } catch (e) {
      _setError('Failed to reset game: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Stub for forceResetRepository to satisfy UI/tests
  void forceResetRepository() {
    // Optionally, reset repository or game state here
    // For now, this is a no-op stub
  }
} 