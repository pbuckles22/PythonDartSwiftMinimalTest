import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:python_flutter_embed_demo/presentation/providers/settings_provider.dart';
import 'package:python_flutter_embed_demo/presentation/providers/game_provider.dart';
import 'package:python_flutter_embed_demo/core/feature_flags.dart';

void main() {
  group('Provider Integration Tests', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      // Reset FeatureFlags to default values before each test
      FeatureFlags.fiftyFiftySensitivity = 0.1;
    });

    test('should handle sensitivity callback mechanism', () {
      // Create providers directly
      final settingsProvider = SettingsProvider();
      final gameProvider = GameProvider();

      // Set up callback
      bool callbackCalled = false;
      settingsProvider.set5050SensitivityCallback(() {
        callbackCalled = true;
      });

      // Update sensitivity - should trigger callback
      settingsProvider.updateFiftyFiftySensitivity(0.15);

      // Verify callback was called and values updated
      expect(callbackCalled, true);
      expect(settingsProvider.fiftyFiftySensitivity, 0.15);
      expect(FeatureFlags.fiftyFiftySensitivity, 0.15);
    });

    test('should initialize with default sensitivity values', () {
      // Create settings provider
      final settingsProvider = SettingsProvider();

      // Verify default sensitivity
      expect(settingsProvider.fiftyFiftySensitivity, 0.1);
      expect(FeatureFlags.fiftyFiftySensitivity, 0.1);
    });

    test('should handle multiple sensitivity changes', () {
      // Create settings provider
      final settingsProvider = SettingsProvider();

      // Track callback calls
      int callbackCount = 0;
      settingsProvider.set5050SensitivityCallback(() {
        callbackCount++;
      });

      // Make multiple sensitivity changes
      settingsProvider.updateFiftyFiftySensitivity(0.05);
      settingsProvider.updateFiftyFiftySensitivity(0.1);
      settingsProvider.updateFiftyFiftySensitivity(0.2);

      // Verify callback was called for each change
      expect(callbackCount, 3);
      expect(settingsProvider.fiftyFiftySensitivity, 0.2);
      expect(FeatureFlags.fiftyFiftySensitivity, 0.2);
    });

    test('should handle null callback gracefully', () {
      // Create settings provider without setting callback
      final settingsProvider = SettingsProvider();

      // Should not throw when updating sensitivity
      expect(() => settingsProvider.updateFiftyFiftySensitivity(0.12), returnsNormally);
      expect(settingsProvider.fiftyFiftySensitivity, 0.12);
      expect(FeatureFlags.fiftyFiftySensitivity, 0.12);
    });
  });
} 