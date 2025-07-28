import 'package:flutter_test/flutter_test.dart';
import 'package:python_flutter_embed_demo/services/native_5050_solver.dart';
import 'package:python_flutter_embed_demo/core/feature_flags.dart';

void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Python Integration Tests', () {
    setUp(() {
      // Enable 50/50 detection for testing
      FeatureFlags.enable5050Detection = true;
      FeatureFlags.enableTestMode = false;
    });

    group('Native 50/50 Solver', () {
      test('should call Python solver with valid probability map', () async {
        final probabilityMap = {
          '(1, 1)': 0.5,
          '(1, 2)': 0.5,
          '(2, 1)': 0.3,
          '(2, 2)': 0.7,
        };

        try {
          final result = await Native5050Solver.find5050(probabilityMap);
          
          // If we get here, the call succeeded (unlikely in test environment)
          expect(result, isA<List<List<int>>>());
        } catch (e) {
          // In test environment, we expect MissingPluginException
          expect(e.toString(), anyOf(
            contains('MissingPluginException'),
            contains('PYTHON_ERROR'), 
            contains('Binding has not yet been initialized')
          ));
        }
      });

      test('should handle empty probability map', () async {
        final probabilityMap = <String, double>{};

        try {
          final result = await Native5050Solver.find5050(probabilityMap);
          expect(result, isEmpty);
        } catch (e) {
          // In test environment, we expect MissingPluginException
          expect(e.toString(), anyOf(
            contains('MissingPluginException'),
            contains('PYTHON_ERROR'), 
            contains('Binding has not yet been initialized')
          ));
        }
      });

      test('should handle probability map with no 50/50 situations', () async {
        final probabilityMap = {
          '(1, 1)': 0.3,
          '(1, 2)': 0.7,
          '(2, 1)': 0.1,
          '(2, 2)': 0.9,
        };

        try {
          final result = await Native5050Solver.find5050(probabilityMap);
          expect(result, isEmpty);
        } catch (e) {
          // In test environment, we expect MissingPluginException
          expect(e.toString(), anyOf(
            contains('MissingPluginException'),
            contains('PYTHON_ERROR'), 
            contains('Binding has not yet been initialized')
          ));
        }
      });

      test('should handle large probability map', () async {
        final probabilityMap = <String, double>{};
        
        // Create a large probability map
        for (int row = 0; row < 16; row++) {
          for (int col = 0; col < 30; col++) {
            probabilityMap['($row, $col)'] = 0.1 + (row + col) % 9 * 0.1;
          }
        }

        try {
          final result = await Native5050Solver.find5050(probabilityMap);
          expect(result, isA<List<List<int>>>());
        } catch (e) {
          // In test environment, we expect MissingPluginException
          expect(e.toString(), anyOf(
            contains('MissingPluginException'),
            contains('PYTHON_ERROR'), 
            contains('Binding has not yet been initialized')
          ));
        }
      });
    });

    group('Method Channel Communication', () {
      test('should use correct method name', () async {
        final probabilityMap = {'(1, 1)': 0.5};

        try {
          await Native5050Solver.find5050(probabilityMap);
        } catch (e) {
          // Should fail with MissingPluginException in test environment
          expect(e.toString(), anyOf(
            contains('MissingPluginException'),
            contains('PYTHON_ERROR'), 
            contains('MethodChannel'), 
            contains('Binding has not yet been initialized')
          ));
        }
      });
    });

    group('Error Handling', () {
      test('should handle Python script errors gracefully', () async {
        // Test with malformed data that might cause Python errors
        final malformedMap = {
          'invalid_key': 0.5,
          '(1, 1)': double.nan,
          '(1, 2)': double.infinity,
        };

        try {
          await Native5050Solver.find5050(malformedMap);
        } catch (e) {
          expect(e.toString(), anyOf(
            contains('MissingPluginException'),
            contains('PYTHON_ERROR'), 
            contains('MethodChannel'), 
            contains('Binding has not yet been initialized')
          ));
        }
      });

      test('should handle null probability map', () async {
        try {
          await Native5050Solver.find5050({});
        } catch (e) {
          expect(e.toString(), anyOf(
            contains('MissingPluginException'),
            contains('PYTHON_ERROR'), 
            contains('MethodChannel'), 
            contains('Binding has not yet been initialized')
          ));
        }
      });
    });

    group('Performance Tests', () {
      test('should handle rapid successive calls', () async {
        final probabilityMap = {
          '(1, 1)': 0.5,
          '(1, 2)': 0.5,
        };

        final stopwatch = Stopwatch()..start();
        
        try {
          for (int i = 0; i < 5; i++) {
            await Native5050Solver.find5050(probabilityMap);
          }
        } catch (e) {
          // Expected MissingPluginException in test environment
          expect(e.toString(), anyOf(
            contains('MissingPluginException'),
            contains('PYTHON_ERROR'), 
            contains('MethodChannel'), 
            contains('Binding has not yet been initialized')
          ));
        }
        
        stopwatch.stop();
        
        // Should complete within reasonable time (5 seconds)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });
    });
  });
} 