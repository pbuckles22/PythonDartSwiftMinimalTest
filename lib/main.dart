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
      title: 'PythonKit Minimal Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
  String _result = 'No result yet';
  bool _loading = false;

  Future<void> _callPython() async {
    print('🔔 Dart: _callPython() called');
    setState(() { _loading = true; });
    try {
      print('🔔 Dart: About to call native addOneAndOne...');
      final value = await pythonChannel.invokeMethod('addOneAndOne');
      print('🔔 Dart: Native returned: $value');
      setState(() {
        _result = 'Python returned: $value';
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
      appBar: AppBar(title: const Text('PythonKit Minimal Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _loading ? null : _callPython,
              child: const Text('Call Python add_one_and_one()'),
            ),
            const SizedBox(height: 24),
            _loading
                ? const CircularProgressIndicator()
                : Text(_result, style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
} 