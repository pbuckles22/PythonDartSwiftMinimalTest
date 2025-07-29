import 'package:flutter_test/flutter_test.dart';
import 'package:python_flutter_embed_demo/services/haptic_service.dart';
import 'package:python_flutter_embed_demo/core/feature_flags.dart';

void main() {
  group('HapticService Tests', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    test('should not throw when haptic feedback is disabled', () {
      final originalValue = FeatureFlags.enableHapticFeedback;
      FeatureFlags.enableHapticFeedback = false;
      
      try {
        // Should not throw exceptions when disabled
        expect(() => HapticService.lightImpact(), returnsNormally);
        expect(() => HapticService.mediumImpact(), returnsNormally);
        expect(() => HapticService.heavyImpact(), returnsNormally);
        expect(() => HapticService.selectionClick(), returnsNormally);
        expect(() => HapticService.vibrate(), returnsNormally);
      } finally {
        FeatureFlags.enableHapticFeedback = originalValue;
      }
    });

    test('should not throw when haptic feedback is enabled', () {
      final originalValue = FeatureFlags.enableHapticFeedback;
      FeatureFlags.enableHapticFeedback = true;
      
      try {
        // Should not throw exceptions when enabled (even if platform doesn't support it)
        expect(() => HapticService.lightImpact(), returnsNormally);
        expect(() => HapticService.mediumImpact(), returnsNormally);
        expect(() => HapticService.heavyImpact(), returnsNormally);
        expect(() => HapticService.selectionClick(), returnsNormally);
        expect(() => HapticService.vibrate(), returnsNormally);
      } finally {
        FeatureFlags.enableHapticFeedback = originalValue;
      }
    });

    test('should handle feature flag changes', () {
      final originalValue = FeatureFlags.enableHapticFeedback;
      
      try {
        // Test with disabled
        FeatureFlags.enableHapticFeedback = false;
        expect(() => HapticService.lightImpact(), returnsNormally);
        
        // Test with enabled
        FeatureFlags.enableHapticFeedback = true;
        expect(() => HapticService.lightImpact(), returnsNormally);
        
        // Test with disabled again
        FeatureFlags.enableHapticFeedback = false;
        expect(() => HapticService.lightImpact(), returnsNormally);
      } finally {
        FeatureFlags.enableHapticFeedback = originalValue;
      }
    });

    test('should handle all haptic methods consistently', () {
      final originalValue = FeatureFlags.enableHapticFeedback;
      
      try {
        // Test all methods with haptic disabled
        FeatureFlags.enableHapticFeedback = false;
        expect(() => HapticService.lightImpact(), returnsNormally);
        expect(() => HapticService.mediumImpact(), returnsNormally);
        expect(() => HapticService.heavyImpact(), returnsNormally);
        expect(() => HapticService.selectionClick(), returnsNormally);
        expect(() => HapticService.vibrate(), returnsNormally);
        
        // Test all methods with haptic enabled
        FeatureFlags.enableHapticFeedback = true;
        expect(() => HapticService.lightImpact(), returnsNormally);
        expect(() => HapticService.mediumImpact(), returnsNormally);
        expect(() => HapticService.heavyImpact(), returnsNormally);
        expect(() => HapticService.selectionClick(), returnsNormally);
        expect(() => HapticService.vibrate(), returnsNormally);
      } finally {
        FeatureFlags.enableHapticFeedback = originalValue;
      }
    });

    test('should handle rapid successive calls', () {
      final originalValue = FeatureFlags.enableHapticFeedback;
      FeatureFlags.enableHapticFeedback = true;
      
      try {
        // Make rapid successive calls
        for (int i = 0; i < 5; i++) {
          expect(() => HapticService.lightImpact(), returnsNormally);
          expect(() => HapticService.mediumImpact(), returnsNormally);
          expect(() => HapticService.heavyImpact(), returnsNormally);
          expect(() => HapticService.selectionClick(), returnsNormally);
          expect(() => HapticService.vibrate(), returnsNormally);
        }
      } finally {
        FeatureFlags.enableHapticFeedback = originalValue;
      }
    });

    test('should handle concurrent calls', () {
      final originalValue = FeatureFlags.enableHapticFeedback;
      FeatureFlags.enableHapticFeedback = true;
      
      try {
        // Make concurrent calls
        expect(() => HapticService.lightImpact(), returnsNormally);
        expect(() => HapticService.mediumImpact(), returnsNormally);
        expect(() => HapticService.heavyImpact(), returnsNormally);
        expect(() => HapticService.selectionClick(), returnsNormally);
        expect(() => HapticService.vibrate(), returnsNormally);
      } finally {
        FeatureFlags.enableHapticFeedback = originalValue;
      }
    });
  });
}