import 'package:flutter/services.dart';

class Native5050Solver {
  static const MethodChannel _channel = MethodChannel('python/minimal');

  /// Calls the native Swift/PythonKit 50/50 solver.
  /// [probabilityMap] should be a Map<String, double> where keys are '(row, col)' strings.
  /// Returns a List<List<int>> of 50/50 cell coordinates.
  static Future<List<List<int>>> find5050(Map<String, double> probabilityMap) async {
    try {
      print('🔍 Native5050Solver: Calling find5050Situations with probability map: $probabilityMap');
      
      final result = await _channel.invokeMethod('find5050Situations', {
        'probabilityMap': probabilityMap,
      }).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('DEBUG: Native 50/50 solver timed out, returning empty result');
          return <List<int>>[];
        },
      );
      
      print('🔍 Native5050Solver: Received result: $result');
      
      if (result is List) {
        final cells = result.map<List<int>>((cell) => List<int>.from(cell)).toList();
        print('🔍 Native5050Solver: Converted to cells: $cells');
        return cells;
      } else {
        throw Exception('Invalid result from native 50/50 solver: $result');
      }
    } catch (e) {
      print('DEBUG: Native 50/50 solver failed: $e');
      return <List<int>>[];
    }
  }
} 