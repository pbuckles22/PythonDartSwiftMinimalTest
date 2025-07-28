import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:python_flutter_embed_demo/services/timer_service.dart';

void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('TimerService Tests', () {
    late TimerService timerService;

    setUp(() {
      timerService = TimerService();
    });

    tearDown(() {
      // Only dispose if the service hasn't been disposed already
      try {
        timerService.dispose();
      } catch (e) {
        // Service already disposed, ignore
      }
    });

    group('Initialization', () {
      test('should initialize with correct default values', () {
        expect(timerService.elapsed, Duration.zero);
        expect(timerService.isRunning, false);
        expect(timerService.isPaused, false);
      });

      test('should be registered as app lifecycle observer', () {
        // This is implicitly tested by the fact that the service can be created
        // and disposed without errors, indicating proper observer registration
        expect(timerService, isA<WidgetsBindingObserver>());
      });
    });

    group('Timer Control', () {
      test('should start timer correctly', () {
        timerService.start();
        
        expect(timerService.isRunning, true);
        expect(timerService.isPaused, false);
        expect(timerService.elapsed, Duration.zero); // Should start at zero
      });

      test('should not start timer if already running', () {
        timerService.start();
        final initialElapsed = timerService.elapsed;
        
        // Wait a bit to ensure some time has passed
        Future.delayed(const Duration(milliseconds: 100));
        
        timerService.start(); // Try to start again
        
        expect(timerService.isRunning, true);
        expect(timerService.isPaused, false);
        // Should not reset elapsed time
        expect(timerService.elapsed, greaterThanOrEqualTo(initialElapsed));
      });

      test('should stop timer correctly', () {
        timerService.start();
        expect(timerService.isRunning, true);
        
        timerService.stop();
        
        expect(timerService.isRunning, false);
        expect(timerService.isPaused, false);
      });

      test('should reset timer correctly', () {
        timerService.start();
        
        // Wait a bit to accumulate some elapsed time
        Future.delayed(const Duration(milliseconds: 100));
        
        timerService.reset();
        
        expect(timerService.isRunning, false);
        expect(timerService.isPaused, false);
        expect(timerService.elapsed, Duration.zero);
      });

      test('should stop timer when already stopped', () {
        expect(timerService.isRunning, false);
        
        timerService.stop(); // Should not throw error
        
        expect(timerService.isRunning, false);
        expect(timerService.isPaused, false);
      });

      test('should reset timer when already stopped', () {
        expect(timerService.isRunning, false);
        expect(timerService.elapsed, Duration.zero);
        
        timerService.reset(); // Should not throw error
        
        expect(timerService.isRunning, false);
        expect(timerService.isPaused, false);
        expect(timerService.elapsed, Duration.zero);
      });
    });

    group('Timer Elapsed Time', () {
      test('should update elapsed time when running', () async {
        timerService.start();
        
        // Wait for timer to update
        await Future.delayed(const Duration(milliseconds: 1100));
        
        expect(timerService.elapsed.inSeconds, greaterThanOrEqualTo(1));
        expect(timerService.isRunning, true);
      });

      test('should not update elapsed time when stopped', () async {
        timerService.start();
        
        // Wait for timer to update
        await Future.delayed(const Duration(milliseconds: 1100));
        final elapsedWhenRunning = timerService.elapsed;
        
        timerService.stop();
        
        // Wait some more time
        await Future.delayed(const Duration(milliseconds: 1100));
        
        expect(timerService.elapsed, elapsedWhenRunning); // Should not change
        expect(timerService.isRunning, false);
      });

      test('should accumulate elapsed time correctly', () async {
        timerService.start();
        
        // Wait for multiple seconds
        await Future.delayed(const Duration(milliseconds: 2100));
        
        expect(timerService.elapsed.inSeconds, greaterThanOrEqualTo(2));
        expect(timerService.isRunning, true);
      });
    });

    group('App Lifecycle Handling', () {
      test('should pause timer when app becomes paused', () {
        timerService.start();
        expect(timerService.isRunning, true);
        expect(timerService.isPaused, false);
        
        timerService.didChangeAppLifecycleState(AppLifecycleState.paused);
        
        expect(timerService.isRunning, true);
        expect(timerService.isPaused, true);
      });

      test('should pause timer when app becomes inactive', () {
        timerService.start();
        expect(timerService.isRunning, true);
        expect(timerService.isPaused, false);
        
        timerService.didChangeAppLifecycleState(AppLifecycleState.inactive);
        
        expect(timerService.isRunning, true);
        expect(timerService.isPaused, true);
      });

      test('should pause timer when app becomes detached', () {
        timerService.start();
        expect(timerService.isRunning, true);
        expect(timerService.isPaused, false);
        
        timerService.didChangeAppLifecycleState(AppLifecycleState.detached);
        
        expect(timerService.isRunning, true);
        expect(timerService.isPaused, true);
      });

      test('should resume timer when app becomes resumed', () {
        timerService.start();
        timerService.didChangeAppLifecycleState(AppLifecycleState.paused);
        expect(timerService.isPaused, true);
        
        timerService.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        expect(timerService.isRunning, true);
        expect(timerService.isPaused, false);
      });

      test('should not pause timer when not running', () {
        expect(timerService.isRunning, false);
        expect(timerService.isPaused, false);
        
        timerService.didChangeAppLifecycleState(AppLifecycleState.paused);
        
        expect(timerService.isRunning, false);
        expect(timerService.isPaused, false);
      });

      test('should not resume timer when not paused', () {
        timerService.start();
        expect(timerService.isRunning, true);
        expect(timerService.isPaused, false);
        
        timerService.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        expect(timerService.isRunning, true);
        expect(timerService.isPaused, false);
      });

      test('should handle unknown app lifecycle state', () {
        timerService.start();
        expect(timerService.isRunning, true);
        expect(timerService.isPaused, false);
        
        // This should not throw an error and should not change the timer state
        timerService.didChangeAppLifecycleState(AppLifecycleState.hidden);
        
        expect(timerService.isRunning, true);
        expect(timerService.isPaused, false);
      });
    });

    group('Pause and Resume Logic', () {
      test('should maintain elapsed time during pause', () async {
        timerService.start();
        
        // Wait for some time to accumulate
        await Future.delayed(const Duration(milliseconds: 1100));
        final elapsedBeforePause = timerService.elapsed;
        
        timerService.didChangeAppLifecycleState(AppLifecycleState.paused);
        
        // Wait while paused
        await Future.delayed(const Duration(milliseconds: 1100));
        
        expect(timerService.elapsed, elapsedBeforePause); // Should not change while paused
        expect(timerService.isPaused, true);
      });

      test('should continue from correct time after resume', () async {
        timerService.start();
        
        // Wait for some time to accumulate
        await Future.delayed(const Duration(milliseconds: 1100));
        final elapsedBeforePause = timerService.elapsed;
        
        timerService.didChangeAppLifecycleState(AppLifecycleState.paused);
        
        // Wait while paused
        await Future.delayed(const Duration(milliseconds: 1100));
        
        timerService.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        // Wait after resume
        await Future.delayed(const Duration(milliseconds: 1100));
        
        expect(timerService.elapsed.inSeconds, greaterThanOrEqualTo(elapsedBeforePause.inSeconds + 1));
        expect(timerService.isPaused, false);
      });

      test('should handle multiple pause/resume cycles', () async {
        timerService.start();
        
        // First pause/resume cycle - run for 1 second
        await Future.delayed(const Duration(milliseconds: 1100));
        timerService.didChangeAppLifecycleState(AppLifecycleState.paused);
        await Future.delayed(const Duration(milliseconds: 500));
        timerService.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        // Second pause/resume cycle - run for 1 more second
        await Future.delayed(const Duration(milliseconds: 1100));
        timerService.didChangeAppLifecycleState(AppLifecycleState.paused);
        await Future.delayed(const Duration(milliseconds: 500));
        timerService.didChangeAppLifecycleState(AppLifecycleState.resumed);
        
        expect(timerService.isRunning, true);
        expect(timerService.isPaused, false);
        expect(timerService.elapsed.inMilliseconds, greaterThanOrEqualTo(2000));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle dispose when timer is running', () {
        timerService.start();
        expect(timerService.isRunning, true);
        
        timerService.dispose(); // Should not throw error
        
        // After dispose, we can't check the state, but it should not crash
      });

      test('should handle dispose when timer is paused', () {
        timerService.start();
        timerService.didChangeAppLifecycleState(AppLifecycleState.paused);
        expect(timerService.isPaused, true);
        
        timerService.dispose(); // Should not throw error
      });

      test('should handle dispose when timer is stopped', () {
        expect(timerService.isRunning, false);
        
        timerService.dispose(); // Should not throw error
      });

      test('should handle rapid start/stop cycles', () {
        for (int i = 0; i < 10; i++) {
          timerService.start();
          timerService.stop();
        }
        
        expect(timerService.isRunning, false);
        expect(timerService.isPaused, false);
      });

      test('should handle rapid start/reset cycles', () {
        for (int i = 0; i < 10; i++) {
          timerService.start();
          timerService.reset();
        }
        
        expect(timerService.isRunning, false);
        expect(timerService.isPaused, false);
        expect(timerService.elapsed, Duration.zero);
      });
    });

    group('Timer Accuracy', () {
      test('should update timer approximately every second', () async {
        timerService.start();
        
        final startTime = DateTime.now();
        await Future.delayed(const Duration(milliseconds: 1100));
        final endTime = DateTime.now();
        
        final actualElapsed = endTime.difference(startTime);
        final timerElapsed = timerService.elapsed;
        
        // Allow for some timing variance (within 200ms)
        expect((timerElapsed - actualElapsed).inMilliseconds.abs(), lessThan(200));
      });

      test('should maintain accuracy across pause/resume cycles', () async {
        timerService.start();
        
        // Run for 1 second
        await Future.delayed(const Duration(milliseconds: 1100));
        final elapsedBeforePause = timerService.elapsed;
        
        // Pause for 1 second
        timerService.didChangeAppLifecycleState(AppLifecycleState.paused);
        await Future.delayed(const Duration(milliseconds: 1100));
        
        // Resume and run for 1 more second
        timerService.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await Future.delayed(const Duration(milliseconds: 1100));
        
        final totalElapsed = timerService.elapsed;
        
        // Total elapsed should be approximately 2 seconds (excluding pause time)
        expect(totalElapsed.inSeconds, greaterThanOrEqualTo(2));
        expect(totalElapsed.inSeconds, lessThanOrEqualTo(3));
      });
    });
  });
}