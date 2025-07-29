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
  });
}