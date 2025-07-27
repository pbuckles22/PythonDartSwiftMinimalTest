import 'package:flutter/services.dart';

class Native5050Solver {
  static const MethodChannel _channel = MethodChannel('minesweeper/solver');

  /// Calls the native Swift/PythonKit 50/50 solver.
  /// [probabilityMap] should be a Map<String, double> where keys are '(row, col)' strings.
  /// Returns a List<List<int>> of 50/50 cell coordinates.
  static Future<List<List<int>>> find5050(Map<String, double> probabilityMap) async {
    try {
      final result = await _channel.invokeMethod('find5050', {
        'probabilityMap': probabilityMap,
      }).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('DEBUG: Native 50/50 solver timed out, returning empty result');
          return <List<int>>[];
        },
      );
      if (result is List) {
        return result.map<List<int>>((cell) => List<int>.from(cell)).toList();
      } else {
        throw Exception('Invalid result from native 50/50 solver: $result');
      }
    } catch (e) {
      print('DEBUG: Native 50/50 solver failed: $e');
      return <List<int>>[];
    }
  }
} 