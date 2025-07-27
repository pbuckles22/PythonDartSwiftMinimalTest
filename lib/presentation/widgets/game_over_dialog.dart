import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../../services/haptic_service.dart';

class GameOverDialog extends StatelessWidget {
  final bool isWin;
  final Duration gameDuration;
  final VoidCallback onNewGame;
  final VoidCallback onClose;

  const GameOverDialog({
    Key? key,
    required this.isWin,
    required this.gameDuration,
    required this.onNewGame,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Provide haptic feedback
    if (isWin) {
      HapticService.mediumImpact();
    } else {
      HapticService.heavyImpact();
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      title: Row(
        children: [
          Icon(
            isWin ? Icons.emoji_events : Icons.warning,
            color: isWin ? Colors.amber : Colors.red,
            size: 32,
          ),
          const SizedBox(width: 12),
          Text(
            isWin ? 'Congratulations!' : 'Game Over',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isWin ? Colors.amber : Colors.red,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isWin 
                ? 'You successfully cleared all mines!'
                : 'You stepped on a mine!',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          _buildGameStats(context),
          const SizedBox(height: 16),
          Text(
            isWin 
                ? 'Great job! Try a harder difficulty next time.'
                : 'Don\'t give up! Try again to improve your skills.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onClose,
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: onNewGame,
          icon: const Icon(Icons.refresh),
          label: const Text('New Game'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isWin ? Colors.amber : Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildGameStats(BuildContext context) {
    final timeString = '${gameDuration.inMinutes.toString().padLeft(2, '0')}:${(gameDuration.inSeconds % 60).toString().padLeft(2, '0')}';
    
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Game Statistics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.timer, size: 16),
              const SizedBox(width: 8),
              Text('Time: $timeString'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isWin ? Icons.emoji_events : Icons.warning,
                size: 16,
                color: isWin ? Colors.amber : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                isWin ? 'Result: Victory!' : 'Result: Defeat',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isWin ? Colors.amber : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 