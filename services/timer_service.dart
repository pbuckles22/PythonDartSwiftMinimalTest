import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class TimerService extends ChangeNotifier with WidgetsBindingObserver {
  Timer? _timer;
  DateTime? _startTime;
  DateTime? _pauseTime;
  Duration _elapsed = Duration.zero;
  bool _isRunning = false;
  bool _isPaused = false;

  TimerService() {
    WidgetsBinding.instance.addObserver(this);
  }

  Duration get elapsed => _elapsed;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _pauseTimer();
        break;
      case AppLifecycleState.resumed:
        _resumeTimer();
        break;
      default:
        break;
    }
  }

  void start() {
    if (_isRunning) return;
    
    _startTime = DateTime.now();
    _isRunning = true;
    _isPaused = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateElapsed();
    });
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _isPaused = false;
    _pauseTime = null;
    notifyListeners();
  }

  void reset() {
    stop();
    _elapsed = Duration.zero;
    _startTime = null;
    notifyListeners();
  }

  void _pauseTimer() {
    if (_isRunning && !_isPaused) {
      _pauseTime = DateTime.now();
      _isPaused = true;
      _timer?.cancel();
      _timer = null;
      notifyListeners();
    }
  }

  void _resumeTimer() {
    if (_isRunning && _isPaused) {
      if (_pauseTime != null && _startTime != null) {
        // Adjust start time to account for the pause duration
        final pauseDuration = _pauseTime!.difference(_startTime!);
        _startTime = DateTime.now().subtract(pauseDuration);
      }
      _isPaused = false;
      _pauseTime = null;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _updateElapsed();
      });
      notifyListeners();
    }
  }

  void _updateElapsed() {
    if (_startTime != null && !_isPaused) {
      _elapsed = DateTime.now().difference(_startTime!);
      notifyListeners();
    }
  }
} 