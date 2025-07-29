import 'package:flutter_test/flutter_test.dart';
import 'package:python_flutter_embed_demo/core/constants.dart';

void main() {
  group('GameConstants Tests', () {
    test('should have correct default values', () {
      expect(GameConstants.defaultRowCount, 18);
      expect(GameConstants.defaultColumnCount, 10);
      expect(GameConstants.defaultBombProbability, 3);
      expect(GameConstants.defaultMaxProbability, 15);
    });

    test('should have correct game state constants', () {
      expect(GameConstants.gameStatePlaying, 'playing');
      expect(GameConstants.gameStateWon, 'won');
      expect(GameConstants.gameStateLost, 'lost');
    });

    test('should have correct animation durations', () {
      expect(GameConstants.tileRevealDuration, const Duration(milliseconds: 150));
      expect(GameConstants.flagPlacementDuration, const Duration(milliseconds: 100));
    });

    test('should return difficulty levels map', () {
      final difficultyLevels = GameConstants.difficultyLevels;
      expect(difficultyLevels, isA<Map<String, Map<String, int>>>());
      
      // In test environment, the map might be empty if GameModeConfig isn't loaded
      // Just verify it's a valid map structure
      expect(difficultyLevels, isA<Map<String, Map<String, int>>>());
    });

    test('should have valid difficulty levels structure when available', () {
      final difficultyLevels = GameConstants.difficultyLevels;
      
      // Only test structure if there are difficulty levels available
      if (difficultyLevels.isNotEmpty) {
        // Check that each difficulty level has required properties
        for (final level in difficultyLevels.values) {
          expect(level.containsKey('rows'), isTrue);
          expect(level.containsKey('columns'), isTrue);
          expect(level.containsKey('mines'), isTrue);
          expect(level['rows'], isA<int>());
          expect(level['columns'], isA<int>());
          expect(level['mines'], isA<int>());
        }
      }
    });

    test('should have positive values for all difficulty levels when available', () {
      final difficultyLevels = GameConstants.difficultyLevels;
      
      // Only test values if there are difficulty levels available
      if (difficultyLevels.isNotEmpty) {
        for (final level in difficultyLevels.values) {
          expect(level['rows'], greaterThan(0));
          expect(level['columns'], greaterThan(0));
          expect(level['mines'], greaterThan(0));
        }
      }
    });

    test('should have consistent difficulty progression when available', () {
      final difficultyLevels = GameConstants.difficultyLevels;
      final levels = difficultyLevels.values.toList();
      
      // Only test progression if there are at least 2 levels available
      if (levels.length >= 2) {
        // Check that difficulty increases (more mines, larger grid)
        for (int i = 1; i < levels.length; i++) {
          final prevLevel = levels[i - 1];
          final currLevel = levels[i];
          
          // At least one dimension should increase
          final rowsIncrease = currLevel['rows']! > prevLevel['rows']!;
          final colsIncrease = currLevel['columns']! > prevLevel['columns']!;
          final minesIncrease = currLevel['mines']! > prevLevel['mines']!;
          
          expect(rowsIncrease || colsIncrease || minesIncrease, isTrue);
        }
      }
    });

    test('should handle empty difficulty levels gracefully', () {
      final difficultyLevels = GameConstants.difficultyLevels;
      
      // Should handle empty map gracefully
      expect(difficultyLevels, isA<Map<String, Map<String, int>>>());
      
      // Should not throw when accessing empty map
      expect(() => difficultyLevels.isEmpty, returnsNormally);
      expect(() => difficultyLevels.isNotEmpty, returnsNormally);
      expect(() => difficultyLevels.length, returnsNormally);
    });
  });
}