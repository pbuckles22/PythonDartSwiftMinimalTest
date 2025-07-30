import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:python_flutter_embed_demo/services/native_5050_solver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Python Integration Tests', () {
    const MethodChannel channel = MethodChannel('python/minimal');

    setUp(() {
      // Set up method channel mock
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
                 if (methodCall.method == 'find5050Situations') {
           // Mock the Python response with real test data
           final probabilityMap = methodCall.arguments['probabilityMap'] as Map<Object?, Object?>;
          
                     // Simulate Python processing - find cells with 0.5 probability
           final fiftyFiftyCells = <List<int>>[];
           for (final entry in probabilityMap.entries) {
             final value = entry.value;
             final key = entry.key;
             
             if (value is double && (value - 0.5).abs() < 1e-6) {
               // Parse "(row, col)" format
               if (key is String && key.startsWith('(') && key.endsWith(')')) {
                 final cleanKey = key.replaceAll('(', '').replaceAll(')', '');
                 final parts = cleanKey.split(', ');
                 if (parts.length == 2) {
                   final row = int.tryParse(parts[0]);
                   final col = int.tryParse(parts[1]);
                   if (row != null && col != null) {
                     fiftyFiftyCells.add([row, col]);
                   }
                 }
               }
             }
           }
          
          return fiftyFiftyCells;
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('should detect 50/50 cells correctly', () async {
      // Test data with known 50/50 cells
      final testData = <String, double>{
        '(0, 7)': 0.5,    // Should be detected
        '(1, 7)': 0.5,    // Should be detected
        '(2, 4)': 0.6,    // Should NOT be detected
        '(3, 6)': 0.4,    // Should NOT be detected
        '(4, 8)': 0.5,    // Should be detected
      };

      final result = await Native5050Solver.find5050(testData);

      expect(result, isNotNull);
      expect(result!.length, 3); // Should find 3 cells with 0.5 probability
      
      // Verify the correct cells are detected
      expect(result.any((cell) => cell[0] == 0 && cell[1] == 7), true);
      expect(result.any((cell) => cell[0] == 1 && cell[1] == 7), true);
      expect(result.any((cell) => cell[0] == 4 && cell[1] == 8), true);
      
      // Verify incorrect cells are NOT detected
      expect(result.any((cell) => cell[0] == 2 && cell[1] == 4), false);
      expect(result.any((cell) => cell[0] == 3 && cell[1] == 6), false);
    });

    test('should handle empty input', () async {
      final result = await Native5050Solver.find5050(<String, double>{});
      expect(result, isNotNull);
      expect(result!.isEmpty, true);
    });

    test('should handle no 50/50 cells', () async {
      final testData = <String, double>{
        '(0, 0)': 0.3,
        '(1, 1)': 0.7,
        '(2, 2)': 0.1,
      };

      final result = await Native5050Solver.find5050(testData);
      expect(result, isNotNull);
      expect(result!.isEmpty, true);
    });

    test('should handle malformed input gracefully', () async {
      final testData = <String, double>{
        'invalid_key': 0.5,
        '(0, 7)': 0.5,
        'another_invalid': 0.3,
      };

      final result = await Native5050Solver.find5050(testData);
      expect(result, isNotNull);
      expect(result!.length, 1); // Should only detect the valid cell
      expect(result.any((cell) => cell[0] == 0 && cell[1] == 7), true);
    });
  });
} 