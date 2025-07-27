import 'package:flutter/material.dart';

class IconUtils {
  /// Convert icon string from JSON to IconData
  static IconData? getIconFromString(String? iconString) {
    if (iconString == null) return null;
    
    switch (iconString) {
      case 'sentiment_satisfied':
        return Icons.sentiment_satisfied;
      case 'sentiment_neutral':
        return Icons.sentiment_neutral;
      case 'sentiment_dissatisfied':
        return Icons.sentiment_dissatisfied;
      case 'warning':
        return Icons.warning;
      case 'settings':
        return Icons.settings;
      case 'games':
        return Icons.games;
      case 'star':
        return Icons.star;
      case 'favorite':
        return Icons.favorite;
      case 'bolt':
        return Icons.bolt;
      case 'fire':
        return Icons.local_fire_department;
      case 'skull':
        return Icons.sports_soccer; // Using soccer as proxy for skull
      case 'diamond':
        return Icons.diamond;
      case 'crown':
        return Icons.emoji_events;
      case 'rocket':
        return Icons.rocket_launch;
      case 'zombie':
        return Icons.person;
      case 'alien':
        return Icons.face;
      case 'robot':
        return Icons.smart_toy;
      case 'ghost':
        return Icons.psychology;
      case 'dragon':
        return Icons.pets;
      default:
        return Icons.games; // Default fallback
    }
  }
} 