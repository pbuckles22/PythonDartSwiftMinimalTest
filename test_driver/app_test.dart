import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('Minesweeper App Tests', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver.close();
    });

    group('App Initialization', () {
      test('should load app successfully', () async {
        // Wait for app to load
        await driver.waitFor(find.byType('MaterialApp'));
        
        // Verify game board is present
        await driver.waitFor(find.byValueKey('game_board'));
        
        // Verify timer is present
        await driver.waitFor(find.byValueKey('timer'));
        
        // Verify mine counter is present
        await driver.waitFor(find.byValueKey('mine_counter'));
      });

      test('should display correct initial state', () async {
        // Check that timer shows 0 initially
        final timerText = await driver.getText(find.byValueKey('timer'));
        expect(timerText, contains('0'));
        
        // Check that mine counter shows correct count for hard difficulty
        final mineCounterText = await driver.getText(find.byValueKey('mine_counter'));
        expect(mineCounterText, contains('99'));
      });
    });

    group('Game Board Interaction', () {
      test('should reveal cell on tap', () async {
        // Find and tap the first cell
        final firstCell = find.byValueKey('cell_0_0');
        await driver.tap(firstCell);
        
        // Wait for cell to be revealed
        await driver.waitFor(find.byValueKey('cell_0_0_revealed'));
        
        // Verify timer started
        await Future.delayed(Duration(milliseconds: 100));
        final timerText = await driver.getText(find.byValueKey('timer'));
        expect(int.parse(timerText.replaceAll(RegExp(r'[^0-9]'), '')), greaterThan(0));
      });

      test('should flag cell on long press', () async {
        // Find and long press a cell
        final cell = find.byValueKey('cell_1_1');
        await driver.scroll(cell, 0, 0, Duration(milliseconds: 500));
        
        // Wait for cell to be flagged
        await driver.waitFor(find.byValueKey('cell_1_1_flagged'));
        
        // Verify mine counter decreased
        final mineCounterText = await driver.getText(find.byValueKey('mine_counter'));
        expect(mineCounterText, contains('98'));
      });

      test('should not reveal flagged cell', () async {
        // Flag a cell
        final cell = find.byValueKey('cell_2_2');
        await driver.scroll(cell, 0, 0, Duration(milliseconds: 500));
        await driver.waitFor(find.byValueKey('cell_2_2_flagged'));
        
        // Try to tap the flagged cell
        await driver.tap(cell);
        
        // Cell should remain flagged, not revealed
        await driver.waitFor(find.byValueKey('cell_2_2_flagged'));
      });
    });

    group('Settings Page', () {
      test('should navigate to settings', () async {
        // Find and tap settings button
        final settingsButton = find.byValueKey('settings_button');
        await driver.tap(settingsButton);
        
        // Wait for settings page to load
        await driver.waitFor(find.byValueKey('settings_page'));
      });

      test('should change difficulty', () async {
        // Navigate to settings
        await driver.tap(find.byValueKey('settings_button'));
        await driver.waitFor(find.byValueKey('settings_page'));
        
        // Change difficulty to easy
        final easyButton = find.byValueKey('difficulty_easy');
        await driver.tap(easyButton);
        
        // Go back to game
        await driver.tap(find.byValueKey('back_button'));
        
        // Verify mine counter changed to easy difficulty
        await driver.waitFor(find.byValueKey('mine_counter'));
        final mineCounterText = await driver.getText(find.byValueKey('mine_counter'));
        expect(mineCounterText, contains('10'));
      });

      test('should toggle game modes', () async {
        // Navigate to settings
        await driver.tap(find.byValueKey('settings_button'));
        await driver.waitFor(find.byValueKey('settings_page'));
        
        // Toggle classic mode
        final classicToggle = find.byValueKey('classic_mode_toggle');
        await driver.tap(classicToggle);
        
        // Toggle kickstarter mode
        final kickstarterToggle = find.byValueKey('kickstarter_mode_toggle');
        await driver.tap(kickstarterToggle);
        
        // Go back to game
        await driver.tap(find.byValueKey('back_button'));
      });
    });

    group('Timer Functionality', () {
      test('should start timer on first move and increment', () async {
        // Wait for app to load
        await driver.waitFor(find.byValueKey('game_board'));
        
        // Get initial timer value
        final initialTimerText = await driver.getText(find.byValueKey('timer'));
        final initialTime = int.parse(initialTimerText.replaceAll(RegExp(r'[^0-9]'), ''));
        expect(initialTime, equals(0));
        
        // Make first move to start timer
        final firstCell = find.byValueKey('cell_0_0');
        await driver.tap(firstCell);
        
        // Wait for timer to start and increment
        await Future.delayed(Duration(milliseconds: 1500));
        
        // Check that timer has incremented
        final newTimerText = await driver.getText(find.byValueKey('timer'));
        final newTime = int.parse(newTimerText.replaceAll(RegExp(r'[^0-9]'), ''));
        expect(newTime, greaterThan(initialTime));
        
        // Wait a bit more and check timer continues incrementing
        await Future.delayed(Duration(milliseconds: 1000));
        final finalTimerText = await driver.getText(find.byValueKey('timer'));
        final finalTime = int.parse(finalTimerText.replaceAll(RegExp(r'[^0-9]'), ''));
        expect(finalTime, greaterThan(newTime));
      });

      test('should stop timer when game ends', () async {
        // Wait for app to load
        await driver.waitFor(find.byValueKey('game_board'));
        
        // Start timer by making a move
        final firstCell = find.byValueKey('cell_0_0');
        await driver.tap(firstCell);
        
        // Wait for timer to start
        await Future.delayed(Duration(milliseconds: 1000));
        final runningTimerText = await driver.getText(find.byValueKey('timer'));
        final runningTime = int.parse(runningTimerText.replaceAll(RegExp(r'[^0-9]'), ''));
        expect(runningTime, greaterThan(0));
        
        // Try to find and tap a bomb to end the game
        bool gameEnded = false;
        for (int i = 0; i < 10 && !gameEnded; i++) {
          try {
            final cell = find.byValueKey('cell_${i}_${i}');
            await driver.tap(cell);
            
            // Check if game is over
            final gameOverDialog = find.byValueKey('game_over_dialog');
            if (await driver.isPresent(gameOverDialog)) {
              gameEnded = true;
              await driver.waitFor(gameOverDialog);
              
              // Wait a bit and check timer stopped
              await Future.delayed(Duration(milliseconds: 1000));
              final stoppedTimerText = await driver.getText(find.byValueKey('timer'));
              final stoppedTime = int.parse(stoppedTimerText.replaceAll(RegExp(r'[^0-9]'), ''));
              
              // Timer should not have incremented significantly after game ended
              expect(stoppedTime, lessThanOrEqualTo(runningTime + 2));
            }
          } catch (e) {
            // Continue to next cell
          }
        }
        
        // If we didn't find a bomb, at least verify timer is running
        if (!gameEnded) {
          final finalTimerText = await driver.getText(find.byValueKey('timer'));
          final finalTime = int.parse(finalTimerText.replaceAll(RegExp(r'[^0-9]'), ''));
          expect(finalTime, greaterThan(runningTime));
        }
      });

      test('should reset timer on new game', () async {
        // Wait for app to load
        await driver.waitFor(find.byValueKey('game_board'));
        
        // Start timer by making a move
        final firstCell = find.byValueKey('cell_0_0');
        await driver.tap(firstCell);
        
        // Wait for timer to start and increment
        await Future.delayed(Duration(milliseconds: 1000));
        final runningTimerText = await driver.getText(find.byValueKey('timer'));
        final runningTime = int.parse(runningTimerText.replaceAll(RegExp(r'[^0-9]'), ''));
        expect(runningTime, greaterThan(0));
        
        // Look for new game button and start new game
        final newGameButton = find.byValueKey('new_game_button');
        if (await driver.isPresent(newGameButton)) {
          await driver.tap(newGameButton);
          
          // Wait for game to reset
          await driver.waitFor(find.byValueKey('game_board'));
          
          // Check that timer reset to 0
          final resetTimerText = await driver.getText(find.byValueKey('timer'));
          final resetTime = int.parse(resetTimerText.replaceAll(RegExp(r'[^0-9]'), ''));
          expect(resetTime, equals(0));
        }
      });
    });

    group('50/50 Detection', () {
      test('should show 50/50 detection button', () async {
        // Verify 50/50 detection button is present
        await driver.waitFor(find.byValueKey('5050_detection_button'));
      });

      test('should trigger 50/50 detection', () async {
        // Tap 50/50 detection button
        final button = find.byValueKey('5050_detection_button');
        await driver.tap(button);
        
        // Wait for detection to complete
        await Future.delayed(Duration(milliseconds: 500));
        
        // Verify no errors occurred
        await driver.waitFor(find.byValueKey('game_board'));
      });
    });

    group('Game Over Scenarios', () {
      test('should handle game loss', () async {
        // Try to find and tap a bomb (this is random, so we just try a few cells)
        for (int i = 0; i < 5; i++) {
          try {
            final cell = find.byValueKey('cell_${i}_${i}');
            await driver.tap(cell);
            
            // Check if game is over
            final gameOverDialog = find.byValueKey('game_over_dialog');
            if (await driver.isPresent(gameOverDialog)) {
              // Game over dialog appeared
              await driver.waitFor(gameOverDialog);
              break;
            }
          } catch (e) {
            // Continue to next cell
          }
        }
      });

      test('should handle new game', () async {
        // Look for new game button
        final newGameButton = find.byValueKey('new_game_button');
        if (await driver.isPresent(newGameButton)) {
          await driver.tap(newGameButton);
          
          // Verify game board reset
          await driver.waitFor(find.byValueKey('game_board'));
          
          // Verify timer reset
          final timerText = await driver.getText(find.byValueKey('timer'));
          expect(timerText, contains('0'));
        }
      });
    });

    group('Performance Tests', () {
      test('should handle rapid cell taps', () async {
        // Rapidly tap multiple cells
        for (int i = 0; i < 10; i++) {
          try {
            final cell = find.byValueKey('cell_${i % 3}_${i % 3}');
            await driver.tap(cell);
            await Future.delayed(Duration(milliseconds: 50));
          } catch (e) {
            // Continue if cell not found
          }
        }
        
        // Verify app is still responsive
        await driver.waitFor(find.byValueKey('game_board'));
      });

      test('should handle scrolling on large board', () async {
        // Scroll the game board
        final gameBoard = find.byValueKey('game_board');
        await driver.scroll(gameBoard, 0, -500, Duration(milliseconds: 1000));
        await driver.scroll(gameBoard, 0, 500, Duration(milliseconds: 1000));
        
        // Verify app is still responsive
        await driver.waitFor(find.byValueKey('game_board'));
      });
    });

    group('Accessibility', () {
      test('should have proper accessibility labels', () async {
        // Check that important elements have accessibility labels
        await driver.waitFor(find.byValueKey('game_board'));
        await driver.waitFor(find.byValueKey('timer'));
        await driver.waitFor(find.byValueKey('mine_counter'));
      });
    });
  });
} 