import 'package:flutter/services.dart';
import '../core/feature_flags.dart';

class HapticService {
  static void lightImpact() {
    if (FeatureFlags.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  static void mediumImpact() {
    if (FeatureFlags.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }
  }

  static void heavyImpact() {
    if (FeatureFlags.enableHapticFeedback) {
      HapticFeedback.heavyImpact();
    }
  }

  static void selectionClick() {
    if (FeatureFlags.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
  }

  static void vibrate() {
    if (FeatureFlags.enableHapticFeedback) {
      HapticFeedback.vibrate();
    }
  }
} 