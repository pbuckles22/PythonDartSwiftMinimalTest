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
  Set<String> _logged5050Cells = {}; // Track logged cells to prevent spam
  List<List<int>> get fiftyFiftyCells => _fiftyFiftyCells;
  
  // Probability analysis highlighting state
  List<List<int>> _probabilityHighlightCells = [];
  List<List<int>> get probabilityHighlightCells => _probabilityHighlightCells;
  
  // Static callback for probability analysis
  static Function(int, int)? onProbabilityAnalysisRequested;

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
      
      final oldState = _gameState;
      _gameState = await _repository.toggleFlag(row, col);
      
      // Start timer on first move if not already running
      if (!_timerService.isRunning) {
        _timerService.start();
      }
      
      // Only update 50/50 detection if the game state actually changed
      if (oldState != _gameState) {
        await updateFiftyFiftyDetection();
      }
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
    
    // Calculate ALL unrevealed cell probabilities and send to Python
    final probabilityMap = _calculateAllUnrevealedProbabilities();
    
    if (probabilityMap.isEmpty) {
      print('🔍 GameProvider: No unrevealed cells to analyze');
      _fiftyFiftyCells = [];
      notifyListeners();
      return;
    }
    
    try {
      print('🔍 GameProvider: Calling Native5050Solver.find5050() with sensitivity: ${FeatureFlags.fiftyFiftySensitivity}');
      print('🔍 GameProvider: Sending ${probabilityMap.length} cells to Python: $probabilityMap');
      final rawPythonResults = await Native5050Solver.find5050(probabilityMap, sensitivity: FeatureFlags.fiftyFiftySensitivity);
      print('🔍 GameProvider: Python returned ${rawPythonResults.length} 50/50 cells: $rawPythonResults');
      
      // Convert Python results to our format
      final rawPythonCells = <List<int>>[];
      for (final result in rawPythonResults) {
        if (result.length == 2) {
          rawPythonCells.add([result[0], result[1]]);
        }
      }
      
      // Validate Python results against board state to find true 50/50 pairs
      final newFiftyFiftyCells = _validatePython5050Results(rawPythonCells);
      print('🔍 GameProvider: After validation: ${newFiftyFiftyCells.length} true 50/50 cells: $newFiftyFiftyCells');
      
      // Only update and notify if the 50/50 cells actually changed
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
        print('🔍 GameProvider: 50/50 cells changed, updating UI');
        _fiftyFiftyCells = newFiftyFiftyCells;
        _logged5050Cells.clear(); // Clear logged cells when 50/50 cells change
        notifyListeners();
      } else {
        print('🔍 GameProvider: 50/50 cells unchanged, skipping UI update');
      }
    } catch (e) {
      print('DEBUG: 50/50 detection failed: $e');
      _fiftyFiftyCells = [];
      notifyListeners();
    }
  }

  /// Calculate probabilities for ALL unrevealed cells (let Python do the 50/50 detection)
  Map<String, double> _calculateAllUnrevealedProbabilities() {
    final probabilityMap = <String, double>{};
    
    if (_gameState == null) return probabilityMap;
    
    print('🔍 GameProvider: Calculating probabilities for ALL unrevealed cells');
    
    // Send ALL unrevealed cells to Python for 50/50 detection
    for (int row = 0; row < _gameState!.board.length; row++) {
      for (int col = 0; col < _gameState!.board[row].length; col++) {
        final cell = _gameState!.getCell(row, col);
        
        if (cell.isUnrevealed && !cell.isFlagged) {
          // Calculate probability for this cell based on adjacent revealed numbers
          final probability = _calculateCellProbability(row, col);
          if (probability > 0) {
            probabilityMap['($row, $col)'] = probability;
          }
        }
      }
    }
    
    print('🔍 GameProvider: Sending ${probabilityMap.length} unrevealed cells to Python');
    return probabilityMap;
  }

  /// Calculate probability for a cell based on adjacent revealed numbers
  /// Returns raw probability - Python will handle 50/50 detection
  double _calculateCellProbability(int row, int col) {
    // Get all revealed neighbors of this cell
    final revealedNeighbors = _getRevealedNeighbors(row, col);
    
    if (revealedNeighbors.isEmpty) {
      return 0.0; // No revealed neighbors, can't calculate probability
    }
    
    // Calculate normal probability from all revealed neighbors
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

  /// Validate Python 50/50 results against board state to find true 50/50 pairs
  List<List<int>> _validatePython5050Results(List<List<int>> pythonResults) {
    final validatedCells = <List<int>>[];
    
    print('🔍 GameProvider: Validating ${pythonResults.length} Python 50/50 cells against board state');
    
    // Group cells into potential pairs (every 2 cells)
    for (int i = 0; i < pythonResults.length; i += 2) {
      if (i + 1 < pythonResults.length) {
        final cell1 = pythonResults[i];
        final cell2 = pythonResults[i + 1];
        
        if (_isValid5050Pair(cell1[0], cell1[1], cell2[0], cell2[1])) {
          print('🔍 GameProvider: Validated 50/50 pair: (${cell1[0]}, ${cell1[1]}) and (${cell2[0]}, ${cell2[1]})');
          validatedCells.add(cell1);
          validatedCells.add(cell2);
        } else {
          print('🔍 GameProvider: Rejected invalid 50/50 pair: (${cell1[0]}, ${cell1[1]}) and (${cell2[0]}, ${cell2[1]})');
        }
      }
    }
    
    print('🔍 GameProvider: Validation complete: ${validatedCells.length} cells in ${validatedCells.length ~/ 2} pairs');
    return validatedCells;
  }
  
  /// Check if two cells form a valid 50/50 pair (more lenient validation)
  bool _isValid5050Pair(int row1, int col1, int row2, int col2) {
    // First check if the cells are side-adjacent to each other
    final rowDiff = (row1 - row2).abs();
    final colDiff = (col1 - col2).abs();
    
    if (!((rowDiff == 0 && colDiff == 1) || (rowDiff == 1 && colDiff == 0))) {
      print('🔍 GameProvider: Cells (${row1}, ${col1}) and (${row2}, ${col2}) are not side-adjacent');
      return false;
    }
    
    // Check if both cells are unrevealed and unflagged
    final cell1 = _gameState!.getCell(row1, col1);
    final cell2 = _gameState!.getCell(row2, col2);
    
    if (!cell1.isUnrevealed || cell1.isFlagged || !cell2.isUnrevealed || cell2.isFlagged) {
      print('🔍 GameProvider: One or both cells are not unrevealed/unflagged');
      return false;
    }
    
    // Find shared revealed neighbors (cells that are adjacent to both)
    final neighbors1 = _getRevealedNeighbors(row1, col1);
    final neighbors2 = _getRevealedNeighbors(row2, col2);
    
    for (final neighbor1 in neighbors1) {
      for (final neighbor2 in neighbors2) {
        if (neighbor1[0] == neighbor2[0] && neighbor1[1] == neighbor2[1]) {
          // Found a shared revealed neighbor
          final neighborRow = neighbor1[0];
          final neighborCol = neighbor1[1];
          final neighborCell = _gameState!.getCell(neighborRow, neighborCol);
          
          if (neighborCell.isRevealed && neighborCell.bombsAround > 0) {
            // Get unrevealed neighbors of this revealed cell
            final unrevealedNeighbors = _getUnrevealedNeighbors(neighborRow, neighborCol);
            final flaggedNeighbors = _getFlaggedNeighbors(neighborRow, neighborCol);
            
            // Check if this revealed cell needs exactly 1 more mine and has exactly 2 unrevealed neighbors
            final remainingMines = neighborCell.bombsAround - flaggedNeighbors.length;
            
            if (unrevealedNeighbors.length == 2 && remainingMines == 1) {
              // Check if both unrevealed neighbors are our two cells
              bool bothCellsPresent = false;
              bool otherCellsPresent = false;
              
              for (final unrevealed in unrevealedNeighbors) {
                if ((unrevealed[0] == row1 && unrevealed[1] == col1) ||
                    (unrevealed[0] == row2 && unrevealed[1] == col2)) {
                  bothCellsPresent = true;
                } else {
                  otherCellsPresent = true;
                }
              }
              
              if (bothCellsPresent && !otherCellsPresent) {
                print('🔍 GameProvider: Valid 50/50 confirmed: cells (${row1}, ${col1}) and (${row2}, ${col2}) share revealed neighbor (${neighborRow}, ${neighborCol}) with value ${neighborCell.bombsAround}');
                return true;
              }
            }
          }
        }
      }
    }
    
    print('🔍 GameProvider: No shared revealed neighbor found for cells (${row1}, ${col1}) and (${row2}, ${col2})');
    return false;
  }

  /// Check if a cell is part of a true 50/50 situation (exactly 2 cells with 0.5 probability)
  bool _isTrue5050Cell(int row, int col) {
    // Check if this cell is part of a true 50/50 situation
    for (List<int> cell in _fiftyFiftyCells) {
      if (cell[0] == row && cell[1] == col) {
        // Only log once per cell to avoid spam
        String cellKey = '$row,$col';
        if (!_logged5050Cells.contains(cellKey)) {
          _logged5050Cells.add(cellKey);
          
          // Find the other cell in this 50/50 pair
          List<int>? otherCell;
          for (List<int> other in _fiftyFiftyCells) {
            if (other[0] != row || other[1] != col) {
              otherCell = other;
              break;
            }
          }
          
          if (otherCell != null) {
            print('🎯 50/50 PAIR: [($row, $col), (${otherCell[0]}, ${otherCell[1]})] - Cell ($row, $col) has bomb: ${_gameState!.board[row][col].hasBomb}');
          } else {
            print('🎯 50/50 SINGLE: Cell ($row, $col) has bomb: ${_gameState!.board[row][col].hasBomb}');
          }
        }
        return true;
      }
    }
    return false;
  }

  /// Calculate the real probability for a cell (public method for UI)
  double calculateCellProbability(int row, int col) {
    return _calculateCellProbability(row, col);
  }

  /// Get detailed probability analysis for a cell (public method for UI)
  Map<String, dynamic> getCellProbabilityAnalysis(int row, int col) {
    if (_gameState == null) {
      return {
        'status': 'No game state',
        'revealedNeighbors': 0,
        'factors': ['Game not initialized'],
      };
    }
    
    final cell = _gameState!.getCell(row, col);
    final factors = <String>[];
    
    if (cell.isRevealed) {
      return {
        'status': 'Cell is revealed',
        'revealedNeighbors': 0,
        'factors': ['Cell value: ${cell.bombsAround}'],
      };
    }
    
    if (cell.isFlagged) {
      return {
        'status': 'Cell is flagged',
        'revealedNeighbors': 0,
        'factors': ['Cell is flagged'],
      };
    }
    
    final revealedNeighbors = _getRevealedNeighbors(row, col);
    factors.add('Has ${revealedNeighbors.length} revealed neighbors');
    
    if (revealedNeighbors.isEmpty) {
      return {
        'status': 'No revealed neighbors',
        'revealedNeighbors': 0,
        'factors': factors,
      };
    }
    
    double totalProbability = 0.0;
    int contributingNeighbors = 0;
    
    for (final neighbor in revealedNeighbors) {
      final neighborRow = neighbor[0];
      final neighborCol = neighbor[1];
      final neighborCell = _gameState!.getCell(neighborRow, neighborCol);
      
      if (neighborCell.isRevealed && neighborCell.bombsAround > 0) {
        final unrevealedNeighbors = _getUnrevealedNeighbors(neighborRow, neighborCol);
        final flaggedNeighbors = _getFlaggedNeighbors(neighborRow, neighborCol);
        final remainingMines = neighborCell.bombsAround - flaggedNeighbors.length;
        
        factors.add('Neighbor ($neighborRow, $neighborCol): needs $remainingMines mines from ${unrevealedNeighbors.length} cells');
        
        if (unrevealedNeighbors.isNotEmpty && remainingMines >= 0) {
          final probability = remainingMines / unrevealedNeighbors.length;
          totalProbability += probability;
          contributingNeighbors++;
          
          factors.add('  → Probability contribution: ${(probability * 100).toStringAsFixed(1)}%');
        }
      }
    }
    
    final finalProbability = contributingNeighbors > 0 ? totalProbability / contributingNeighbors : 0.0;
    
    String status;
    if (finalProbability > 0.4 && finalProbability < 0.6) {
      status = 'Near 50/50 situation';
    } else if (finalProbability > 0.6) {
      status = 'High probability of mine';
    } else if (finalProbability < 0.4) {
      status = 'Low probability of mine';
    } else {
      status = 'Unknown probability';
    }
    
    return {
      'status': status,
      'revealedNeighbors': revealedNeighbors.length,
      'factors': factors,
    };
  }

  /// Save current board state for debugging
  void saveBoardStateForDebug() {
    if (_gameState == null) return;
    
    final boardState = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'rows': _gameState!.rows,
      'columns': _gameState!.columns,
      'minesCount': _gameState!.minesCount,
      'board': <List<Map<String, dynamic>>>[],
    };
    
    for (int row = 0; row < _gameState!.rows; row++) {
      final rowData = <Map<String, dynamic>>[];
      for (int col = 0; col < _gameState!.columns; col++) {
        final cell = _gameState!.getCell(row, col);
        rowData.add({
          'row': row,
          'col': col,
          'hasBomb': cell.hasBomb,
          'bombsAround': cell.bombsAround,
          'isRevealed': cell.isRevealed,
          'isFlagged': cell.isFlagged,
          'state': cell.state.toString(),
        });
      }
      boardState['board'].add(rowData);
    }
    
    // Save to a file or print for debugging
    print('🔍🔍🔍 BOARD STATE SAVED FOR DEBUG 🔍🔍🔍');
    print('Board dimensions: ${_gameState!.rows}x${_gameState!.columns}');
    print('Total mines: ${_gameState!.minesCount}');
    print('Revealed cells: ${_gameState!.revealedCount}');
    print('Flagged cells: ${_gameState!.flaggedCount}');
    print('Board state JSON: ${boardState.toString()}');
  }

  /// Debug probability calculation with step-by-step reasoning
  Map<String, dynamic> debugProbabilityCalculation(int row, int col) {
    if (_gameState == null) {
      return {'error': 'No game state'};
    }
    
    final cell = _gameState!.getCell(row, col);
    if (cell.isRevealed) {
      return {'error': 'Cell is revealed', 'value': cell.bombsAround};
    }
    
    if (cell.isFlagged) {
      return {'error': 'Cell is flagged'};
    }
    
    final debug = <String, dynamic>{
      'targetCell': {'row': row, 'col': col, 'hasBomb': cell.hasBomb},
      'revealedNeighbors': <List<Map<String, dynamic>>>[],
      'calculation': <String, dynamic>{},
    };
    
    final revealedNeighbors = _getRevealedNeighbors(row, col);
    double totalProbability = 0.0;
    int contributingNeighbors = 0;
    
    for (final neighbor in revealedNeighbors) {
      final neighborRow = neighbor[0];
      final neighborCol = neighbor[1];
      final neighborCell = _gameState!.getCell(neighborRow, neighborCol);
      
      if (neighborCell.isRevealed && neighborCell.bombsAround > 0) {
        final unrevealedNeighbors = _getUnrevealedNeighbors(neighborRow, neighborCol);
        final flaggedNeighbors = _getFlaggedNeighbors(neighborRow, neighborCol);
        final remainingMines = neighborCell.bombsAround - flaggedNeighbors.length;
        
        final neighborDebug = {
          'position': [neighborRow, neighborCol],
          'value': neighborCell.bombsAround,
          'unrevealedNeighbors': unrevealedNeighbors.map((pos) => [pos[0], pos[1]]).toList(),
          'flaggedNeighbors': flaggedNeighbors.map((pos) => [pos[0], pos[1]]).toList(),
          'remainingMines': remainingMines,
          'probability': unrevealedNeighbors.isNotEmpty ? remainingMines / unrevealedNeighbors.length : 0.0,
        };
        
        debug['revealedNeighbors'].add([neighborDebug]);
        
        if (unrevealedNeighbors.isNotEmpty && remainingMines >= 0) {
          final probability = remainingMines / unrevealedNeighbors.length;
          totalProbability += probability;
          contributingNeighbors++;
        }
      }
    }
    
    final finalProbability = contributingNeighbors > 0 ? totalProbability / contributingNeighbors : 0.0;
    
    debug['calculation'] = {
      'totalProbability': totalProbability,
      'contributingNeighbors': contributingNeighbors,
      'finalProbability': finalProbability,
      'finalProbabilityPercent': (finalProbability * 100).toStringAsFixed(1),
    };
    
    return debug;
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
    final is5050 = _fiftyFiftyCells.any((cell) => cell[0] == row && cell[1] == col);
    if (is5050 && _gameState != null) {
      // Only log once per cell to avoid spam
      String cellKey = 'is5050_$row,$col';
      if (!_logged5050Cells.contains(cellKey)) {
        _logged5050Cells.add(cellKey);
        final cell = _gameState!.getCell(row, col);
        
        // Find the other cell in this 50/50 pair for better debug output
        List<int>? otherCell;
        for (List<int> fiftyFiftyCell in _fiftyFiftyCells) {
          if (fiftyFiftyCell[0] != row || fiftyFiftyCell[1] != col) {
            otherCell = fiftyFiftyCell;
            break;
          }
        }
        
        if (otherCell != null) {
          print('🎯 50/50 PAIR: [($row, $col), (${otherCell[0]}, ${otherCell[1]})] - Cell ($row, $col) has bomb: ${cell.hasBomb}');
        } else {
          print('🎯 50/50 SINGLE: Cell ($row, $col) has bomb: ${cell.hasBomb}');
        }
      }
    }
    return is5050;
  }

  // Reveal a cell as a 50/50 safe move if allowed
  Future<void> execute5050SafeMove(int row, int col) async {
    print('🎯 50/50 CLICK: User clicked 50/50 cell ($row, $col)');
    print('🎯 50/50 CLICK: Feature enabled: ${FeatureFlags.enable5050SafeMove}');
    print('🎯 50/50 CLICK: Cell in 50/50 situation: ${isCellIn5050Situation(row, col)}');
    
    if (!FeatureFlags.enable5050SafeMove) {
      print('🎯 50/50 CLICK: Feature disabled, falling back to regular reveal');
      await revealCell(row, col);
      return;
    }
    
    if (!isCellIn5050Situation(row, col)) {
      print('🎯 50/50 CLICK: Cell is not in 50/50 situation, falling back to regular reveal');
      await revealCell(row, col);
      return;
    }
    
    // Find the other cell in the 50/50 pair
    final otherCell = _findOtherCellIn5050Pair(row, col);
    if (otherCell != null) {
      print('🎯 50/50 CLICK: Found other cell in pair (${otherCell[0]}, ${otherCell[1]})');
      print('🎯 50/50 CLICK: Executing safe move from ($row, $col) to (${otherCell[0]}, ${otherCell[1]})');
      
      // Use the repository's safe move method
      _gameState = await _repository.perform5050SafeMove(row, col, otherCell[0], otherCell[1]);
      
      print('🎯 50/50 CLICK: Safe move completed - Game over: ${isGameOver}');
      
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
    } else {
      print('🎯 50/50 CLICK: Could not find other cell in pair, falling back to regular reveal');
      await revealCell(row, col);
    }
  }

  /// Find the other cell in a 50/50 pair
  List<int>? _findOtherCellIn5050Pair(int row, int col) {
    if (_gameState == null) return null;
    
    print('🔍 50/50 Safe Move: Looking for other cell in 50/50 pair for ($row, $col)');
    
    // Get revealed neighbors of the clicked cell
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
          print('🔍 50/50 Safe Move: Found 50/50 situation with neighbor ($neighborRow, $neighborCol)');
          
          // Find the other unrevealed cell (not the clicked one)
          for (final unrevealed in unrevealedNeighbors) {
            if (unrevealed[0] != row || unrevealed[1] != col) {
              print('🔍 50/50 Safe Move: Other cell in pair is (${unrevealed[0]}, ${unrevealed[1]})');
              return unrevealed;
            }
          }
        }
      }
    }
    
    print('🔍 50/50 Safe Move: No other cell found in pair');
    return null;
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

  /// Debug method to analyze why specific cells are not detected as 50/50
  void debug5050Analysis(int row, int col) {
    if (_gameState == null) {
      print('🔍 DEBUG: No game state available');
      return;
    }
    
    final cell = _gameState!.getCell(row, col);
    print('🔍 DEBUG: Analyzing cell ($row, $col)');
    print('🔍 DEBUG: Cell is revealed: ${cell.isRevealed}');
    print('🔍 DEBUG: Cell is flagged: ${cell.isFlagged}');
    
    if (cell.isRevealed) {
      print('🔍 DEBUG: Cell is revealed, cannot be part of 50/50');
      return;
    }
    
    if (cell.isFlagged) {
      print('🔍 DEBUG: Cell is flagged, cannot be part of 50/50');
      return;
    }
    
    final revealedNeighbors = _getRevealedNeighbors(row, col);
    print('🔍 DEBUG: Cell has ${revealedNeighbors.length} revealed neighbors');
    
    for (final neighbor in revealedNeighbors) {
      final neighborRow = neighbor[0];
      final neighborCol = neighbor[1];
      final neighborCell = _gameState!.getCell(neighborRow, neighborCol);
      
      print('🔍 DEBUG: Neighbor ($neighborRow, $neighborCol):');
      print('🔍 DEBUG:   - Value: ${neighborCell.bombsAround}');
      print('🔍 DEBUG:   - Is revealed: ${neighborCell.isRevealed}');
      
      if (neighborCell.isRevealed && neighborCell.bombsAround > 0) {
        final unrevealedNeighbors = _getUnrevealedNeighbors(neighborRow, neighborCol);
        final flaggedNeighbors = _getFlaggedNeighbors(neighborRow, neighborCol);
        final remainingMines = neighborCell.bombsAround - flaggedNeighbors.length;
        
        print('🔍 DEBUG:   - Unrevealed neighbors: ${unrevealedNeighbors.length}');
        print('🔍 DEBUG:   - Flagged neighbors: ${flaggedNeighbors.length}');
        print('🔍 DEBUG:   - Remaining mines needed: $remainingMines');
        
        // Check if this is a potential 50/50 situation
        if (unrevealedNeighbors.length == 2 && remainingMines == 1) {
          print('🔍 DEBUG:   ✅ POTENTIAL 50/50: 2 unrevealed neighbors, 1 remaining mine');
          
          // Check if current cell is one of the unrevealed neighbors
          bool isCurrentCellUnrevealed = unrevealedNeighbors.any((n) => n[0] == row && n[1] == col);
          if (isCurrentCellUnrevealed) {
            print('🔍 DEBUG:   ✅ Current cell is one of the unrevealed neighbors');
            
            // Find the other unrevealed neighbor
            List<int> otherCell = [-1, -1];
            for (final unrevealed in unrevealedNeighbors) {
              if (unrevealed[0] != row || unrevealed[1] != col) {
                otherCell = unrevealed;
                break;
              }
            }
            
            if (otherCell[0] != -1) {
              print('🔍 DEBUG:   ✅ Other unrevealed neighbor: (${otherCell[0]}, ${otherCell[1]})');
              
              // Check if the other cell has additional information
              final otherRevealedNeighbors = _getRevealedNeighbors(otherCell[0], otherCell[1]);
              bool hasAdditionalInfo = false;
              
              for (final otherNeighbor in otherRevealedNeighbors) {
                if (otherNeighbor[0] != neighborRow || otherNeighbor[1] != neighborCol) {
                  final otherNeighborCell = _gameState!.getCell(otherNeighbor[0], otherNeighbor[1]);
                  if (otherNeighborCell.isRevealed && otherNeighborCell.bombsAround > 0) {
                    final otherUnrevealedNeighbors = _getUnrevealedNeighbors(otherNeighbor[0], otherNeighbor[1]);
                    final otherFlaggedNeighbors = _getFlaggedNeighbors(otherNeighbor[0], otherNeighbor[1]);
                    final otherRemainingMines = otherNeighborCell.bombsAround - otherFlaggedNeighbors.length;
                    
                    print('🔍 DEBUG:   ⚠️ Other cell has additional neighbor (${otherNeighbor[0]}, ${otherNeighbor[1]})');
                    print('🔍 DEBUG:     - Unrevealed neighbors: ${otherUnrevealedNeighbors.length}');
                    print('🔍 DEBUG:     - Remaining mines: $otherRemainingMines');
                    
                    if (otherUnrevealedNeighbors.length != 2 || otherRemainingMines != 1) {
                      hasAdditionalInfo = true;
                      print('🔍 DEBUG:     ❌ Additional info breaks 50/50');
                      break;
                    }
                  }
                }
              }
              
              if (!hasAdditionalInfo) {
                print('🔍 DEBUG:   ✅ CONFIRMED: This is a true 50/50 situation!');
              } else {
                print('🔍 DEBUG:   ❌ REJECTED: Additional information breaks 50/50');
              }
            }
          } else {
            print('🔍 DEBUG:   ❌ Current cell is not one of the unrevealed neighbors');
          }
        } else {
          print('🔍 DEBUG:   ❌ NOT 50/50: ${unrevealedNeighbors.length} unrevealed neighbors, $remainingMines remaining mines');
        }
             } else {
         print('🔍 DEBUG:   ❌ NOT 50/50: Not a revealed number cell');
       }
     }
   }

  /// Get all cells that factored into the probability calculation for a given cell
  List<List<int>> getCellsInProbabilityCalculation(int row, int col) {
    if (_gameState == null) return [];
    
    final cell = _gameState!.getCell(row, col);
    if (cell.isRevealed || cell.isFlagged) return [];
    
    final contributingCells = <List<int>>[];
    final revealedNeighbors = _getRevealedNeighbors(row, col);
    
    for (final neighbor in revealedNeighbors) {
      final neighborRow = neighbor[0];
      final neighborCol = neighbor[1];
      final neighborCell = _gameState!.getCell(neighborRow, neighborCol);
      
      if (neighborCell.isRevealed && neighborCell.bombsAround > 0) {
        final unrevealedNeighbors = _getUnrevealedNeighbors(neighborRow, neighborCol);
        final flaggedNeighbors = _getFlaggedNeighbors(neighborRow, neighborCol);
        final remainingMines = neighborCell.bombsAround - flaggedNeighbors.length;
        
        if (unrevealedNeighbors.isNotEmpty && remainingMines >= 0) {
          // Add the revealed neighbor that's contributing
          contributingCells.add([neighborRow, neighborCol]);
          
          // Add all unrevealed neighbors that are part of the calculation
          for (final unrevealed in unrevealedNeighbors) {
            if (!contributingCells.any((cell) => cell[0] == unrevealed[0] && cell[1] == unrevealed[1])) {
              contributingCells.add(unrevealed);
            }
          }
          
          // Add flagged neighbors that are part of the calculation
          for (final flagged in flaggedNeighbors) {
            if (!contributingCells.any((cell) => cell[0] == flagged[0] && cell[1] == flagged[1])) {
              contributingCells.add(flagged);
            }
          }
        }
      }
    }
    
    return contributingCells;
  }
  
  /// Set cells to highlight for probability analysis
  void setProbabilityHighlight(int row, int col) {
    _probabilityHighlightCells = getCellsInProbabilityCalculation(row, col);
    notifyListeners();
  }
  
  /// Clear probability highlighting
  void clearProbabilityHighlight() {
    _probabilityHighlightCells = [];
    notifyListeners();
  }
  
  /// Check if a cell should be highlighted for probability analysis
  bool isCellHighlightedForProbability(int row, int col) {
    return _probabilityHighlightCells.any((cell) => cell[0] == row && cell[1] == col);
  }
  
  /// Debug a specific case - cell (4,0) that should be 100% but shows 77%
  void debugSpecificCase() {
    if (_gameState == null) {
      print('🔍 DEBUG: No game state available');
      return;
    }
    
    print('🔍🔍🔍 DEBUGGING CELL (4,0) CASE 🔍🔍🔍');
    
    // Check cell (4,0)
    final cell40 = _gameState!.getCell(4, 0);
    print('🔍 Cell (4,0): isRevealed=${cell40.isRevealed}, isFlagged=${cell40.isFlagged}, hasBomb=${cell40.hasBomb}');
    
    // Check cell (3,1) - the revealed "1"
    final cell31 = _gameState!.getCell(3, 1);
    print('🔍 Cell (3,1): isRevealed=${cell31.isRevealed}, bombsAround=${cell31.bombsAround}');
    
    if (cell31.isRevealed && cell31.bombsAround == 1) {
      // Get all neighbors of (3,1)
      final neighbors = _getAllNeighbors(3, 1);
      print('🔍 Neighbors of (3,1): ${neighbors.map((pos) => '(${pos[0]}, ${pos[1]})').join(', ')}');
      
      // Check each neighbor
      for (final neighbor in neighbors) {
        final neighborCell = _gameState!.getCell(neighbor[0], neighbor[1]);
        print('🔍 Neighbor (${neighbor[0]}, ${neighbor[1]}): isRevealed=${neighborCell.isRevealed}, isFlagged=${neighborCell.isFlagged}, hasBomb=${neighborCell.hasBomb}');
      }
      
      // Get unrevealed neighbors specifically
      final unrevealedNeighbors = _getUnrevealedNeighbors(3, 1);
      print('🔍 Unrevealed neighbors of (3,1): ${unrevealedNeighbors.map((pos) => '(${pos[0]}, ${pos[1]})').join(', ')}');
      
      // Get flagged neighbors
      final flaggedNeighbors = _getFlaggedNeighbors(3, 1);
      print('🔍 Flagged neighbors of (3,1): ${flaggedNeighbors.map((pos) => '(${pos[0]}, ${pos[1]})').join(', ')}');
      
      // Calculate what the probability should be
      final remainingMines = cell31.bombsAround - flaggedNeighbors.length;
      final probability = unrevealedNeighbors.isNotEmpty ? remainingMines / unrevealedNeighbors.length : 0.0;
      print('🔍 Expected probability for (4,0): ${(probability * 100).toStringAsFixed(1)}%');
      print('🔍   - Remaining mines needed: $remainingMines');
      print('🔍   - Unrevealed neighbors: ${unrevealedNeighbors.length}');
    }
  }
  
  /// Get all neighbors of a cell (including revealed, unrevealed, and flagged)
  List<List<int>> _getAllNeighbors(int row, int col) {
    final neighbors = <List<int>>[];
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final newRow = row + dr;
        final newCol = col + dc;
        if (newRow >= 0 && newRow < _gameState!.rows && newCol >= 0 && newCol < _gameState!.columns) {
          neighbors.add([newRow, newCol]);
        }
      }
    }
    return neighbors;
  }
} 