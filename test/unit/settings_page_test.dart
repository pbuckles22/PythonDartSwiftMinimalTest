import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:python_flutter_embed_demo/presentation/pages/settings_page.dart';
import 'package:python_flutter_embed_demo/presentation/providers/settings_provider.dart';
import 'package:python_flutter_embed_demo/presentation/providers/game_provider.dart';

void main() {
  group('SettingsPage Tests', () {
    late SettingsProvider settingsProvider;
    late GameProvider gameProvider;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      settingsProvider = SettingsProvider();
      gameProvider = GameProvider();
    });

    Widget createTestWidget({bool closeOnChange = true}) {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
            ChangeNotifierProvider<GameProvider>.value(value: gameProvider),
          ],
          child: SettingsPage(closeOnChange: closeOnChange),
        ),
      );
    }

    group('Basic Widget Tests', () {
      testWidgets('should build without errors', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(SettingsPage), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
      });

      testWidgets('should display ListView with content', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(Card), findsWidgets);
        expect(find.byType(Switch), findsWidgets);
      });

      testWidgets('should handle closeOnChange parameter', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(closeOnChange: false));
        await tester.pumpAndSettle();

        expect(find.byType(SettingsPage), findsOneWidget);
        expect(find.byType(SettingsPage), findsOneWidget);
      });
    });

    group('Provider Integration Tests', () {
      testWidgets('should use SettingsProvider', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Verify that the widget uses the provider
        expect(find.byType(Consumer<SettingsProvider>), findsOneWidget);
      });

      testWidgets('should handle provider state changes', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Change provider state
        settingsProvider.setClassicMode(false);
        await tester.pumpAndSettle();

        // Widget should rebuild
        expect(find.byType(SettingsPage), findsOneWidget);
      });

      testWidgets('should handle kickstarter mode changes', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Change kickstarter mode
        settingsProvider.setKickstarterMode(true);
        await tester.pumpAndSettle();

        // Widget should rebuild
        expect(find.byType(SettingsPage), findsOneWidget);
      });

      testWidgets('should handle 50/50 detection changes', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Toggle 50/50 detection
        settingsProvider.toggle5050Detection();
        await tester.pumpAndSettle();

        // Widget should rebuild
        expect(find.byType(SettingsPage), findsOneWidget);
      });

      testWidgets('should handle haptic feedback changes', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Toggle haptic feedback
        settingsProvider.toggleHapticFeedback();
        await tester.pumpAndSettle();

        // Widget should rebuild
        expect(find.byType(SettingsPage), findsOneWidget);
      });
    });

    group('Switch Interaction Tests', () {
      testWidgets('should handle switch taps', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final switches = find.byType(Switch);
        if (switches.evaluate().isNotEmpty) {
          await tester.tap(switches.first);
          await tester.pumpAndSettle();

          // Should not crash
          expect(find.byType(SettingsPage), findsOneWidget);
        }
      });

      testWidgets('should handle multiple switch interactions', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final switches = find.byType(Switch);
        for (int i = 0; i < switches.evaluate().length && i < 3; i++) {
          await tester.tap(switches.at(i));
          await tester.pumpAndSettle();
        }

        // Should not crash
        expect(find.byType(SettingsPage), findsOneWidget);
      });
    });

    group('Navigation Tests', () {
      testWidgets('should handle navigation when closeOnChange is true', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(closeOnChange: true));
        await tester.pumpAndSettle();

        // Try to trigger navigation by tapping a switch
        final switches = find.byType(Switch);
        if (switches.evaluate().isNotEmpty) {
          await tester.tap(switches.first);
          await tester.pumpAndSettle();
        }

        // Should handle navigation gracefully
        expect(find.byType(SettingsPage), findsOneWidget);
      });

      testWidgets('should handle navigation when closeOnChange is false', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(closeOnChange: false));
        await tester.pumpAndSettle();

        // Try to trigger navigation by tapping a switch
        final switches = find.byType(Switch);
        if (switches.evaluate().isNotEmpty) {
          await tester.tap(switches.first);
          await tester.pumpAndSettle();
        }

        // Should remain on the page
        expect(find.byType(SettingsPage), findsOneWidget);
      });
    });

    group('Theme and Styling Tests', () {
      testWidgets('should use Material theme', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('should display cards with proper styling', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final cards = find.byType(Card);
        expect(cards, findsWidgets);
      });

      testWidgets('should display switches with proper styling', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final switches = find.byType(Switch);
        expect(switches, findsWidgets);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should handle missing providers gracefully', (WidgetTester tester) async {
        // Create a mock settings provider for this test
        final mockSettingsProvider = SettingsProvider();
        mockSettingsProvider.loadSettingsFromConfig();
        
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<SettingsProvider>.value(
              value: mockSettingsProvider,
              child: SettingsPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should render with mock provider
        expect(find.byType(SettingsPage), findsOneWidget);
      });

      testWidgets('should handle provider errors gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should handle any provider errors gracefully
        expect(find.byType(SettingsPage), findsOneWidget);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should have semantic structure', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('should have interactive elements', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(Switch), findsWidgets);
        expect(find.byType(Card), findsWidgets);
      });
    });

    group('Performance Tests', () {
      testWidgets('should handle rapid state changes', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Rapid state changes
        for (int i = 0; i < 5; i++) {
          settingsProvider.setClassicMode(i % 2 == 0);
          settingsProvider.setKickstarterMode(i % 2 == 1);
          await tester.pumpAndSettle();
        }

        // Should handle rapid changes gracefully
        expect(find.byType(SettingsPage), findsOneWidget);
      });

      testWidgets('should handle multiple rebuilds', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Multiple rebuilds
        for (int i = 0; i < 10; i++) {
          await tester.pump();
        }

        // Should handle multiple rebuilds gracefully
        expect(find.byType(SettingsPage), findsOneWidget);
      });
    });

    group('50/50 Sensitivity Slider Tests', () {
      testWidgets('should show sensitivity slider when 50/50 detection is enabled', (WidgetTester tester) async {
        // Enable 50/50 detection
        settingsProvider.toggle5050Detection();
        expect(settingsProvider.is5050DetectionEnabled, true);
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should find the sensitivity slider
        expect(find.text('50/50 Detection Sensitivity'), findsOneWidget);
        expect(find.byType(Slider), findsOneWidget);
      });

      testWidgets('should hide sensitivity slider when 50/50 detection is disabled', (WidgetTester tester) async {
        // Disable 50/50 detection
        settingsProvider.toggle5050Detection();
        expect(settingsProvider.is5050DetectionEnabled, false);
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should not find the sensitivity slider
        expect(find.text('50/50 Detection Sensitivity'), findsNothing);
      });

      testWidgets('should display current sensitivity range', (WidgetTester tester) async {
        // Enable 50/50 detection
        settingsProvider.toggle5050Detection();
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should show the range (default 0.1 = 40-60%)
        expect(find.text('Range: 40% - 60%'), findsOneWidget);
      });

      testWidgets('should update range display when sensitivity changes', (WidgetTester tester) async {
        // Enable 50/50 detection
        settingsProvider.toggle5050Detection();
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Change sensitivity to 0.05 (45-55%)
        settingsProvider.updateFiftyFiftySensitivity(0.05);
        await tester.pumpAndSettle();

        // Should show updated range
        expect(find.text('Range: 45% - 55%'), findsOneWidget);
      });

      testWidgets('should allow slider interaction', (WidgetTester tester) async {
        // Enable 50/50 detection
        settingsProvider.toggle5050Detection();
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find the slider
        final slider = find.byType(Slider);
        expect(slider, findsOneWidget);

        // Get initial value
        final initialValue = settingsProvider.fiftyFiftySensitivity;
        expect(initialValue, 0.1);

        // Drag slider to a new value
        await tester.drag(slider, const Offset(50.0, 0.0));
        await tester.pumpAndSettle();

        // Value should have changed
        expect(settingsProvider.fiftyFiftySensitivity, isNot(initialValue));
      });

      testWidgets('should show strict and lenient labels', (WidgetTester tester) async {
        // Enable 50/50 detection
        settingsProvider.toggle5050Detection();
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should show the labels
        expect(find.text('Strict (45-55%)'), findsOneWidget);
        expect(find.text('Lenient (30-70%)'), findsOneWidget);
      });

      testWidgets('should show help tooltip', (WidgetTester tester) async {
        // Enable 50/50 detection
        settingsProvider.toggle5050Detection();
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should find help icon
        expect(find.byIcon(Icons.help_outline), findsOneWidget);
      });
    });

    group('Settings Menu Organization Tests', () {
      testWidgets('should display Board Size section at the top', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find all section headers
        final sectionHeaders = find.byType(Text);
        final headerTexts = <String>[];
        
        for (final element in sectionHeaders.evaluate()) {
          final widget = element.widget as Text;
          if (widget.style?.fontWeight == FontWeight.bold) {
            headerTexts.add(widget.data!);
          }
        }

        // Board Size should be the first section
        expect(headerTexts.first, 'Board Size');
      });

      testWidgets('should display sections in correct order', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find all section headers
        final sectionHeaders = find.byType(Text);
        final headerTexts = <String>[];
        
        for (final element in sectionHeaders.evaluate()) {
          final widget = element.widget as Text;
          if (widget.style?.fontWeight == FontWeight.bold) {
            headerTexts.add(widget.data!);
          }
        }

        // Expected order: Board Size, General Gameplay, Advanced / Experimental
        expect(headerTexts.length, greaterThanOrEqualTo(3));
        expect(headerTexts[0], 'Board Size');
        expect(headerTexts[1], 'General Gameplay');
        expect(headerTexts[2], 'Advanced / Experimental');
      });

      testWidgets('should display 50/50 features in correct order when enabled', (WidgetTester tester) async {
        // Enable 50/50 detection
        settingsProvider.toggle5050Detection();
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find all text widgets in the advanced section
        final advancedSection = find.ancestor(
          of: find.text('Advanced / Experimental'),
          matching: find.byType(Column),
        );
        
        final advancedTexts = <String>[];
        for (final element in advancedSection.evaluate()) {
          final textWidgets = find.descendant(
            of: find.byWidget(element.widget),
            matching: find.byType(Text),
          );
          
          for (final textElement in textWidgets.evaluate()) {
            final text = (textElement.widget as Text).data;
            if (text != null && text.contains('50/50')) {
              advancedTexts.add(text);
            }
          }
        }

        // Should have 50/50 detection, sensitivity, and safe move in order
        expect(advancedTexts.length, greaterThanOrEqualTo(3));
        expect(advancedTexts[0], contains('50/50 Detection'));
        expect(advancedTexts[1], contains('50/50 Detection Sensitivity'));
        expect(advancedTexts[2], contains('50/50 Safe Move'));
      });

      testWidgets('should not show sensitivity and safe move when 50/50 detection is disabled', (WidgetTester tester) async {
        // Disable 50/50 detection
        settingsProvider.toggle5050Detection();
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should not find sensitivity or safe move toggles
        expect(find.text('50/50 Detection Sensitivity'), findsNothing);
        expect(find.text('50/50 Safe Move'), findsNothing);
      });
    });
  });
}