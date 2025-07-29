import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:python_flutter_embed_demo/core/icon_utils.dart';

void main() {
  group('IconUtils Tests', () {
    test('should return null for null input', () {
      expect(IconUtils.getIconFromString(null), isNull);
    });

    test('should return correct icons for valid strings', () {
      expect(IconUtils.getIconFromString('sentiment_satisfied'), equals(Icons.sentiment_satisfied));
      expect(IconUtils.getIconFromString('sentiment_neutral'), equals(Icons.sentiment_neutral));
      expect(IconUtils.getIconFromString('sentiment_dissatisfied'), equals(Icons.sentiment_dissatisfied));
      expect(IconUtils.getIconFromString('warning'), equals(Icons.warning));
      expect(IconUtils.getIconFromString('settings'), equals(Icons.settings));
      expect(IconUtils.getIconFromString('games'), equals(Icons.games));
      expect(IconUtils.getIconFromString('star'), equals(Icons.star));
      expect(IconUtils.getIconFromString('favorite'), equals(Icons.favorite));
      expect(IconUtils.getIconFromString('bolt'), equals(Icons.bolt));
      expect(IconUtils.getIconFromString('fire'), equals(Icons.local_fire_department));
      expect(IconUtils.getIconFromString('skull'), equals(Icons.sports_soccer));
      expect(IconUtils.getIconFromString('diamond'), equals(Icons.diamond));
      expect(IconUtils.getIconFromString('crown'), equals(Icons.emoji_events));
      expect(IconUtils.getIconFromString('rocket'), equals(Icons.rocket_launch));
      expect(IconUtils.getIconFromString('zombie'), equals(Icons.person));
      expect(IconUtils.getIconFromString('alien'), equals(Icons.face));
      expect(IconUtils.getIconFromString('robot'), equals(Icons.smart_toy));
      expect(IconUtils.getIconFromString('ghost'), equals(Icons.psychology));
      expect(IconUtils.getIconFromString('dragon'), equals(Icons.pets));
    });

    test('should return default icon for unknown strings', () {
      expect(IconUtils.getIconFromString('unknown_icon'), equals(Icons.games));
      expect(IconUtils.getIconFromString(''), equals(Icons.games));
      expect(IconUtils.getIconFromString('invalid'), equals(Icons.games));
    });

    test('should handle case sensitivity', () {
      expect(IconUtils.getIconFromString('SENTIMENT_SATISFIED'), equals(Icons.games));
      expect(IconUtils.getIconFromString('Sentiment_Satisfied'), equals(Icons.games));
    });

    test('should return non-null IconData for all valid cases', () {
      final validIcons = [
        'sentiment_satisfied',
        'sentiment_neutral',
        'sentiment_dissatisfied',
        'warning',
        'settings',
        'games',
        'star',
        'favorite',
        'bolt',
        'fire',
        'skull',
        'diamond',
        'crown',
        'rocket',
        'zombie',
        'alien',
        'robot',
        'ghost',
        'dragon',
      ];

      for (final iconString in validIcons) {
        final icon = IconUtils.getIconFromString(iconString);
        expect(icon, isNotNull);
        expect(icon, isA<IconData>());
      }
    });
  });
}