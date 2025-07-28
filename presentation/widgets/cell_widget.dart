import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/cell.dart';
import '../providers/game_provider.dart';
import '../../services/haptic_service.dart';
import '../../core/feature_flags.dart';

class CellWidget extends StatelessWidget {
  final int row;
  final int col;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const CellWidget({
    Key? key,
    required this.row,
    required this.col,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final cell = gameProvider.getCell(row, col);
        final is5050 = gameProvider.isCellIn5050Situation(row, col);
        
        if (cell == null) {
          return const SizedBox.shrink();
        }

        return RawGestureDetector(
          gestures: <Type, GestureRecognizerFactory>{
            LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(
                duration: const Duration(milliseconds: 200), // Fast flagging
              ),
              (LongPressGestureRecognizer instance) {
                instance.onLongPress = () {
                  if (gameProvider.isPlaying && gameProvider.isValidAction(row, col)) {
                    HapticService.mediumImpact();
                    onLongPress();
                  }
                };
              },
            ),
            TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                TapGestureRecognizer>(
              () => TapGestureRecognizer(),
              (TapGestureRecognizer instance) {
                instance.onTap = () {
                  if (gameProvider.isPlaying && gameProvider.isValidAction(row, col)) {
                    onTap();
                  }
                };
              },
            ),
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.all(1.0),
            decoration: BoxDecoration(
              color: _getCellColor(context, cell, is5050),
              border: Border.all(
                color: _getCellBorderColor(context, cell, is5050),
                width: _getCellBorderWidth(is5050),
              ),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Center(
              child: _buildCellContent(context, cell, is5050),
            ),
          ),
        );
      },
    );
  }

  Color _getCellColor(BuildContext context, Cell cell, bool is5050) {
    if (cell.isHitBomb) {
      return Colors.yellow.shade600; // Yellow background for the bomb that was hit
    } else if (cell.isExploded) {
      return Colors.red;
    } else if (cell.isIncorrectlyFlagged) {
      return Colors.red;
    } else if (cell.isRevealed) {
      return Theme.of(context).colorScheme.surface;
    } else if (cell.isFlagged) {
      return Theme.of(context).colorScheme.primaryContainer;
    } else if (is5050) {
      return Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.8);
    } else {
      return Theme.of(context).colorScheme.surfaceVariant;
    }
  }

  Color _getCellBorderColor(BuildContext context, Cell cell, bool is5050) {
    if (is5050 && FeatureFlags.enable5050Detection) {
      return Colors.orange.shade600; // Orange border for 50/50 cells
    }
    return Theme.of(context).colorScheme.outline.withOpacity(0.3);
  }

  double _getCellBorderWidth(bool is5050) {
    if (is5050 && FeatureFlags.enable5050Detection) {
      return 2.0; // Thicker border for 50/50 cells
    }
    return 1.0;
  }

  Widget _buildCellContent(BuildContext context, Cell cell, bool is5050) {
    if (cell.isHitBomb) {
      // The specific bomb that was clicked and caused the game to end
      return const Text(
        '💣', // Bomb emoji for the bomb that was hit
        style: TextStyle(fontSize: 20, color: Colors.red), // Red bomb on yellow background
      );
    } else if (cell.isFlagged) {
      return Icon(
        Icons.flag,
        color: Theme.of(context).colorScheme.primary,
        size: 20,
      );
    } else if (cell.isIncorrectlyFlagged) {
      return Icon(
        Icons.close,
        color: Colors.black,
        size: 20,
      );
    } else if (cell.isExploded) {
      return Icon(
        Icons.warning,
        color: Colors.white,
        size: 20,
      );
    } else if (cell.isRevealed) {
      if (cell.hasBomb) {
        return const Text(
          '💣', // Bomb emoji for other bombs
          style: TextStyle(fontSize: 20),
        );
      } else if (cell.bombsAround > 0) {
        return Text(
          '${cell.bombsAround}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: _getNumberColor(cell.bombsAround),
            fontWeight: FontWeight.bold,
          ),
        );
      } else {
        return const SizedBox.shrink(); // Empty cell
      }
    } else if (is5050 && FeatureFlags.enable5050Detection) {
      // Show a subtle indicator for 50/50 cells
      return Stack(
        alignment: Alignment.center,
        children: [
          // Main cell content (empty for unrevealed)
          const SizedBox.shrink(),
          // 50/50 indicator in top-right corner
          Positioned(
            top: 2,
            right: 2,
            child: Icon(
              Icons.help_outline,
              color: Colors.orange.shade600,
              size: 12,
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink(); // Unrevealed cell
    }
  }

  Color _getNumberColor(int number) {
    switch (number) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.red;
      case 4:
        return Colors.purple;
      case 5:
        return Colors.brown;
      case 6:
        return Colors.cyan;
      case 7:
        return Colors.black;
      case 8:
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
} 