import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/cell.dart';
import '../../domain/entities/game_state.dart';
import '../providers/game_provider.dart';
import 'cell_widget.dart';
import '../../core/feature_flags.dart';

class GameBoard extends StatefulWidget {
  const GameBoard({Key? key}) : super(key: key);

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  double _zoomLevel = 1.0;
  static const double _minZoom = 1.0; // 100%
  static const double _maxZoom = 2.0; // 200%
  static const double _zoomStep = 0.1;

  final GlobalKey _boardKey = GlobalKey();
  final GlobalKey _firstCellKey = GlobalKey();
  double? _cellSize;
  bool _postLayoutAdjusted = false;
  double? _lastAvailableHeight;
  int? _lastRows;
  int? _lastColumns;
  static const double _epsilon = 0.5; // Acceptable pixel error
  
  // Add scroll controllers to maintain scroll position
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  void _debugBoardAndCellSize(int rows, int columns, double expectedCellSize) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final boardContext = _boardKey.currentContext;
      final cellContext = _firstCellKey.currentContext;
      if (boardContext != null) {
        final boardBox = boardContext.findRenderObject() as RenderBox?;
        if (boardBox != null) {
          final boardSize = boardBox.size;
          // print('DEBUG: Board rendered size: ${boardSize.width} x ${boardSize.height}');
          // print('DEBUG: Board expected height: ${expectedCellSize * rows + (rows - 1) * 2.0 * _zoomLevel}');
          // print('DEBUG: Board height diff: ${boardSize.height - (expectedCellSize * rows + (rows - 1) * 2.0 * _zoomLevel)}');
        }
      }
      if (cellContext != null) {
        final cellBox = cellContext.findRenderObject() as RenderBox?;
        if (cellBox != null) {
          final cellSize = cellBox.size;
          // print('DEBUG: First cell rendered size: ${cellSize.width} x ${cellSize.height}');
          // print('DEBUG: Expected cell size: $expectedCellSize');
          // print('DEBUG: Cell height diff: ${cellSize.height - expectedCellSize}');
        }
      }
    });
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _maybeAdjustCellSize(int rows, double availableHeight, double spacing) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final boardContext = _boardKey.currentContext;
      if (boardContext != null) {
        final boardBox = boardContext.findRenderObject() as RenderBox?;
        if (boardBox != null) {
          final actualHeight = boardBox.size.height;
          final expectedHeight = _cellSize! * rows + (rows - 1) * spacing;
          final diff = actualHeight - availableHeight;
          // Only adjust if the difference is significant
          if ((diff).abs() > _epsilon && !_postLayoutAdjusted) {
            final correctedCellSize = (availableHeight - (rows - 1) * spacing) / rows;
            setState(() {
              _cellSize = correctedCellSize;
              _postLayoutAdjusted = true;
            });
          } else if ((diff).abs() <= _epsilon && _postLayoutAdjusted) {
            // Reset for next game/board
            setState(() {
              _postLayoutAdjusted = false;
            });
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final gameState = gameProvider.gameState;
        if (gameState == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = gameState.rows;
        final columns = gameState.columns;
        // Reset cell size and adjustment if board size or available height changes
        final shouldReset = _lastRows != rows || _lastColumns != columns || _lastAvailableHeight != null && _lastAvailableHeight != MediaQuery.of(context).size.height;
        if (shouldReset) {
          _cellSize = null;
          _postLayoutAdjusted = false;
          _lastRows = rows;
          _lastColumns = columns;
          _lastAvailableHeight = MediaQuery.of(context).size.height;
        }
        return Column(
          children: [
            _buildGameHeader(context, gameProvider),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableHeight = constraints.maxHeight;
                  final spacing = 2.0 * _zoomLevel;
                  final cellSize = _cellSize ?? (availableHeight - (rows - 1) * spacing) / rows;
                  final boardHeight = cellSize * rows + (rows - 1) * spacing;
                  final boardWidth = columns * cellSize + (columns - 1) * spacing;
                  // Feedback loop: measure and adjust after first layout
                  if (_cellSize == null || !_postLayoutAdjusted) {
                    _cellSize = cellSize;
                    _maybeAdjustCellSize(rows, availableHeight, spacing);
                  }
                  // Debug prints removed to prevent infinite loop
                  // print('DEBUG: Calculated cellSize: $cellSize');
                  // print('DEBUG: Calculated boardHeight: $boardHeight');
                  // print('DEBUG: Calculated boardWidth: $boardWidth');
                  // _debugBoardAndCellSize(rows, columns, cellSize);
                  Widget grid = Container(
                    key: _boardKey,
                    width: boardWidth,
                    height: boardHeight,
                    color: Colors.blue.withOpacity(0.05), // Visual debug
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        childAspectRatio: 1.0,
                        mainAxisSpacing: spacing,
                        crossAxisSpacing: spacing,
                      ),
                      itemCount: rows * columns,
                      itemBuilder: (context, index) {
                        final row = index ~/ columns;
                        final col = index % columns;
                        final cellKey = (index == 0) ? _firstCellKey : null;
                        return SizedBox(
                          key: cellKey,
                          width: cellSize,
                          height: cellSize,
                          child: CellWidget(
                            row: row,
                            col: col,
                            onTap: () {
                              final is5050Cell = gameProvider.isCellIn5050Situation(row, col);
                              final is5050SafeMoveEnabled = FeatureFlags.enable5050SafeMove;
                              if (is5050Cell && is5050SafeMoveEnabled) {
                                gameProvider.execute5050SafeMove(row, col);
                              } else {
                                gameProvider.revealCell(row, col);
                              }
                            },
                            onLongPress: () {
                              gameProvider.toggleFlag(row, col);
                              // _debugBoardAndCellSize(rows, columns, cellSize);
                            },
                          ),
                        );
                      },
                    ),
                  );
                  // If the board is taller than the available height, allow vertical scrolling
                  if (boardHeight > availableHeight + 0.5) {
                    return SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        controller: _verticalScrollController,
                        scrollDirection: Axis.vertical,
                        child: grid,
                      ),
                    );
                  } else {
                    // No vertical scroll, only horizontal if needed
                    return SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: grid,
                    );
                  }
                },
              ),
            ),
            Container(
              height: 60.0,
              child: Center(
                child: _buildZoomControls(context),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGameHeader(BuildContext context, GameProvider gameProvider) {
    final gameState = gameProvider.gameState!;
    final stats = gameProvider.getGameStatistics();
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Mine counter
          _buildStatCard(
            context,
            'Mines',
            '${gameProvider.getRemainingMines()}',
            Icons.warning,
          ),
          
          // Timer with continuous updates
          Consumer<GameProvider>(
            builder: (context, provider, child) {
              final elapsed = provider.timerService.elapsed;
              final timeString = '${elapsed.inMinutes.toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
              return _buildStatCard(
                context,
                'Time',
                timeString,
                Icons.timer,
              );
            },
          ),
          
          // Progress
          _buildStatCard(
            context,
            'Progress',
            _progressString(gameState.progressPercentage),
            Icons.bar_chart,
          ),
        ],
      ),
    );
  }

  Widget _buildZoomControls(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _zoomOut,
            icon: const Icon(Icons.zoom_out),
            tooltip: 'Zoom Out',
            iconSize: 20,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '${(_zoomLevel * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: _zoomIn,
            icon: const Icon(Icons.zoom_in),
            tooltip: 'Zoom In',
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _zoomIn() {
    if (_zoomLevel < _maxZoom) {
      setState(() {
        _zoomLevel = (_zoomLevel + _zoomStep).clamp(_minZoom, _maxZoom);
      });
    }
  }

  void _zoomOut() {
    if (_zoomLevel > _minZoom) {
      setState(() {
        _zoomLevel = (_zoomLevel - _zoomStep).clamp(_minZoom, _maxZoom);
      });
    }
  }

  String _progressString(double progress) {
    if (progress.isNaN || progress.isInfinite || progress < 0) return '0%';
    final percent = (progress * 100).clamp(0, 100).toInt();
    return '$percent%';
  }
} 