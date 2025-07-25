import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Python Integration Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PythonDemoPage(),
    );
  }
}

class PythonDemoPage extends StatefulWidget {
  const PythonDemoPage({super.key});

  @override
  State<PythonDemoPage> createState() => _PythonDemoPageState();
}

class _PythonDemoPageState extends State<PythonDemoPage> {
  static const pythonChannel = MethodChannel('python/minimal');
  String _result = 'Click the button to call Python (1+1)';
  bool _loading = false;

  Future<void> _callPython() async {
    print('🔔 Dart: _callPython() called');
    setState(() { 
      _loading = true;
    });
    
    try {
      print('🔔 Dart: About to call native addOneAndOne...');
      final value = await pythonChannel.invokeMethod('addOneAndOne');
      print('🔔 Dart: Native returned: $value');
      
      setState(() {
        _result = 'Python result: $value';
      });
    } on PlatformException catch (e) {
      print('🔔 Dart: PlatformException: $e');
      setState(() {
        _result = 'Error: ${e.message}';
      });
    } catch (e, st) {
      print('🔔 Dart: Unexpected error: $e\n$st');
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Python Integration Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Python Integration Test',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'This app calls a Python script that adds 1+1',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _loading ? null : _callPython,
              child: Text(_loading ? 'Calling Python...' : 'Call Python (1+1)'),
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Result:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _result,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 